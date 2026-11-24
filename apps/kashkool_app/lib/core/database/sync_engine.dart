library sync_engine;

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../config/supabase_bootstrap.dart';
import 'db_provider.dart';
import 'local_db.dart';

/// Flushes the local Drift queue to Supabase/PostgreSQL.
///
/// Every queued mutation targets the tenant of the signed-in profile
/// (`tenants/{tenantId}/...`, now relational tables with RLS) — the same
/// boundary the edge functions and policies enforce. Drift remains the
/// offline source of truth; Supabase is the authoritative sync target.
///
/// Priority: 0=CRITICAL (attendance, payments), 1=HIGH (sessions, quizzes),
/// 2=NORMAL (students, metadata).
class SyncEngine {
  static const int maxRetries = 5;
  static const Duration baseDelay = Duration(seconds: 2);
  static const Duration maxDelay = Duration(minutes: 5);

  /// Local collections that map 1:1 to a tenant-scoped Postgres table.
  static const Map<String, String> _tenantTables = <String, String>{
    'attendance': 'attendance',
    'sessions': 'sessions',
    'students': 'students',
    'quizzes': 'quizzes',
    'quiz_results': 'quiz_results',
    'wallet_transactions': 'wallet_transactions',
  };

  final LocalDb _db;
  sb.SupabaseClient? _client;

  SyncEngine({required LocalDb db, sb.SupabaseClient? client})
      : _db = db,
        _client = client;

  sb.SupabaseClient get _supabase => _client ??= SupabaseBootstrap.client;

  /// Process the entire sync queue in priority order.
  Future<SyncResult> processSyncQueue() async {
    debugPrint('SyncEngine: Processing offline queue...');

    final pendingItems = await _db.getSyncQueueOrdered();
    if (pendingItems.isEmpty) {
      return const SyncResult(processed: 0, failed: 0, message: 'Queue empty');
    }

    int processed = 0;
    int failed = 0;
    final errors = <String>[];

    for (final item in pendingItems) {
      if (item.status == 'processing') continue; // Skip stuck items

      await _db.upsertSyncQueueItem(
        SyncQueueTableCompanion(
          id: Value(item.id),
          status: const Value('processing'),
        ),
      );

      final success = await _syncItem(item);
      if (success) {
        await _db.upsertSyncQueueItem(
          SyncQueueTableCompanion(
            id: Value(item.id),
            status: const Value('completed'),
          ),
        );
        processed++;
      } else {
        final newRetryCount = item.retryCount + 1;
        if (newRetryCount >= maxRetries) {
          await _db.upsertSyncQueueItem(
            SyncQueueTableCompanion(
              id: Value(item.id),
              status: const Value('failed'),
            ),
          );
          failed++;
          errors.add(
            'Item ${item.id} (${item.collectionName}) failed after '
            '$maxRetries retries',
          );
        } else {
          await _db.upsertSyncQueueItem(
            SyncQueueTableCompanion(
              id: Value(item.id),
              status: const Value('pending'),
              retryCount: Value(newRetryCount),
            ),
          );
          failed++;
          errors.add('Item ${item.id} retry $newRetryCount/$maxRetries');
        }
      }

      // Exponential backoff between items.
      await Future<void>.delayed(
        Duration(milliseconds: 100 * (1 << (processed + failed))),
      );
    }

    final message = 'Processed: $processed, Failed: $failed'
        '${errors.isNotEmpty ? ' - Errors: ${errors.join('; ')}' : ''}';
    debugPrint('SyncEngine: $message');

    return SyncResult(
      processed: processed,
      failed: failed,
      message: message,
      errors: errors,
    );
  }

  /// Sync a single queue item based on collection and operation.
  Future<bool> _syncItem(SyncQueueTableData item) async {
    final table = _tenantTables[item.collectionName];
    if (table == null) {
      debugPrint('SyncEngine: Unknown collection ${item.collectionName}');
      return false;
    }
    if (!SupabaseBootstrap.isReady) {
      debugPrint('SyncEngine: Supabase is not configured, deferring ${item.id}');
      return false;
    }

    final data = _parseDataJson(item.dataJson);
    if (item.operation == 'delete') {
      return _deleteDocument(item, table);
    }
    return _writeDocument(item, table, data);
  }

  /// Money and attendance go through validating/idempotent RPCs; the rest are
  /// tenant-scoped upserts. `updated_at` is stamped by the database trigger.
  Future<bool> _writeDocument(
    SyncQueueTableData item,
    String table,
    Map<String, dynamic> data,
  ) async {
    final tenantId = await _currentTenantId();
    if (tenantId == null) {
      debugPrint('SyncEngine: no tenant profile, deferring ${item.id}');
      return false;
    }

    try {
      switch (item.collectionName) {
        case 'attendance':
          await _supabase.rpc('record_attendance', params: <String, dynamic>{
            'p_id': item.documentId,
            'p_tenant_id': tenantId,
            'p_student_id': _text(data, 'studentId', alt: 'userId'),
            'p_session_id': _text(data, 'sessionId'),
            'p_idempotency_key': '$tenantId:${item.documentId}',
            'p_scanned_at': _dateTime(data, 'timestamp', alt: 'scannedAt')?.toUtc().toIso8601String() ??
                DateTime.now().toUtc().toIso8601String(),
          });
        case 'wallet_transactions':
          final amount = _number(data, 'amount', alt: 'amountPiasters');
          if (amount == null || amount == 0) return false;
          await _supabase.rpc('record_wallet_transaction', params: <String, dynamic>{
            'p_id': item.documentId,
            'p_tenant_id': tenantId,
            'p_student_id': _text(data, 'userId', alt: 'studentId'),
            'p_amount_piasters': (amount * 100).round(),
            'p_kind': _text(data, 'kind', fallback: 'topup'),
            'p_channel': _channel(_text(data, 'channel', fallback: 'cash')),
            'p_reference_id': _textOrNull(data, 'referenceId'),
            'p_idempotency_key': '$tenantId:${item.documentId}',
            'p_note': _text(data, 'description', alt: 'note'),
          });
        default:
          await _supabase.from(table).upsert(
                _mapRow(item.collectionName, item.documentId, tenantId, data),
                onConflict: 'id',
              );
      }
      return true;
    } on sb.PostgrestException catch (error) {
      debugPrint(
        'SyncEngine: Supabase ${error.code} writing '
        '${item.collectionName}/${item.documentId}: ${error.message}',
      );
      return false;
    } catch (error) {
      debugPrint('SyncEngine: write failed for ${item.id}: $error');
      return false;
    }
  }

  Future<bool> _deleteDocument(SyncQueueTableData item, String table) async {
    // A ledger entry can never be hard-deleted: a void/refund entry is the
    // only legal correction (immutable ledger + anti-fraud contract).
    if (item.collectionName == 'wallet_transactions') {
      debugPrint('SyncEngine: ledger deletes are forbidden; use void RPC');
      return false;
    }
    final tenantId = await _currentTenantId();
    if (tenantId == null) return false;

    try {
      await _supabase
          .from(table)
          .delete()
          .eq('id', item.documentId)
          .eq('tenant_id', tenantId);
      return true;
    } on sb.PostgrestException catch (error) {
      debugPrint('SyncEngine: Supabase ${error.code} deleting ${item.id}');
      return false;
    } catch (error) {
      debugPrint('SyncEngine: delete failed for ${item.id}: $error');
      return false;
    }
  }

  /// Tenant id from the signed-in profile. Null when not signed in or not
  /// enrolled by a centre yet.
  Future<String?> _currentTenantId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      final row = await _supabase
          .from('profiles')
          .select('tenant_id')
          .eq('id', user.id)
          .maybeSingle();
      final tenantId = row?['tenant_id'] as String?;
      if (tenantId == null || tenantId.isEmpty || tenantId == 'unassigned') {
        return null;
      }
      return tenantId;
    } catch (error) {
      debugPrint('SyncEngine: could not read tenant profile ($error)');
      return null;
    }
  }

  /// Maps the offline JSON (camelCase queue keys) onto the exact
  /// Postgres column names. Unknown keys are dropped, never sent to the API.
  Map<String, dynamic> _mapRow(
    String collection,
    String id,
    String tenantId,
    Map<String, dynamic> data,
  ) {
    final base = <String, dynamic>{'id': id, 'tenant_id': tenantId};
    switch (collection) {
      case 'students':
        return <String, dynamic>{
          ...base,
          'name': _text(data, 'name', fallback: ''),
          'phone': _text(data, 'phone', fallback: ''),
          'group_id': _textOrNull(data, 'groupId', alt: 'group_id'),
          'bound_device_id': _textOrNull(data, 'deviceFingerprint', alt: 'boundDeviceId'),
          'is_online': data['isOnline'] == true,
          'metadata': <String, dynamic>{
            'syncedAt': _textOrNull(data, 'syncedAt') ?? DateTime.now().toIso8601String(),
          },
        };
      case 'sessions':
        return <String, dynamic>{
          ...base,
          'title': _text(data, 'title', fallback: ''),
          'subject': _text(data, 'subject', fallback: _text(data, 'type', fallback: '')),
          'group_id': _textOrNull(data, 'groupId'),
          'hall_id': _textOrNull(data, 'hallId'),
          'governorate': _text(data, 'governorate', fallback: ''),
          'session_type': _text(data, 'type', fallback: 'offline'),
          'qr_secret': _text(data, 'qrSecret', fallback: ''),
          'starts_at': _dateTime(data, 'startTime', alt: 'startsAt')?.toUtc().toIso8601String(),
          'ends_at': _dateTime(data, 'endTime', alt: 'endsAt')?.toUtc().toIso8601String(),
          'is_active': data['isActive'] == true,
        };
      case 'quizzes':
        return <String, dynamic>{
          ...base,
          'title': _text(data, 'title', fallback: ''),
          'subject': _text(data, 'subject', fallback: ''),
          'tags': (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
          'questions': data['questions'] ?? <dynamic>[],
          'time_limit_minutes': _int(data, 'timeLimitMinutes') ?? 0,
          'difficulty': _text(data, 'difficulty', fallback: ''),
        };
      case 'quiz_results':
        return <String, dynamic>{
          ...base,
          'quiz_id': _text(data, 'quizId'),
          'student_id': _text(data, 'studentId', alt: 'userId'),
          'score': _number(data, 'score') ?? 0,
          'answers': data['answers'] ?? <String, dynamic>{},
          'taken_at': _dateTime(data, 'takenAt')?.toUtc().toIso8601String() ??
              DateTime.now().toUtc().toIso8601String(),
        };
      case 'attendance':
        return <String, dynamic>{
          ...base,
          'student_id': _text(data, 'studentId', alt: 'userId'),
          'session_id': _text(data, 'sessionId'),
          'status': _text(data, 'status', fallback: 'present'),
          'idempotency_key': '$tenantId:$id',
          'scanned_at': _dateTime(data, 'timestamp', alt: 'scannedAt')?.toUtc().toIso8601String() ??
              DateTime.now().toUtc().toIso8601String(),
        };
      default:
        return base;
    }
  }

  Map<String, dynamic> _parseDataJson(String json) {
    try {
      return Map<String, dynamic>.from(jsonDecode(json) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _text(
    Map<String, dynamic> data,
    String key, {
    String? alt,
    String fallback = '',
  }) {
    final value = data[key] ?? (alt == null ? null : data[alt]);
    return value == null ? fallback : value.toString();
  }

  String? _textOrNull(Map<String, dynamic> data, String key, {String? alt}) {
    final value = data[key] ?? (alt == null ? null : data[alt]);
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  int? _int(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  num? _number(Map<String, dynamic> data, String key, {String? alt}) {
    final value = data[key] ?? (alt == null ? null : data[alt]);
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }

  DateTime? _dateTime(Map<String, dynamic> data, String key, {String? alt}) {
    final value = data[key] ?? (alt == null ? null : data[alt]);
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _channel(String raw) {
    switch (raw) {
      case 'cashToWallet':
      case 'cash':
        return 'cash';
      case 'vodafoneCash':
        return 'vodafone_cash';
      case 'instaPay':
        return 'insta_pay';
      default:
        return raw;
    }
  }
}

/// Result of a sync cycle
class SyncResult {
  const SyncResult({
    required this.processed,
    required this.failed,
    required this.message,
    this.errors = const [],
  });

  final int processed;
  final int failed;
  final String message;
  final List<String> errors;

  bool get hasErrors => failed > 0;
  bool get isClean => failed == 0;
}

/// Provider for SyncEngine
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(localDbProvider);
  return SyncEngine(db: db);
});
