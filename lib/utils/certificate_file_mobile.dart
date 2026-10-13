
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> handleCertificateFile(
    Uint8List pdfBytes,
    String fileName,
    ) async {
  final output = await getTemporaryDirectory();
  final file = File('${output.path}/$fileName');
  await file.writeAsBytes(pdfBytes);

  try {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'I earned a certificate in Skill Challenge App!\n\nKeep learning and growing!\n#SkillChallenge #Learning #Certificate',
    );
  } catch (e) {
    print('Error sharing: $e');
  }
}