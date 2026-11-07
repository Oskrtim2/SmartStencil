import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum PermissionDecision { granted, denied, permanentlyDenied }

abstract interface class PermissionGateway {
  Future<PermissionDecision> requestCameraAccess();

  Future<void> requestGalleryAccessIfNeeded();

  Future<bool> openSettings();
}

class PermissionService implements PermissionGateway {
  const PermissionService();

  @override
  Future<PermissionDecision> requestCameraAccess() async {
    final PermissionStatus current = await Permission.camera.status;
    if (current.isGranted || current.isLimited) {
      return PermissionDecision.granted;
    }
    if (current.isPermanentlyDenied || current.isRestricted) {
      return PermissionDecision.permanentlyDenied;
    }

    final PermissionStatus requested = await Permission.camera.request();
    if (requested.isGranted || requested.isLimited) {
      return PermissionDecision.granted;
    }
    if (requested.isPermanentlyDenied || requested.isRestricted) {
      return PermissionDecision.permanentlyDenied;
    }
    return PermissionDecision.denied;
  }

  @override
  Future<void> requestGalleryAccessIfNeeded() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    final PermissionStatus current = await Permission.photos.status;
    if (current.isGranted || current.isLimited) {
      return;
    }
    await Permission.photos.request();
  }

  @override
  Future<bool> openSettings() => openAppSettings();
}
