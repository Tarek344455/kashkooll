import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'config/supabase_bootstrap.dart';

/// Remote feature flags and the global emergency switch.
///
/// State lives in the `feature_flags` table so a flip on one admin device
/// reaches every client (Realtime). Updates are optimistic: the UI repaints
/// immediately and the previous value is restored if the store rejects the
/// write. Rolling back matters for the kill switch — the console must never
/// claim the platform is blocked when the write never landed.
final killSwitchServiceProvider = ChangeNotifierProvider<KillSwitchService>((ref) {
  return KillSwitchService();
});

/// Persistence seam: Supabase in production, in-memory in tests.
abstract class SwitchStore {
  Future<Map<String, bool>> read();

  Future<void> write(String feature, bool enabled);
}

class SupabaseSwitchStore implements SwitchStore {
  SupabaseSwitchStore({sb.SupabaseClient? client}) : _client = client;

  sb.SupabaseClient? _client;

  sb.SupabaseClient get _supabase => _client ??= SupabaseBootstrap.client;

  @override
  Future<Map<String, bool>> read() async {
    final rows = await _supabase.from('feature_flags').select('key,enabled');
    final flags = <String, bool>{};
    for (final row in rows) {
      final key = row['key'];
      final value = row['enabled'];
      if (key is String && value is bool) flags[key] = value;
    }
    return flags;
  }

  /// The RPC enforces supervisor-only writes and appends an audit entry.
  @override
  Future<void> write(String feature, bool enabled) async {
    await _supabase.rpc('set_flag', params: <String, dynamic>{
      'p_key': feature,
      'p_enabled': enabled,
    });
  }
}

class KillSwitchService extends ChangeNotifier {
  KillSwitchService({SwitchStore? store}) : _store = store ?? SupabaseSwitchStore();

  static const Map<String, bool> _defaults = <String, bool>{
    'global_emergency': false,
    'new_quiz_feature': true,
    'live_classroom': true,
    'cash_desk': true,
  };

  final SwitchStore _store;
  final Map<String, bool> _flags = Map<String, bool>.of(_defaults);

  bool _loading = false;
  bool _loaded = false;
  bool _disposed = false;
  String? _error;

  bool get isLoading => _loading;
  bool get isLoaded => _loaded;
  String? get error => _error;

  bool get isGlobalKillSwitchActive => isFeatureEnabled('global_emergency');

  List<String> get featureKeys => _defaults.keys.toList(growable: false);

  bool isFeatureEnabled(String feature) => _flags[feature] ?? false;

  /// Pulls the authoritative switch state. Safe to call repeatedly.
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    _notify();

    try {
      final stored = await _store.read();
      for (final entry in stored.entries) {
        if (_defaults.containsKey(entry.key)) _flags[entry.key] = entry.value;
      }
      _loaded = true;
    } catch (error) {
      _error = 'Could not load remote switches. Showing last known values. ($error)';
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<void> toggleKillSwitch(bool activate) =>
      setFeature('global_emergency', activate);

  /// Flips a single flag, writes it through, and rolls back on failure.
  Future<void> setFeature(String feature, bool enabled) async {
    final previous = _flags[feature];
    _flags[feature] = enabled;
    _error = null;
    _notify();

    try {
      await _store.write(feature, enabled);
      _loaded = true;
    } catch (error) {
      if (previous == null) {
        _flags.remove(feature);
      } else {
        _flags[feature] = previous;
      }
      _error = 'Change to "$feature" was not saved. ($error)';
      _notify();
    }
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
