import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Simultaneous multi-gesture recognizer for tattoo manipulation.
///
/// Supports concurrent:
/// - **Drag** (single finger): Reposition the tattoo stencil.
/// - **Pinch** (two fingers): Scale the tattoo.
/// - **Rotate** (two fingers): Rotate the tattoo.
///
/// Gestures are decomposed from raw pointer data rather than using
/// competing GestureRecognizer instances, so all three transforms
/// can update simultaneously during a two-finger interaction.
class TattooGestureController {
  /// Callbacks
  final void Function(Offset delta)? onPan;
  final void Function(double scaleFactor)? onScale;
  final void Function(double angleDelta)? onRotate;
  final void Function()? onGestureStart;
  final void Function()? onGestureEnd;

  /// Internal state
  final Map<int, Offset> _activePointers = {};
  double? _previousAngle;
  double? _previousDistance;
  Offset? _previousMidpoint;

  TattooGestureController({
    this.onPan,
    this.onScale,
    this.onRotate,
    this.onGestureStart,
    this.onGestureEnd,
  });

  /// Handle pointer down events.
  void onPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    if (_activePointers.length == 1) {
      onGestureStart?.call();
    }
    _resetReferenceState();
  }

  /// Handle pointer move events.
  void onPointerMove(PointerMoveEvent event) {
    if (!_activePointers.containsKey(event.pointer)) return;
    _activePointers[event.pointer] = event.localPosition;

    if (_activePointers.length == 1) {
      // Single finger → pan only
      _handlePan(event.delta);
    } else if (_activePointers.length == 2) {
      // Two fingers → simultaneous pinch + rotate + pan
      _handleTwoFingerGesture();
    }
  }

  /// Handle pointer up events.
  void onPointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    _resetReferenceState();
    if (_activePointers.isEmpty) {
      onGestureEnd?.call();
    }
  }

  /// Handle pointer cancel events.
  void onPointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    _resetReferenceState();
    if (_activePointers.isEmpty) {
      onGestureEnd?.call();
    }
  }

  /// Build a [Listener] widget that captures raw pointer events.
  Widget buildListener({required Widget child}) {
    return Listener(
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      child: child,
    );
  }

  // ── Private ───────────────────────────────────────

  void _handlePan(Offset delta) {
    onPan?.call(delta);
  }

  void _handleTwoFingerGesture() {
    final pointers = _activePointers.values.toList();
    final p1 = pointers[0];
    final p2 = pointers[1];

    final midpoint = (p1 + p2) / 2.0;
    final distance = (p1 - p2).distance;
    final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);

    if (_previousDistance != null && _previousAngle != null && _previousMidpoint != null) {
      // Scale factor (pinch)
      if (_previousDistance! > 0) {
        final scaleFactor = distance / _previousDistance!;
        if (scaleFactor != 1.0) {
          onScale?.call(scaleFactor);
        }
      }

      // Rotation delta
      var angleDelta = angle - _previousAngle!;
      // Normalize to [-π, π]
      if (angleDelta > math.pi) angleDelta -= 2 * math.pi;
      if (angleDelta < -math.pi) angleDelta += 2 * math.pi;
      if (angleDelta.abs() > 0.001) {
        onRotate?.call(angleDelta);
      }

      // Two-finger pan (midpoint movement)
      final panDelta = midpoint - _previousMidpoint!;
      if (panDelta.distance > 0.5) {
        onPan?.call(panDelta);
      }
    }

    _previousDistance = distance;
    _previousAngle = angle;
    _previousMidpoint = midpoint;
  }

  void _resetReferenceState() {
    _previousAngle = null;
    _previousDistance = null;
    _previousMidpoint = null;
  }
}
