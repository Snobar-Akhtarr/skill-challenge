import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ✅ Helper import
import '../../utils/certificate_file.dart';
import '../../theme/app_theme.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  List<Map<String, dynamic>> _certificates = [];
  bool _loading = true;
  int _completedChallenges = 0;
  String _userName = '';
  bool _isGenerating = false;

  final Map<String, Color> _skillColors = {
    'AI': const Color(0xFF7B2FBE),
    'Artificial Intelligence': const Color(0xFF7B2FBE),
    'Data Science': const Color(0xFF1976D2),
    'Flutter': const Color(0xFF00BCD4),
    'Cyber Security': const Color(0xFFD32F2F),
    'Cybersecurity': const Color(0xFFD32F2F),
    'English Speaking': const Color(0xFF388E3C),
    'Web Development': const Color(0xFF00796B),
    'Web': const Color(0xFF00796B),
    'web': const Color(0xFF00796B),
    'SQL': const Color(0xFFF57C00),
    'Python': const Color(0xFFF9A825),
    'JavaScript': const Color(0xFFF9A825),
    'AI/ML': const Color(0xFF7B2FBE),
  };

  final Map<String, String> _skillAppreciation = {
    'AI': 'Your understanding of artificial intelligence is remarkable!',
    'Artificial Intelligence': 'Your understanding of artificial intelligence is remarkable!',
    'Data Science': 'You have mastered the art of turning data into insights!',
    'Flutter': 'You are building the future of apps with Flutter!',
    'Cyber Security': 'You are a guardian of digital security!',
    'Cybersecurity': 'You are a guardian of digital security!',
    'English Speaking': 'Your communication skills are truly impressive!',
    'Web Development': 'You are crafting the web of tomorrow!',
    'Web': 'You are crafting the web of tomorrow!',
    'web': 'You are crafting the web of tomorrow!',
    'SQL': 'You are a master of data queries!',
    'Python': 'You are coding the future with Python!',
    'JavaScript': 'You are building interactive web experiences!',
    'AI/ML': 'Your understanding of artificial intelligence is remarkable!',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && mounted) {
        var data = userDoc.data() as Map<String, dynamic>;
        _userName = data['name'] ?? user.displayName ?? 'User';
        _completedChallenges = (data['completedChallenges'] as List?)?.length ?? 0;

        List<String> earnedCertificates = [];
        if (data['certificates'] != null) {
          if (data['certificates'] is List) {
            earnedCertificates = List<String>.from(data['certificates']);
          } else if (data['certificates'] is String) {
            if (data['certificates'].isNotEmpty) {
              earnedCertificates = [data['certificates']];
            }
          }
        }

        _certificates = earnedCertificates.map((certId) {
          String skill = certId.replaceFirst('Certificate_', '');
          return {
            'id': certId,
            'skill': skill,
            'isEarned': true,
            'earnedAt': DateTime.now(),
          };
        }).toList();
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateAndShareCertificate(
      BuildContext context,
      Map<String, dynamic> certificate,
      ) async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      String? userName = await _askUserName(context);
      if (userName == null || userName.trim().isEmpty) {
        setState(() => _isGenerating = false);
        return;
      }

      if (!mounted) {
        setState(() => _isGenerating = false);
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'Generating your certificate...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      String skillName = certificate['skill'];
      Color skillColor = _skillColors[skillName] ?? const Color(0xFF6C63FF);
      String appreciation = _skillAppreciation[skillName] ?? 'You are a true learner!';

      PdfColor primaryPdfColor = PdfColor(
        skillColor.red / 255,
        skillColor.green / 255,
        skillColor.blue / 255,
      );
      PdfColor darkTeal = PdfColor(44/255, 62/255, 80/255);
      PdfColor mintGreen = PdfColor(168/255, 230/255, 207/255);
      PdfColor gold = PdfColor(212/255, 175/255, 55/255);
      PdfColor white = PdfColors.white;
      PdfColor black = PdfColors.black;
      PdfColor grey = PdfColors.grey600;
      PdfColor lightGrey = PdfColors.grey400;

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: primaryPdfColor,
                  width: 8,
                ),
                borderRadius: pw.BorderRadius.circular(15),
              ),
              child: pw.Container(
                padding: const pw.EdgeInsets.all(40),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight,
                    colors: [
                      white,
                      PdfColor(
                        primaryPdfColor.red,
                        primaryPdfColor.green,
                        primaryPdfColor.blue,
                        0.05,
                      ),
                    ],
                  ),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    // Top Lines
                    pw.Container(
                      height: 2,
                      width: 500,
                      color: gold,
                    ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      height: 2,
                      width: 300,
                      color: primaryPdfColor,
                    ),
                    pw.SizedBox(height: 20),

                    // Logo
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 70,
                          height: 70,
                          decoration: pw.BoxDecoration(
                            gradient: pw.RadialGradient(
                              colors: [darkTeal, mintGreen],
                            ),
                            borderRadius: pw.BorderRadius.circular(35),
                            border: pw.Border.all(
                              color: gold,
                              width: 2,
                            ),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              'SC',
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: gold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 15),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Skill Challenge',
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: darkTeal,
                                letterSpacing: 2,
                              ),
                            ),
                            pw.Text(
                              'Learn & Earn',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: grey,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),

                    // Title - Color
                    pw.Text(
                      'CERTIFICATE OF COMPLETION',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryPdfColor,
                        letterSpacing: 5,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      height: 1,
                      width: 200,
                      color: primaryPdfColor,
                    ),
                    pw.SizedBox(height: 25),

                    // Presented to - Normal
                    pw.Text(
                      'This certificate is proudly presented to',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: grey,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 15),

                    // User Name - Bold
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: primaryPdfColor,
                            width: 2,
                          ),
                        ),
                      ),
                      child: pw.Text(
                        userName.trim().toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 38,
                          fontWeight: pw.FontWeight.bold,
                          color: black,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // for successfully completing the course of - Normal
                    pw.Text(
                      'for successfully completing the course of',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: grey,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 12),

                    // ✅ SKILL NAME - Simple Bold (NO BOX)
                    pw.Text(
                      skillName.toUpperCase(),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryPdfColor,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 15),

                    // ✅ APPRECIATION - Simple Text (NO BOX)
                    pw.Text(
                      '"$appreciation"',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: primaryPdfColor,
                        fontStyle: pw.FontStyle.italic,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 25),

                    // Bottom Row
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              height: 1,
                              width: 120,
                              color: grey,
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Date: ${DateTime.now().toString().split(' ')[0]}',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: grey,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Row(
                              children: [
                                pw.Text(
                                  '✓',
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    color: primaryPdfColor,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(width: 6),
                                pw.Text(
                                  'Verified',
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    color: primaryPdfColor,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Container(
                              height: 1,
                              width: 80,
                              color: primaryPdfColor,
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Authorized Signature',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: grey,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Container(
                              height: 1,
                              width: 120,
                              color: grey,
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'From Skill Challenge App',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: darkTeal,
                                fontWeight: pw.FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 15),

                    pw.Container(
                      height: 1,
                      width: 500,
                      color: lightGrey,
                    ),
                    pw.SizedBox(height: 8),

                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Certificate ID: CERT-${DateTime.now().millisecondsSinceEpoch}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: lightGrey,
                          ),
                        ),
                        pw.Text(
                          'Skill Challenge App',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: darkTeal,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();

      if (mounted) Navigator.pop(context);

      final fileName = 'Certificate_${certificate['id']}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // ✅ WEB
      if (kIsWeb) {
        await handleCertificateFile(pdfBytes, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Certificate downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        setState(() => _isGenerating = false);
        return;
      }

      // ✅ ANDROID
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        _showShareDialog(context, file, certificate, userName);
      }

      setState(() => _isGenerating = false);

    } catch (e) {
      if (mounted) Navigator.pop(context);
      setState(() => _isGenerating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _askUserName(BuildContext context) async {
    TextEditingController nameController = TextEditingController();
    nameController.text = _userName;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Enter Your Name',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your full name as you want it to appear on the certificate',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, nameController.text.trim());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your name'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Generate Certificate'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(
      BuildContext context,
      File file,
      Map<String, dynamic> certificate,
      String userName,
      ) {
    Color skillColor = _skillColors[certificate['skill']] ?? const Color(0xFF6C63FF);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        title: const Text(
          'Certificate Ready!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [skillColor, skillColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    '🎓',
                    style: TextStyle(fontSize: 50),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${certificate['skill']} Certificate',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share your certificate with others!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _shareCertificate(file);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareCertificate(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'I earned a certificate in Skill Challenge App!\n\nKeep learning and growing!\n#SkillChallenge #Learning #Certificate',
      );
    } catch (e) {
      print('Error sharing certificate: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "My Certificates",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _loading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 20),
            Text(
              'Loading certificates...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : _certificates.isEmpty
          ? _buildEmptyState()
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('🎓', '${_certificates.length}', 'Certificates'),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildStatItem('✅', '$_completedChallenges', 'Challenges'),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildStatItem('🏆', _completedChallenges >= 10 ? 'Pro' : 'Start', 'Level'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: _certificates.length,
                itemBuilder: (context, index) {
                  var cert = _certificates[index];
                  Color skillColor = _skillColors[cert['skill']] ?? Colors.deepPurple;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: skillColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: skillColor.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: skillColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '🎓',
                            style: TextStyle(fontSize: 30),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cert['skill'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '✅ Earned! Tap to share',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: skillColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.share,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: _isGenerating ? null : () {
                            _generateAndShareCertificate(context, cert);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'No Certificates Yet!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Complete challenges with 80%+ score to earn certificates',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('Go to Challenges'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}