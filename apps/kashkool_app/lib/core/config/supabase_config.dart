/// Compile-time Supabase configuration.
///
/// Both values are public by design (RLS is the security boundary). They are
/// injected with --dart-define; no credential is ever hardcoded or committed:
///
///   flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=<anon-key>
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => validationError == null;

  /// Explicit reason the client cannot be initialised, null when healthy.
  /// Never fabricate a fallback project — that would send real OTPs nowhere.
  static String? get validationError {
    if (url.isEmpty) return 'SUPABASE_URL is not configured.';
    if (anonKey.isEmpty) return 'SUPABASE_ANON_KEY is not configured.';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'SUPABASE_URL is not a valid URL.';
    }
    if (uri.scheme != 'https' && uri.host != '127.0.0.1' && uri.host != 'localhost') {
      return 'SUPABASE_URL must use HTTPS (localhost is allowed for development).';
    }
    return null;
  }
}
