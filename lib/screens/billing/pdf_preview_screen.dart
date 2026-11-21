import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';

/// Full-screen PDF preview allowing direct print and share.
class PdfPreviewScreen extends StatelessWidget {
  final String title;
  final String fileName;
  final Future<Uint8List> Function() pdfDataBuilder;

  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.fileName,
    required this.pdfDataBuilder,
  });

  static Route<void> route({
    required String title,
    required String fileName,
    required Future<Uint8List> Function() pdfDataBuilder,
  }) {
    return MaterialPageRoute(
      builder: (_) => PdfPreviewScreen(
        title: title,
        fileName: fileName,
        pdfDataBuilder: pdfDataBuilder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: PdfPreview(
        build: (_) => pdfDataBuilder(),
        pdfFileName: fileName,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        actions: const [],
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Generating PDF document...'),
            ],
          ),
        ),
      ),
    );
  }
}
