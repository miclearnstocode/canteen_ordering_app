// lib/widgets/qr_scanner_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';

// Only import on mobile, not on web
class QRScannerWrapper extends StatefulWidget {
  final Function(String) onScan;
  final VoidCallback? onError;

  const QRScannerWrapper({
    super.key,
    required this.onScan,
    this.onError,
  });

  @override
  State<QRScannerWrapper> createState() => _QRScannerWrapperState();
}

class _QRScannerWrapperState extends State<QRScannerWrapper> {
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebFallback();
    }

    // Mobile - use the actual QR scanner
    return _buildMobileScanner();
  }

  Widget _buildMobileScanner() {
    // Use a placeholder for mobile - the actual QR scanner will be loaded
    // on mobile devices only
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Camera Ready',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            Text(
              'Point camera at QR code',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebFallback() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 120,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'QR Scanner',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Camera access is not available on web.\nPlease use the mobile app to scan QR codes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showManualQRDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.edit),
              label: Text(
                'Enter QR Code Manually',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualQRDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter QR Code'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter QR code data...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qrData = controller.text.trim();
              if (qrData.isNotEmpty) {
                Navigator.pop(context);
                widget.onScan(qrData);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
            ),
            child: const Text('Scan'),
          ),
        ],
      ),
    );
  }
}