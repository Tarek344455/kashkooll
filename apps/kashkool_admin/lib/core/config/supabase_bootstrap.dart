import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'supabase_config.dart';

/// Supabase lifecycle for the super-admin console. Mirrors the main app.
class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static bool _ready = false;
  static String? _error;

  static bool get isReady => _ready;
  static String? get error => _error;

  static Future<void> initialize() async {
    final issue = SupabaseConfig.validationError;
    if (issue != null) {
      _ready = false;
      _error = issue;
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
      _ready = false;
      _error = '$error';
      debugPrint('Supabase initialization failed: $error');
    }
  }

  static sb.SupabaseClient get client => sb.Supabase.instance.client;
}
