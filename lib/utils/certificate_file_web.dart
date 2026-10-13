// lib/utils/certificate_file_web.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;


import 'dart:html' as html;

Future<void> handleCertificateFile(
    Uint8List pdfBytes,
    String fileName,
    ) async {
  if (!kIsWeb) return;

  try {
    final blob = html.Blob(
      [pdfBytes],
      'application/pdf',
    );

    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..download = fileName;

    anchor.click();


    Future.delayed(
      const Duration(seconds: 5),
          () {
        html.Url.revokeObjectUrl(url);
      },
    );

    print('✅ Certificate downloaded: $fileName');
  } catch (e) {
    print('❌ Download error: $e');
  }
}