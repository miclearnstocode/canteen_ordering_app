// lib/widgets/mobile_qr_scanner.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MobileQRScanner extends StatefulWidget {
  /// Called once per successful scan. The raw QR string is passed in.
  final Function(String) onScan;

  /// Optional: block further scans for this long after a hit.
  final Duration debounce;

  const MobileQRScanner({
    super.key,
    required this.onScan,
    this.debounce = const Duration(seconds: 3),
  });

  @override
  State<MobileQRScanner> createState() => _MobileQRScannerState();
}

class _MobileQRScannerState extends State<MobileQRScanner> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isScanning = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_isScanning) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _isScanning = true);
    widget.onScan(raw);

    Future.delayed(widget.debounce, () {
      if (mounted) setState(() => _isScanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Camera preview + detection ──
        MobileScanner(
          controller: _controller,
          onDetect: _handleDetect,
        ),

        // ── Viewfinder frame ──
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFFF6B35),
                width: 4,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // ── Hint text ──
        const Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Text(
            'Point the camera at the QR code',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}