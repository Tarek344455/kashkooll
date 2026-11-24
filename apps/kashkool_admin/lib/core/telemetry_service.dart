import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'config/supabase_bootstrap.dart';

final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  return TelemetryService();
});

/// Active sessions per governorate. Empty map = no centre is live right now.
final governorateCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) {
  return ref.watch(telemetryServiceProvider).getActiveSessionsByGovernorate();
});

/// Platform-wide counters for the command centre header.
final systemMetricsProvider =
    FutureProvider.autoDispose<SystemMetrics>((ref) {
  return ref.watch(telemetryServiceProvider).getSystemMetrics();
});

/// Snapshot of platform load. Every field comes from a Postgres aggregate.
class SystemMetrics {
  const SystemMetrics({
    required this.activeTenants,
    required this.frozenTenants,
    required this.totalStudents,
    required this.backendHealthy,
    required this.capturedAt,
    this.activeStudents = 0,
    this.liveSessions = 0,
    this.pendingAlerts = 0,
  });

  final int activeTenants;
  final int frozenTenants;
  final int totalStudents;
  final bool backendHealthy;
  final DateTime capturedAt;
  final int activeStudents;
  final int liveSessions;
  final int pendingAlerts;

  int get totalTenants => activeTenants + frozenTenants;
}

/// Live Egypt governorate activity and backend health.
///
/// Read failures are surfaced to the caller so the UI can show an error state;
/// nothing here invents numbers when Supabase is unreachable.
class TelemetryService {
  TelemetryService({sb.SupabaseClient? client}) : _client = client;

  sb.SupabaseClient? _client;

  sb.SupabaseClient get _supabase => _client ??= SupabaseBootstrap.client;

  /// Counts active sessions per governorate.
  Future<Map<String, int>> getActiveSessionsByGovernorate() async {
    final result = await _supabase.rpc('sessions_by_governorate');
    if (result is! Map) return <String, int>{};
    return result.map(
      (key, value) => MapEntry(
        key.toString(),
        value is num ? value.round() : int.tryParse(value.toString()) ?? 0,
      ),
    );
  }

  /// Aggregated platform counters in a single round-trip.
  Future<SystemMetrics> getSystemMetrics() async {
    final row = await _supabase.rpc('platform_metrics');
    final data = row is Map ? Map<String, dynamic>.from(row) : <String, dynamic>{};

    int count(String key) {
      final value = data[key];
      return value is num ? value.round() : int.tryParse(value.toString()) ?? 0;
    }

    return SystemMetrics(
      activeTenants: count('activeTenants'),
      frozenTenants: count('frozenTenants'),
      totalStudents: count('totalStudents'),
      activeStudents: count('activeStudents'),
      liveSessions: count('liveSessions'),
      pendingAlerts: count('pendingAlerts'),
      backendHealthy: await checkBackendHealth(),
      capturedAt: DateTime.now(),
    );
  }

  /// Pings the heartbeat row written by pg_cron every minute.
  Future<bool> checkBackendHealth() async {
    try {
      final row = await _supabase
          .from('health_ping')
          .select('beat_at')
          .eq('id', 'ping')
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (row == null) return false;
      final raw = row['beat_at'];
      final beat = raw is DateTime
          ? raw
          : (raw is String ? DateTime.tryParse(raw) : null);
      if (beat == null) return false;
      return DateTime.now().difference(beat.toLocal()).inMinutes < 15;
    } catch (_) {
      return false;
    }
  }
}
