import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo_ar_preview/core/permissions/permission_service.dart';
import 'package:tattoo_ar_preview/features/camera/data/camera_session.dart';

void main() {
  group('CameraSession permissions', () {
    test('reports a denied camera permission', () async {
      final CameraSession session = CameraSession(
        _FakePermissionGateway(PermissionDecision.denied),
      );

      await session.initialize();

      expect(session.status, CameraStatus.permissionDenied);
      expect(session.controller, isNull);
      session.dispose();
    });

    test('reports a permanently denied camera permission', () async {
      final CameraSession session = CameraSession(
        _FakePermissionGateway(PermissionDecision.permanentlyDenied),
      );

      await session.initialize();

      expect(session.status, CameraStatus.permissionPermanentlyDenied);
      expect(session.controller, isNull);
      session.dispose();
    });

    test('can retry after a denied permission without losing state', () async {
      final _FakePermissionGateway gateway = _FakePermissionGateway(
        PermissionDecision.denied,
      );
      final CameraSession session = CameraSession(gateway);

      await session.initialize();
      expect(session.status, CameraStatus.permissionDenied);

      gateway.decision = PermissionDecision.permanentlyDenied;
      await session.initialize();

      expect(session.status, CameraStatus.permissionPermanentlyDenied);
      session.dispose();
    });
  });
}

class _FakePermissionGateway implements PermissionGateway {
  _FakePermissionGateway(this.decision);

  PermissionDecision decision;

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<PermissionDecision> requestCameraAccess() async => decision;

  @override
  Future<void> requestGalleryAccessIfNeeded() async {}
}
