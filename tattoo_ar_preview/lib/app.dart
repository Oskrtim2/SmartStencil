import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/bootstrap/presentation/shader_bootstrap.dart';

class SmartStencilApp extends StatelessWidget {
  const SmartStencilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartStencil',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const ShaderBootstrap(),
    );
  }
}
