import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../editor/presentation/tattoo_editor_screen.dart';

class ShaderBootstrap extends StatefulWidget {
  const ShaderBootstrap({super.key});

  @override
  State<ShaderBootstrap> createState() => _ShaderBootstrapState();
}

class _ShaderBootstrapState extends State<ShaderBootstrap> {
  static const String _shaderAsset = 'shaders/ink_blend.frag';

  late Future<ui.FragmentProgram> _programFuture;

  @override
  void initState() {
    super.initState();
    _programFuture = ui.FragmentProgram.fromAsset(_shaderAsset);
  }

  void _retry() {
    setState(() {
      _programFuture = ui.FragmentProgram.fromAsset(_shaderAsset);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.FragmentProgram>(
      future: _programFuture,
      builder:
          (BuildContext context, AsyncSnapshot<ui.FragmentProgram> snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return TattooEditorScreen(inkProgram: snapshot.data!);
            }
            if (snapshot.hasError) {
              debugPrint(
                'SmartStencil: no se pudo cargar el shader: '
                '${snapshot.error}',
              );
              return _ShaderFailureView(onRetry: _retry);
            }
            return const _SplashView();
          },
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(26),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.brush_rounded,
                color: AppColors.background,
                size: 42,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'SmartStencil',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.8),
            ),
            const SizedBox(height: 6),
            Text(
              'Cargando el motor de tinta…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 30),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShaderFailureView extends StatelessWidget {
  const _ShaderFailureView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.blur_off_rounded,
                      color: AppColors.accent,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No se pudo cargar el motor de tinta',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'SmartStencil necesita compilar su shader de mezcla para '
                    'previsualizar el tatuaje. Cierra cualquier otra app de '
                    'cámara y vuelve a intentarlo.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
