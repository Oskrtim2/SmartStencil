import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

/// QR code scanner screen for the client flow.
///
/// Scans a QR code containing a share token, fetches the presigned URL
/// from the backend, and navigates to the AR preview screen.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Scan Design QR'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // Scan overlay with cutout
          _buildScanOverlay(),

          // Bottom instruction / status
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return CustomPaint(
      painter: _ScanOverlayPainter(),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.85),
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        32, 48, 32, MediaQuery.of(context).padding.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isProcessing) ...[
            const CircularProgressIndicator(
              color: Color(0xFF8B5CF6),
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            _statusMessage ?? 'Point your camera at the design QR code',
            style: TextStyle(
              color: _statusMessage != null && _statusMessage!.contains('Error')
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFF1F5F9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your artist shared a QR code for the design preview',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFA78BFA), size: 18),
            label: const Text(
              'Modo Demo: Probar Realidad Aumentada Ahora',
              style: TextStyle(
                color: Color(0xFFA78BFA),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF8B5CF6), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.12),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/ar', arguments: {'isDemo': true});
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final rawValue = barcode.rawValue!;

    // Extract the share token from the QR data
    // Expected format: "inksight://share/{token}" or just the token UUID
    final token = _extractToken(rawValue);
    if (token == null) {
      setState(() => _statusMessage = 'Invalid QR code format');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Loading design…';
    });

    try {
      // Fetch presigned URL from backend
      final apiClient = ApiClient(baseUrl: _getApiBaseUrl());
      final response = await apiClient.getSharedDesign(token);

      if (!mounted) return;

      // Navigate to AR preview with the presigned URL
      await Navigator.pushReplacementNamed(
        context,
        '/ar',
        arguments: {
          'presignedUrl': response.presignedUrl,
          'metadata': response.metadata,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
      });

      // Reset after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _statusMessage = null);
        }
      });
    }
  }

  String? _extractToken(String rawValue) {
    // Deep link format
    final deepLinkMatch = RegExp(r'inksight://share/([a-zA-Z0-9\-]+)').firstMatch(rawValue);
    if (deepLinkMatch != null) return deepLinkMatch.group(1);

    // Plain UUID format
    final uuidMatch = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false)
        .firstMatch(rawValue);
    if (uuidMatch != null) return rawValue;

    // URL format: https://api.inksight.app/share/{token}
    final urlMatch = RegExp(r'/share/([a-zA-Z0-9\-]+)').firstMatch(rawValue);
    if (urlMatch != null) return urlMatch.group(1);

    return null;
  }

  String _getApiBaseUrl() {
    return ApiConfig.baseUrl;
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }
}

/// Paints the scan overlay with a transparent cutout and animated border.
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scanAreaSize = size.width * 0.65;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.4),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Semi-transparent overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(24)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withOpacity(0.6),
    );

    // Corner brackets
    final cornerLength = 28.0;
    final cornerPaint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final r = 12.0; // corner radius

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + cornerLength)
        ..lineTo(scanRect.left, scanRect.top + r)
        ..quadraticBezierTo(scanRect.left, scanRect.top, scanRect.left + r, scanRect.top)
        ..lineTo(scanRect.left + cornerLength, scanRect.top),
      cornerPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.top)
        ..lineTo(scanRect.right - r, scanRect.top)
        ..quadraticBezierTo(scanRect.right, scanRect.top, scanRect.right, scanRect.top + r)
        ..lineTo(scanRect.right, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.bottom - cornerLength)
        ..lineTo(scanRect.left, scanRect.bottom - r)
        ..quadraticBezierTo(scanRect.left, scanRect.bottom, scanRect.left + r, scanRect.bottom)
        ..lineTo(scanRect.left + cornerLength, scanRect.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.bottom)
        ..lineTo(scanRect.right - r, scanRect.bottom)
        ..quadraticBezierTo(scanRect.right, scanRect.bottom, scanRect.right, scanRect.bottom - r)
        ..lineTo(scanRect.right, scanRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
