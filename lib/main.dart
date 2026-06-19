import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/auth/screens/login_screen.dart';
import 'app_shell.dart';

Future<void> main() async {
  final startupStopwatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env may not exist yet — safe to ignore
  }

  final mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  if (mapboxToken.isNotEmpty && !mapboxToken.contains('YOUR_')) {
    MapboxOptions.setAccessToken(mapboxToken);
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('YOUR_')) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      if (kDebugMode) {
        debugPrint('🚀 Supabase initialized successfully');
      }

      // Refresh session on startup if it is expired to prevent Realtime token errors
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      if (session != null && session.isExpired) {
        if (kDebugMode) {
          debugPrint(
              '🔑 Supabase session is expired on startup, refreshing...');
        }
        try {
          await client.auth.refreshSession();
          if (kDebugMode) {
            debugPrint('🔑 Supabase session refreshed successfully');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Supabase session refresh failed, signing out: $e');
          }
          try {
            await client.auth.signOut();
          } catch (_) {}
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Supabase init failed: $e');
      }
    }
  } else {
    if (kDebugMode) {
      debugPrint('⚠️ Supabase credentials missing in .env');
    }
  }

  startupStopwatch.stop();
  if (kDebugMode) {
    debugPrint(
        '⏱️ App startup initialization completed in ${startupStopwatch.elapsedMilliseconds}ms');
  }

  runApp(
    const ProviderScope(
      child: RoadCareApp(),
    ),
  );
}

class RoadCareApp extends ConsumerWidget {
  const RoadCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'RoadCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authState.when(
        data: (user) {
          if (user != null) return const AppShell();
          return const LoginScreen();
        },
        loading: () => const _SplashScreen(),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C6AE), Color(0xFF009E8D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C6AE).withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.report_problem_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'RoadCare',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Community Pothole Reporting',
              style: TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Color(0xFF00C6AE),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
