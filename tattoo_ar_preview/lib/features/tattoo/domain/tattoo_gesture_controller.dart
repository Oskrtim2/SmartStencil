import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'tattoo_transform.dart';

class TattooGestureController extends ChangeNotifier {
  TattooTransform _transform = const TattooTransform();
  Size _viewportSize = Size.zero;
  double _lastGestureScale = 1;
  double _lastGestureRotation = 0;
  Offset _lastFocalPoint = Offset.zero;
  int _lastPointerCount = 0;

  TattooTransform get transform => _transform;

  void updateViewport(Size size) {
    _viewportSize = size;
  }

  void onScaleStart(ScaleStartDetails details) {
    _lastGestureScale = 1;
    _lastGestureRotation = 0;
    _lastFocalPoint = details.localFocalPoint;
    _lastPointerCount = details.pointerCount;
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    if (_viewportSize.isEmpty) {
      return;
    }
    if (details.pointerCount != _lastPointerCount) {
      _lastPointerCount = details.pointerCount;
      _lastGestureScale = details.scale;
      _lastGestureRotation = details.rotation;
      _lastFocalPoint = details.localFocalPoint;
      return;
    }

    final double gestureScale = details.scale.isFinite && details.scale >= 0
        ? details.scale
        : _lastGestureScale;
    final double gestureRotation = details.rotation.isFinite
        ? details.rotation
        : _lastGestureRotation;
    final double scaleDelta = _lastGestureScale > 0
        ? gestureScale / _lastGestureScale
        : 1;
    final double rotationDelta = gestureRotation - _lastGestureRotation;
    final Offset focalDelta = details.localFocalPoint - _lastFocalPoint;

    final TattooTransform next = _transform
        .copyWith(
          translation:
              _transform.translation +
              Offset(
                focalDelta.dx / _viewportSize.width,
                focalDelta.dy / _viewportSize.height,
              ),
          scale: _transform.scale * scaleDelta,
          rotation: _transform.rotation + rotationDelta,
        )
        .normalized();

    _lastGestureScale = gestureScale;
    _lastGestureRotation = gestureRotation;
    _lastFocalPoint = details.localFocalPoint;

    if (next == _transform) {
      return;
    }
    _transform = next;
    notifyListeners();
  }

  void onScaleEnd() {
    _lastGestureScale = 1;
    _lastGestureRotation = 0;
    _lastFocalPoint = Offset.zero;
    _lastPointerCount = 0;
  }

  void reset() {
    if (_transform == const TattooTransform()) {
      return;
    }
    _transform = const TattooTransform();
    notifyListeners();
  }
}
