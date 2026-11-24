import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/admin_theme.dart';
import 'core/config/supabase_bootstrap.dart';
import 'features/dashboard/presentation/god_mode_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  runApp(const ProviderScope(child: KashkoolAdminApp()));
}

class KashkoolAdminApp extends StatelessWidget {
  const KashkoolAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kashkool Command Centre',
      theme: AdminTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const GodModeDashboard(),
    );
  }
}
