/// Compile-time Supabase configuration for the command centre.
/// Uses the same --dart-define values as the main app (public anon key only).
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

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
