class AppConfig {
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static const String groqApiKey =
      String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const String deepseekApiKey =
      String.fromEnvironment('DEEPSEEK_API_KEY', defaultValue: '');
  static const String openrouterApiKey =
      String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');
  static const String nvidiaApiKey =
      String.fromEnvironment('NVIDIA_API_KEY', defaultValue: '');
  static const String opencodeApiKey =
      String.fromEnvironment('OPENCODE_API_KEY', defaultValue: '');
  static const String omnirouteBaseUrl =
      String.fromEnvironment('OMNIROUTE_BASE_URL', defaultValue: '');
  static const String omnirouteApiKey =
      String.fromEnvironment('OMNIROUTE_API_KEY', defaultValue: '');

  static bool get isSupabaseConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
