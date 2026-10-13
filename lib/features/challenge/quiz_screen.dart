import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

// ✅ Helper import
import '../../utils/certificate_file.dart';
import '../../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  final String skillName;
  final String category;

  const QuizScreen({
    super.key,
    required this.skillName,
    required this.category,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QueryDocumentSnapshot> _questions = [];
  int currentQuestion = 0;
  int score = 0;
  int? selectedAnswer;
  bool answered = false;
  bool _loading = true;
  int _totalXP = 0;
  int _totalQuestionsCompleted = 0;
  bool _isGenerating = false;
  String _userName = '';
  String _userEmail = '';

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
    'General': const Color(0xFF607D8B),
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
    'General': 'You are a true learner!',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadQuestionsFromFirestore();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        _userName = data['name'] ?? user.displayName ?? 'User';
        _userEmail = data['email'] ?? user.email ?? '';
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadQuestionsFromFirestore() async {
    setState(() => _loading = true);

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('category', isEqualTo: widget.category)
          .get();

      List<QueryDocumentSnapshot> allQuestions = snapshot.docs.toList();
      allQuestions.shuffle(Random());

      setState(() {
        _questions = allQuestions;
        _loading = false;
      });
    } catch (e) {
      print('Error loading questions: $e');
      setState(() => _loading = false);
    }
  }

  void selectAnswer(int index) {
    if (answered) return;
    setState(() {
      selectedAnswer = index;
    });
  }

  void submitAnswer() {
    if (selectedAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select an answer first")),
      );
      return;
    }

    setState(() {
      answered = true;

      var questionData = _questions[currentQuestion].data() as Map<String, dynamic>;

      int correctAnswer;
      if (questionData['correctAnswer'] is int) {
        correctAnswer = questionData['correctAnswer'];
      } else {
        String correctText = questionData['correctAnswer'] ?? 'A';
        Map<String, int> letterToIndex = {'A': 0, 'B': 1, 'C': 2, 'D': 3};
        correctAnswer = letterToIndex[correctText] ?? 0;
      }

      if (selectedAnswer == correctAnswer) {
        score++;
        int xp = questionData['xp'] ?? 10;
        _totalXP += xp;
        _saveProgress(xp, _questions[currentQuestion].id);
      }
    });
  }

  Future<void> _saveProgress(int xpEarned, String questionId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentReference ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      DocumentSnapshot snapshot = await ref.get();

      if (snapshot.exists) {
        int oldXP = (snapshot.data() as Map<String, dynamic>)['xp'] ?? 0;
        List completed = List.from(
            (snapshot.data() as Map<String, dynamic>)['completedChallenges'] ?? []
        );

        if (!completed.contains(questionId)) {
          completed.add(questionId);
          _totalQuestionsCompleted = completed.length;

          await ref.update({
            'xp': oldXP + xpEarned,
            'level': ((oldXP + xpEarned) ~/ 50) + 1,
            'completedChallenges': completed,
          });

          await _checkBadges(user.uid, oldXP + xpEarned, completed);
        }
      }
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  Future<void> _checkBadges(String uid, int xp, List completed) async {
    try {
      List<String> currentBadges = [];
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        currentBadges = List.from(
            (userDoc.data() as Map<String, dynamic>)['badges'] ?? []
        );
      }

      List<String> newBadges = [];

      if (completed.length >= 5 && !currentBadges.contains('🥉 Bronze Learner')) {
        newBadges.add('🥉 Bronze Learner');
      }
      if (completed.length >= 10 && !currentBadges.contains('🥈 Silver Learner')) {
        newBadges.add('🥈 Silver Learner');
      }
      if (completed.length >= 20 && !currentBadges.contains('🥇 Gold Learner')) {
        newBadges.add('🥇 Gold Learner');
      }
      if (completed.length >= 30 && !currentBadges.contains('💎 Diamond Learner')) {
        newBadges.add('💎 Diamond Learner');
      }
      if (xp >= 100 && !currentBadges.contains('⭐ XP Explorer')) {
        newBadges.add('⭐ XP Explorer');
      }
      if (xp >= 250 && !currentBadges.contains('🚀 XP Master')) {
        newBadges.add('🚀 XP Master');
      }
      if (xp >= 500 && !currentBadges.contains('👑 XP Legend')) {
        newBadges.add('👑 XP Legend');
      }

      if (newBadges.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({
          'badges': FieldValue.arrayUnion(newBadges),
        });

        for (String badge in newBadges) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎖️ New Badge: $badge!'),
                backgroundColor: Colors.amber,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error checking badges: $e');
    }
  }

  Future<void> _saveCertificateForSkill() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String skillName = widget.category;
      String certId = 'Certificate_$skillName';

      DocumentReference userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      await userRef.update({
        'certificates': FieldValue.arrayUnion([certId]),
      });

      print('✅ Certificate saved: $certId');
    } catch (e) {
      print('❌ Error saving certificate: $e');
    }
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

  // ✅ PDF CERTIFICATE - SIMPLE DESIGN
  Future<void> _generateCertificatePDF(String userName) async {
    try {
      String skillName = widget.category;
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
                  width: 6,
                ),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Container(
                padding: const pw.EdgeInsets.all(40),
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
                          width: 60,
                          height: 60,
                          decoration: pw.BoxDecoration(
                            gradient: pw.RadialGradient(
                              colors: [darkTeal, mintGreen],
                            ),
                            borderRadius: pw.BorderRadius.circular(30),
                            border: pw.Border.all(
                              color: gold,
                              width: 2,
                            ),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              'SC',
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: gold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 12),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Skill Challenge',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: darkTeal,
                                letterSpacing: 2,
                              ),
                            ),
                            pw.Text(
                              'Learn & Earn',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: grey,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),

                    // Title
                    pw.Text(
                      'CERTIFICATE OF COMPLETION',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryPdfColor,
                        letterSpacing: 4,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      height: 1,
                      width: 180,
                      color: primaryPdfColor,
                    ),
                    pw.SizedBox(height: 25),

                    // Presented to
                    pw.Text(
                      'This certificate is proudly presented to',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: grey,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 15),

                    // User Name - Bold
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 10,
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
                          fontSize: 34,
                          fontWeight: pw.FontWeight.bold,
                          color: black,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // for successfully completing the course of
                    pw.Text(
                      'for successfully completing the course of',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: grey,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 10),

                    // ✅ SKILL NAME - SIRF BOLD, SIMPLE
                    pw.Text(
                      skillName,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: black,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 15),

                    // Appreciation
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColor(
                          primaryPdfColor.red,
                          primaryPdfColor.green,
                          primaryPdfColor.blue,
                          0.05,
                        ),
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(
                          color: PdfColor(
                            primaryPdfColor.red,
                            primaryPdfColor.green,
                            primaryPdfColor.blue,
                            0.2,
                          ),
                          width: 1,
                        ),
                      ),
                      child: pw.Text(
                        '"$appreciation"',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: primaryPdfColor,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 25),

                    // Bottom Row - Date + Verified + From
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              height: 1,
                              width: 100,
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
                              width: 100,
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
                            fontSize: 9,
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

      final fileName = 'Certificate_${widget.category}_${DateTime.now().millisecondsSinceEpoch}.pdf';

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
        return;
      }

      // ✅ ANDROID
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
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
                        '${widget.category} Certificate',
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
    } catch (e) {
      print('Error generating PDF: $e');
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

  Future<void> _askUserNameAndGenerate() async {
    TextEditingController nameController = TextEditingController();
    nameController.text = _userName;

    return showDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _generateCertificatePDF(nameController.text.trim());
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

  void nextQuestion() {
    if (currentQuestion < _questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        answered = false;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    double percentage = _questions.isEmpty ? 0 : (score / _questions.length) * 100;
    bool hasEarnedCertificate = percentage >= 80;

    if (hasEarnedCertificate) {
      _saveCertificateForSkill();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 70,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Challenge Completed!\n\n"
                    "Score: $score / ${_questions.length}\n"
                    "Percentage: ${percentage.toInt()}%\n"
                    "Total XP Earned: $_totalXP XP\n\n"
                    "${percentage >= 80 ? '🌟 Certificate Earned!' : '💪 Keep Practicing!'}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (percentage >= 80) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.secondaryColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🎓 ${widget.category} Certificate Earned!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _askUserNameAndGenerate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.file_download),
                    label: const Text(
                      'Generate & Share Certificate',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              if (percentage < 80) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Need ${(80 - percentage).toInt()}% more for certificate',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Back To Challenges",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          widget.skillName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_loading && _questions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$_totalXP XP',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
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
              'Loading Questions...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : _questions.isEmpty
          ? _buildEmptyState()
          : _buildQuizContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'No questions found in ${widget.skillName}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Admin needs to add questions in this category',
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
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent() {
    var questionData = _questions[currentQuestion].data() as Map<String, dynamic>;

    List<String> options;
    if (questionData.containsKey('options')) {
      options = (questionData['options'] as List<dynamic>?)?.cast<String>() ?? [];
    } else {
      options = [
        questionData['optionA'] ?? '',
        questionData['optionB'] ?? '',
        questionData['optionC'] ?? '',
        questionData['optionD'] ?? '',
      ];
    }

    int correctAnswer;
    if (questionData['correctAnswer'] is int) {
      correctAnswer = questionData['correctAnswer'];
    } else {
      String correctText = questionData['correctAnswer'] ?? 'A';
      Map<String, int> letterToIndex = {'A': 0, 'B': 1, 'C': 2, 'D': 3};
      correctAnswer = letterToIndex[correctText] ?? 0;
    }

    String questionText = questionData['question'] ?? 'No question text';
    int xp = questionData['xp'] ?? 10;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Question ${currentQuestion + 1}/${_questions.length}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+$xp XP',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (currentQuestion + 1) / _questions.length,
            minHeight: 10,
            borderRadius: BorderRadius.circular(20),
            color: AppTheme.primaryColor,
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(height: 30),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              questionText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 25),

          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                bool isCorrect = index == correctAnswer;
                bool isSelected = selectedAnswer == index;

                Color color = Colors.white;
                if (answered) {
                  if (isCorrect) {
                    color = Colors.green.shade100;
                  } else if (isSelected) {
                    color = Colors.red.shade100;
                  }
                } else if (isSelected) {
                  color = AppTheme.primaryColor;
                }

                IconData? trailingIcon;
                Color? iconColor;
                if (answered) {
                  if (isCorrect) {
                    trailingIcon = Icons.check_circle;
                    iconColor = Colors.green;
                  } else if (isSelected) {
                    trailingIcon = Icons.cancel;
                    iconColor = Colors.red;
                  }
                }

                return GestureDetector(
                  onTap: () => selectAnswer(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected && !answered
                            ? AppTheme.primaryColor
                            : Colors.grey.shade200,
                        width: isSelected && !answered ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            options[index],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isSelected && !answered
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        if (trailingIcon != null)
                          Icon(trailingIcon, color: iconColor),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: answered
                    ? AppTheme.primaryColor
                    : (selectedAnswer == null ? Colors.grey : AppTheme.primaryColor),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: answered ? nextQuestion : submitAnswer,
              child: Text(
                answered
                    ? (currentQuestion == _questions.length - 1
                    ? "🏆 Finish"
                    : "Next Question →")
                    : "Submit Answer",
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}