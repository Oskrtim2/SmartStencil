import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class InkControls extends StatelessWidget {
  const InkControls({
    super.key,
    required this.opacity,
    required this.hasDesign,
    required this.isPicking,
    required this.isCapturing,
    required this.canCapture,
    required this.onOpacityChanged,
    required this.onPick,
    required this.onCapture,
  });

  final ValueListenable<double> opacity;
  final bool hasDesign;
  final bool isPicking;
  final bool isCapturing;
  final bool canCapture;
  final ValueChanged<double> onOpacityChanged;
  final VoidCallback onPick;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final bool isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final Widget opacityControl = _OpacityControl(
      opacity: opacity,
      enabled: hasDesign && !isCapturing,
      hasDesign: hasDesign,
      onChanged: onOpacityChanged,
    );
    final Widget galleryButton = _GalleryButton(
      hasDesign: hasDesign,
      isPicking: isPicking,
      enabled: !isCapturing,
      onPressed: onPick,
    );
    final Widget shutter = _ShutterButton(
      enabled: canCapture && !isCapturing,
      busy: isCapturing,
      onPressed: onCapture,
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.fromLTRB(
              isLandscape ? 22 : 18,
              isLandscape ? 16 : 15,
              isLandscape ? 22 : 18,
              isLandscape ? 16 : 17,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: isLandscape
                ? Row(
                    children: <Widget>[
                      Expanded(child: opacityControl),
                      const SizedBox(width: 18),
                      galleryButton,
                      const SizedBox(width: 16),
                      shutter,
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      opacityControl,
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: galleryButton,
                            ),
                            Align(alignment: Alignment.center, child: shutter),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _OpacityControl extends StatelessWidget {
  const _OpacityControl({
    required this.opacity,
    required this.enabled,
    required this.hasDesign,
    required this.onChanged,
  });

  final ValueListenable<double> opacity;
  final bool enabled;
  final bool hasDesign;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: opacity,
      builder: (BuildContext context, double value, Widget? child) {
        final int percentage = (value * 100).round();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.opacity_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 7),
                Text(
                  'Intensidad del tinte',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const Spacer(),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.accent,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
            Slider(
              value: value,
              onChanged: enabled ? onChanged : null,
              semanticFormatterCallback: (double next) =>
                  'Intensidad del tinte ${(next * 100).round()} por ciento',
            ),
            Text(
              hasDesign
                  ? 'Arrastra, pellizca y gira con dos dedos'
                  : 'Importa un PNG con transparencia para empezar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({
    required this.hasDesign,
    required this.isPicking,
    required this.enabled,
    required this.onPressed,
  });

  final bool hasDesign;
  final bool isPicking;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: hasDesign
          ? 'Reemplazar diseño PNG'
          : 'Importar diseño PNG transparente',
      child: FloatingActionButton.small(
        heroTag: 'smartstencil-gallery',
        onPressed: enabled && !isPicking ? onPressed : null,
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: AppColors.surfaceHigh,
        foregroundColor: AppColors.accent,
        child: isPicking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.accent,
                ),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.enabled,
    required this.busy,
    required this.onPressed,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color ringColor = enabled
        ? AppColors.textPrimary
        : AppColors.textSecondary.withValues(alpha: 0.35);
    final Color coreColor = enabled
        ? AppColors.textPrimary
        : AppColors.textSecondary.withValues(alpha: 0.24);

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Capturar y compartir',
      child: Tooltip(
        message: enabled || busy
            ? 'Capturar y compartir'
            : 'Importa un diseño para capturar',
        child: GestureDetector(
          onTap: enabled ? onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 78,
            height: 78,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.18),
              border: Border.all(color: ringColor, width: 3),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: coreColor,
              ),
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: AppColors.background,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
