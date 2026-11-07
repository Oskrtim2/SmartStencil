import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'tattoo_transform.dart';

class TattooGestureController extends ChangeNotifier {
  TattooTransform _transform = const TattooTransform();
  TattooTransform _startTransform = const TattooTransform();
  Offset _startFocalPoint = Offset.zero;
  Size _viewportSize = Size.zero;

  TattooTransform get transform => _transform;

  void updateViewport(Size size) {
    _viewportSize = size;
  }

  void onScaleStart(ScaleStartDetails details) {
    _startTransform = _transform;
    _startFocalPoint = details.localFocalPoint;
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    if (_viewportSize.isEmpty) {
      return;
    }
    final Offset delta = details.localFocalPoint - _startFocalPoint;
    final TattooTransform next = _startTransform
        .copyWith(
          translation:
              _startTransform.translation +
              Offset(
                delta.dx / _viewportSize.width,
                delta.dy / _viewportSize.height,
              ),
          scale: _startTransform.scale * details.scale,
          rotation: _startTransform.rotation + details.rotation,
        )
        .normalized();
    if (next == _transform) {
      return;
    }
    _transform = next;
    notifyListeners();
  }

  void reset() {
    if (_transform == const TattooTransform()) {
      return;
    }
    _transform = const TattooTransform();
    notifyListeners();
  }
}
