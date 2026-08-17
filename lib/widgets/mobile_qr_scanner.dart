// lib/widgets/mobile_qr_scanner.dart
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class MobileQRScanner extends StatefulWidget {
  final Function(String) onScan;

  const MobileQRScanner({
    super.key,
    required this.onScan,
  });

  @override
  State<MobileQRScanner> createState() => _MobileQRScannerState();
}

class _MobileQRScannerState extends State<MobileQRScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanning = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!_isScanning) {
        setState(() => _isScanning = true);
        widget.onScan(scanData.code ?? '');
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _isScanning = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: const Color(0xFFFF6B35),
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: 250,
      ),
    );
  }
}