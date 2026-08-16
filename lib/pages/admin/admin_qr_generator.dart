// lib/pages/admin/admin_qr_generator.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:typed_data';
import 'dart:io';
// ignore: deprecated_member_use
import 'dart:html' as html;

class AdminQRGenerator extends StatefulWidget {
  const AdminQRGenerator({super.key});

  @override
  State<AdminQRGenerator> createState() => _AdminQRGeneratorState();
}

class _AdminQRGeneratorState extends State<AdminQRGenerator> {
  final ScreenshotController _screenshotController = ScreenshotController();
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
    } catch (e) {
      print('Error getting canteen data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadQR() async {
    try {
      // Capture the QR code widget as image
      final Uint8List? image = await _screenshotController.capture();
      
      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to capture QR code'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Save to gallery (Android/iOS) or download (web)
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await ImageGallerySaver.saveImage(
          image,
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
        // For web, create a download link
        try {
          // Create a blob from the image data
          final blob = html.Blob([image]);
          final url = html.Url.createObjectUrl(blob);
          
          // Create an anchor element and trigger download
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', 'canteen_qr_${DateTime.now().millisecondsSinceEpoch}.png')
            ..style.display = 'none';
          
          // Add to body, click, and remove
          final body = html.document.body;
          if (body != null) {
            body.append(anchor);
            anchor.click();
            // Use remove() instead of removeChild
            anchor.remove();
          }
          
          // Revoke the URL to free memory
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
          print('Web download error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error downloading: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Fallback for other platforms
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download not supported on this platform'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error downloading QR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareQR() async {
    try {
      final Uint8List? image = await _screenshotController.capture();
      
      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to capture QR code'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Share the QR code
      await Share.share(
        'Scan this QR code to order from $_canteenName!',
        subject: 'Canteen QR Code',
      );
    } catch (e) {
      print('Error sharing QR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Generate QR Code',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
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
                  Screenshot(
                    controller: _screenshotController,
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
                        children: [
                          Text(
                            'Scan to Order',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
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
                            '$_canteenName',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
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
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _downloadQR,
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