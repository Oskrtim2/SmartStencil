import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/navigation/main_shell_screen.dart';
import 'features/ar_preview/presentation/ar_preview_screen.dart';
import 'features/qr_scanner/presentation/qr_scanner_screen.dart';
import 'features/ai_studio/presentation/ai_studio_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'shared/theme/app_theme.dart';

class InkSightApp extends ConsumerWidget {
  const InkSightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'InkSight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/main': (_) => const MainShellScreen(),
        '/scan': (_) => const QrScannerScreen(),
        '/ai': (_) => const AiStudioScreen(),
        '/ar': (_) => const ArPreviewScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}

/// Gatekeeper: strictly enforces login requirement
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Initial session check in progress
    if (!authState.isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: Color(0xFF8B5CF6),
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      );
    }

    // Mandatory Login check
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    // Authenticated -> Navigate to full app shell
    return const MainShellScreen();
  }
}
