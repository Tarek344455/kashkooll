import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'supabase_config.dart';

/// Tracks whether Supabase initialised successfully.
///
/// Screens use this to explain an explicitly degraded mode instead of
/// surfacing a raw platform exception. A build without credentials opens
/// normally and reports "not configured" — it never uses fake data.
class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static bool _ready = false;
  static String? _error;

  static bool get isReady => _ready;
  static String? get error => _error;

  static Future<void> initialize() async {
    final issue = SupabaseConfig.validationError;
    if (issue != null) {
      markUnavailable(issue);
      return;
    }

    try {
      await sb.Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
        debug: kDebugMode,
      );
      _ready = true;
      _error = null;
    } catch (error) {
      markUnavailable('$error');
      debugPrint('Supabase initialization failed: $error');
    }
  }

  static void markUnavailable(String reason) {
    _ready = false;
    _error = reason;
  }

  /// Only call after [initialize] succeeded.
  static sb.SupabaseClient get client => sb.Supabase.instance.client;
}
