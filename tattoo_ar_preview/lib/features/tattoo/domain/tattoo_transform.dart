import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';

@immutable
class TattooTransform {
  const TattooTransform({
    this.translation = Offset.zero,
    this.scale = 1,
    this.rotation = 0,
  });

  static const double minScale = AppConstants.minTattooScale;
  static const double maxScale = AppConstants.maxTattooScale;
  static const double maxTranslation = AppConstants.maxTattooTranslation;

  final Offset translation;
  final double scale;
  final double rotation;

  TattooTransform copyWith({
    Offset? translation,
    double? scale,
    double? rotation,
  }) {
    return TattooTransform(
      translation: translation ?? this.translation,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }

  TattooTransform normalized() {
    return TattooTransform(
      translation: Offset(
        translation.dx.clamp(-maxTranslation, maxTranslation).toDouble(),
        translation.dy.clamp(-maxTranslation, maxTranslation).toDouble(),
      ),
      scale: scale.clamp(minScale, maxScale).toDouble(),
      rotation: _normalizeAngle(rotation),
    );
  }

  static double _normalizeAngle(double angle) {
    const double fullTurn = math.pi * 2;
    double result = angle % fullTurn;
    if (result > math.pi) {
      result -= fullTurn;
    } else if (result < -math.pi) {
      result += fullTurn;
    }
    return result;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TattooTransform &&
            translation == other.translation &&
            scale == other.scale &&
            rotation == other.rotation;
  }

  @override
  int get hashCode => Object.hash(translation, scale, rotation);

  @override
  String toString() {
    return 'TattooTransform(translation: $translation, scale: $scale, '
        'rotation: $rotation)';
  }
}
