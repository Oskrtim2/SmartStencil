import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ar/ar_platform_bridge.dart';
import '../../../core/ar/ar_session_controller.dart';
import '../../../core/ar/native_ar_bridge.dart';

/// Provides the [ArPlatformBridge] instance.
/// Defaults to [NativeArBridge], which automatically provides AR on device or simulation mode as fallback.
final arPlatformBridgeProvider = Provider<ArPlatformBridge>((ref) {
  return NativeArBridge();
});

/// Provides the [ArSessionController] — the top-level AR orchestrator.
///
/// Lifecycle:
/// - Created once per AR preview session.
/// - Disposed when the provider is no longer watched.
final arSessionControllerProvider = Provider.autoDispose<ArSessionController>((ref) {
  final bridge = ref.watch(arPlatformBridgeProvider);
  final controller = ArSessionController(bridge: bridge);

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});
