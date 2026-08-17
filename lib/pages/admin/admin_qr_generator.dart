// lib/pages/admin/admin_qr_generator.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io' show Platform;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class AdminQRGenerator extends StatefulWidget {
  const AdminQRGenerator({super.key});

  @override
  State<AdminQRGenerator> createState() => _AdminQRGeneratorState();
}

class _AdminQRGeneratorState extends State<AdminQRGenerator> {
  final GlobalKey _qrKey = GlobalKey();
  String _canteenId = 'main';
  String _canteenName = 'Main Canteen';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCanteenData();
  }

  Future<void> _getCanteenData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('canteen')
          .doc('main')
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _canteenId = 'main';
            _canteenName = data['name'] ?? 'Main Canteen';
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _captureAndDownloadQR() async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Generating QR Code...'),
              ],
            ),
            backgroundColor: Color(0xFFFF6B35),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get the QR widget's render object
      final RenderRepaintBoundary boundary = _qrKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      
      if (byteData == null) {
        throw Exception('Failed to generate image');
      }
      
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save or download based on platform
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await ImageGallerySaver.saveImage(
          pngBytes,
          quality: 100,
          name: 'canteen_qr_${DateTime.now().millisecondsSinceEpoch}',
        );
        
        if (result != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ QR Code saved to gallery!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (kIsWeb) {
        // Web download
        try {
          final blob = html.Blob([pngBytes]);
          final url = html.Url.createObjectUrl(blob);
          
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', 'canteen_qr_${DateTime.now().millisecondsSinceEpoch}.png')
            ..style.display = 'none';
          
          final body = html.document.body;
          if (body != null) {
            body.append(anchor);
            anchor.click();
            anchor.remove();
          }
          
          html.Url.revokeObjectUrl(url);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ QR Code downloaded!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          throw Exception('Web download failed: $e');
        }
      } else {
        throw Exception('Download not supported on this platform');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareQR() async {
    await Share.share(
      'Scan this QR code to order from $_canteenName!\n\nCanteenQR - Scan.Order.Earn Rewards.',
      subject: 'Canteen QR Code',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Generate QR Code',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // QR Code Preview
                  RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      padding: const EdgeInsets.all(32),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Scan to Order',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: QrImageView(
                              data: 'canteenqr://$_canteenId',
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _canteenName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Scan to view menu and order',
                            style: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Print this QR code and place it on tables for customers to scan.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Download Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _captureAndDownloadQR,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.download),
                          label: Text(
                            'Download PNG',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareQR,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.share),
                          label: Text(
                            'Share',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Print Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🖨️ Print dialog would open here'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.print),
                      label: Text(
                        'Print QR Code',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}