import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../qr_scanner/presentation/qr_scanner_screen.dart';
import '../ai_studio/presentation/ai_studio_screen.dart';
import '../ar_preview/presentation/ar_preview_screen.dart';
import '../profile/presentation/profile_screen.dart';
import '../auth/providers/auth_provider.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = 1});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    QrScannerScreen(),
    AiStudioScreen(),
    ArPreviewScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // If not authenticated, ensure redirect to login
    if (authState.isInitialized && !authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF14141F),
          border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF06B6D4)),
              label: 'Escanear QR',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_rounded, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.auto_awesome_rounded, color: Color(0xFFA78BFA)),
              label: 'Estudio IA',
            ),
            NavigationDestination(
              icon: Icon(Icons.view_in_ar_rounded, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.view_in_ar_rounded, color: Color(0xFF06B6D4)),
              label: 'Visor AR',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_rounded, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.account_circle_rounded, color: Color(0xFFA78BFA)),
              label: 'Mi Cuenta',
            ),
          ],
        ),
      ),
    );
  }
}
