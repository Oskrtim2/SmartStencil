import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraViewfinder extends StatelessWidget {
  const CameraViewfinder({super.key, required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CameraValue>(
      valueListenable: controller,
      builder: (BuildContext context, CameraValue value, Widget? child) {
        final Size? previewSize = value.previewSize;
        if (!value.isInitialized || previewSize == null) {
          return const ColoredBox(color: Colors.black);
        }
        final bool isLandscape =
            value.deviceOrientation == DeviceOrientation.landscapeLeft ||
            value.deviceOrientation == DeviceOrientation.landscapeRight;
        final double width = isLandscape
            ? previewSize.width
            : previewSize.height;
        final double height = isLandscape
            ? previewSize.height
            : previewSize.width;
        return ClipRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: width,
                height: height,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }
}
