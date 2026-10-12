import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/ar_preview/presentation/ar_preview_screen.dart';
import 'features/qr_scanner/presentation/qr_scanner_screen.dart';
import 'shared/theme/app_theme.dart';

class InkSightApp extends ConsumerWidget {
  const InkSightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'InkSight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: '/scan',
      routes: {
        '/scan': (_) => const QrScannerScreen(),
        '/ar': (_) => const ArPreviewScreen(),
      },
    );
  }
}
