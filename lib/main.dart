import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/app_config.dart';
import 'core/models/kashkool_models.dart';
import 'screens/login_screen.dart';
import 'screens/workspace_shell.dart';
import 'state/kashkool_controller.dart';
import 'ui/space_glass.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
  runApp(const KashkoolApp());
}

class KashkoolApp extends StatefulWidget {
  const KashkoolApp({super.key});

  @override
  State<KashkoolApp> createState() => _KashkoolAppState();
}

class _KashkoolAppState extends State<KashkoolApp> {
  final KashkoolController _controller = KashkoolController();
  bool _bootComplete = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final isAr = _controller.language == AppLanguage.ar;
        final baseTheme = ThemeData.dark(useMaterial3: true);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kashkool — كشكول',
          locale: Locale(isAr ? 'ar' : 'en'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: baseTheme.copyWith(
            scaffoldBackgroundColor: KashkoolColors.cosmicBlack,
            textTheme: GoogleFonts.cairoTextTheme(baseTheme.textTheme),
            colorScheme: const ColorScheme.dark(
              primary: KashkoolColors.neonCyan,
              secondary: KashkoolColors.nebulaPurple,
              surface: KashkoolColors.spaceSurface,
            ),
          ),
          home: Stack(
            children: [
              CosmicParallaxCanvas(
                examModeActive: _controller.examModeActive,
              ),
              if (!_controller.signedIn)
                LoginScreen(controller: _controller)
              else
                WorkspaceShell(controller: _controller),
              if (!_bootComplete)
                OrbitalIgnitionSplash(
                  onComplete: () {
                    if (mounted) setState(() => _bootComplete = true);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
