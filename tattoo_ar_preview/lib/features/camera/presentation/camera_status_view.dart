import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/camera_session.dart';

class CameraStatusView extends StatelessWidget {
  const CameraStatusView({
    super.key,
    required this.session,
    required this.onRetry,
  });

  final CameraSession session;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final CameraStatus status = session.status;
    final _StatusContent content = _contentFor(status, session.errorMessage);
    final bool isBusy =
        status == CameraStatus.initializing || status == CameraStatus.idle;
    final bool isPermanentlyDenied =
        status == CameraStatus.permissionPermanentlyDenied;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF19191F), AppColors.background],
        ),
      ),
      child: SafeArea(
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
                    child: Icon(
                      content.icon,
                      color: AppColors.accent,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    content.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    content.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  if (isBusy) ...<Widget>[
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.6),
                    ),
                  ] else ...<Widget>[
                    const SizedBox(height: 28),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: isPermanentlyDenied
                              ? () => unawaited(_openSettings(context))
                              : onRetry,
                          icon: Icon(
                            isPermanentlyDenied
                                ? Icons.settings_outlined
                                : Icons.refresh_rounded,
                          ),
                          label: Text(
                            isPermanentlyDenied
                                ? 'Abrir ajustes'
                                : status == CameraStatus.permissionDenied
                                ? 'Permitir cámara'
                                : 'Reintentar',
                          ),
                        ),
                        if (status == CameraStatus.permissionDenied)
                          TextButton.icon(
                            onPressed: () => unawaited(_openSettings(context)),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 18,
                            ),
                            label: const Text('Abrir ajustes del sistema'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    final bool opened = await session.openSettings();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron abrir los ajustes del sistema.'),
        ),
      );
    }
  }

  _StatusContent _contentFor(CameraStatus status, String? errorMessage) {
    switch (status) {
      case CameraStatus.idle:
      case CameraStatus.initializing:
        return const _StatusContent(
          icon: Icons.camera_alt_outlined,
          title: 'Preparando cámara',
          message:
              'Estamos activando la cámara trasera y sus ajustes '
              'automáticos de enfoque y exposición.',
        );
      case CameraStatus.permissionDenied:
        return const _StatusContent(
          icon: Icons.no_photography_outlined,
          title: 'Permiso de cámara necesario',
          message:
              'SmartStencil necesita la cámara trasera para previsualizar '
              'tatuajes sobre la piel en tiempo real.',
        );
      case CameraStatus.permissionPermanentlyDenied:
        return const _StatusContent(
          icon: Icons.lock_outline_rounded,
          title: 'Cámara bloqueada',
          message:
              'El permiso de cámara está desactivado. Ábrelo en los '
              'ajustes del sistema y vuelve a intentarlo.',
        );
      case CameraStatus.unavailable:
        return _StatusContent(
          icon: Icons.videocam_off_outlined,
          title: 'Cámara no disponible',
          message: errorMessage ?? 'No se encontró una cámara utilizable.',
        );
      case CameraStatus.failure:
        return _StatusContent(
          icon: Icons.error_outline_rounded,
          title: 'No se pudo abrir la cámara',
          message:
              errorMessage ??
              'Ocurrió un error al iniciar la cámara. Inténtalo de nuevo.',
        );
      case CameraStatus.ready:
        return const _StatusContent(
          icon: Icons.camera_alt_outlined,
          title: 'Cámara lista',
          message: 'La cámara está lista.',
        );
    }
  }
}

class _StatusContent {
  const _StatusContent({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}
