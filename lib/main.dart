import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:drive_safe_app/screens/admin_dashboard.dart';
import 'package:drive_safe_app/screens/dashboard_screen.dart';
import 'package:drive_safe_app/screens/dl_screen.dart';
import 'package:drive_safe_app/firebase_options.dart';
import 'package:drive_safe_app/screens/login_screen.dart';
import 'package:drive_safe_app/screens/notifications_screen.dart';
import 'package:drive_safe_app/screens/profile_screen.dart';
import 'package:drive_safe_app/screens/register_screen.dart';
import 'package:drive_safe_app/screens/report_issue_screen.dart';
import 'package:drive_safe_app/screens/settings_screen.dart';
import 'package:drive_safe_app/screens/track_screen.dart';
import 'package:drive_safe_app/models/app_settings_model.dart';
import 'package:drive_safe_app/services/auth_service.dart';
import 'package:drive_safe_app/services/local_storage_service.dart';
import 'dart:ui';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
    return true;
  };
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF7F0000),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: SelectableText(
              details.exceptionAsString(),
              style: const TextStyle(color: Colors.yellow, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppSettings>(
      future: LocalStorageService.getSettings(),
      builder: (context, settingsSnapshot) {
        final initialSettings = settingsSnapshot.data ?? LocalStorageService.settingsNotifier.value;

        return ValueListenableBuilder<AppSettings>(
          valueListenable: LocalStorageService.settingsNotifier,
          builder: (context, liveSettings, _) {
            final settings = settingsSnapshot.connectionState == ConnectionState.done
                ? liveSettings
                : initialSettings;
            final accentColor = settings.strongBlueAccent
                ? const Color(0xFF0B65C2)
                : const Color(0xFF2F80ED);

            return MaterialApp(
              title: 'Drive Safe',
              theme: ThemeData(
                primaryColor: accentColor,
                colorScheme: ColorScheme.fromSeed(seedColor: accentColor),
                scaffoldBackgroundColor: Colors.white,
                appBarTheme: AppBarTheme(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6B400),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(foregroundColor: accentColor),
                ),
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              home: const _AppHomeGate(),
              routes: {
                '/home': (_) => const _AppHomeGate(),
                '/login': (_) => const LoginScreen(),
                '/register': (_) => const RegisterScreen(),
                '/dashboard': (_) => const DashboardScreen(),
                '/admin': (_) => const AdminDashboard(),
                '/report': (_) => const ReportIssueScreen(),
                '/track': (_) => const TrackScreen(),
                '/profile': (_) => const ProfileScreen(),
                '/dl': (_) => const DLScreen(),
                '/notifications': (_) => const NotificationsScreen(),
                '/settings': (_) => const SettingsScreen(),
              },
            );
          },
        );
      },
    );
  }
}

class _AppHomeGate extends StatelessWidget {
  const _AppHomeGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object?>>(
      future: Future.wait<Object?>([
        AuthService.getCurrentUserProfile(),
        AuthService.isCurrentUserAdmin(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _LoadingScreen();
        }

        final sessionData = snapshot.data ?? const <Object?>[];
        final currentUser = sessionData.isNotEmpty ? sessionData[0] : null;
        final isAdminSession = sessionData.length > 1 ? (sessionData[1] as bool? ?? false) : false;

        if (isAdminSession) {
          return const AdminDashboard();
        }

        if (currentUser != null) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
