import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/supabase_bootstrap.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase is available on every Flutter target. A build without
  // SUPABASE_URL / SUPABASE_ANON_KEY stays usable and the login screen shows
  // an explicit "not configured" state instead of a raw platform exception.
  await SupabaseBootstrap.initialize();

  runApp(
    ProviderScope(
      child: KashkoolApp(bootstrapError: SupabaseBootstrap.error),
    ),
  );
}

class KashkoolApp extends ConsumerWidget {
  const KashkoolApp({super.key, this.bootstrapError});

  final Object? bootstrapError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Kashkool',
      theme: KashkoolTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
