import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ AppTheme Import
import '../../theme/app_theme.dart';
import 'quiz_screen.dart';

class ChallengeScreen extends StatefulWidget {
  final String? initialSkill;

  const ChallengeScreen({super.key, this.initialSkill});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  Map<String, int> _categoryCounts = {};
  List<String> _categories = [];
  bool _loading = true;
  List<String> _completedIds = [];
  String _errorMessage = '';

  // ✅ COMPLETE ICONS MAP
  final Map<String, IconData> _categoryIcons = {
    'AI': Icons.psychology,
    'Artificial Intelligence': Icons.psychology,
    'Data Science': Icons.analytics,
    'Flutter': Icons.phone_android,
    'SQL': Icons.storage,
    'Python': Icons.code,
    'JavaScript': Icons.javascript,
    'Cyber Security': Icons.security,
    'Cybersecurity': Icons.security,
    'English Speaking': Icons.mic,
    'Web Development': Icons.web,
    'Web development': Icons.web,
    'Web': Icons.web,
    'web': Icons.web,
    'AI/ML': Icons.psychology,
  };

  // ✅ COMPLETE COLORS MAP
  final Map<String, Color> _categoryColors = {
    'AI': AppTheme.primaryColor,
    'Artificial Intelligence': AppTheme.primaryColor,
    'Data Science': AppTheme.primaryColor,
    'Flutter': AppTheme.primaryColor,
    'SQL': AppTheme.primaryColor,
    'Python': AppTheme.primaryColor,
    'JavaScript': AppTheme.primaryColor,
    'Cyber Security': AppTheme.primaryColor,
    'Cybersecurity': AppTheme.primaryColor,
    'English Speaking': AppTheme.primaryColor,
    'Web Development': AppTheme.primaryColor,
    'Web development': AppTheme.primaryColor,
    'Web': AppTheme.primaryColor,
    'web': AppTheme.primaryColor,
    'AI/ML': AppTheme.primaryColor,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      print('📢 Fetching questions from Firestore...');

      QuerySnapshot questionsSnapshot = await FirebaseFirestore.instance
          .collection('questions')
          .get();

      print('📢 Total questions found: ${questionsSnapshot.docs.length}');

      if (questionsSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _loading = false;
            _errorMessage = 'No questions found. Please add questions from Admin panel.';
          });
        }
        return;
      }

      Map<String, int> tempCounts = {};
      for (var doc in questionsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        String category = data['category'] ?? 'General';
        if (category.trim().isEmpty) {
          category = 'General';
        }

        // ✅ Skip Beginner/Intermediate/Advanced
        if (category != 'Beginner' && category != 'Intermediate' && category != 'Advanced') {
          tempCounts[category] = (tempCounts[category] ?? 0) + 1;
          print('📢 Category: $category');
        }
      }

      print('📢 Categories found: ${tempCounts.keys.join(', ')}');

      List<String> sortedCategories = tempCounts.keys.toList();
      sortedCategories.sort();

      // ✅ Filter by initialSkill if provided
      if (widget.initialSkill != null && widget.initialSkill!.isNotEmpty) {
        String skill = widget.initialSkill!;
        if (skill == 'Cyber Security') {
          sortedCategories = sortedCategories
              .where((category) => category == 'Cyber Security' || category == 'Cybersecurity')
              .toList();
        } else {
          sortedCategories = sortedCategories
              .where((category) => category == skill)
              .toList();
        }
        print('📢 Filtered categories: $sortedCategories');
      }

      User? user = FirebaseAuth.instance.currentUser;
      List<String> completed = [];
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          completed = List<String>.from(
              (userDoc.data() as Map<String, dynamic>)['completedChallenges'] ?? []
          );
          print('📢 Completed challenges: ${completed.length}');
        }
      }

      if (mounted) {
        setState(() {
          _categoryCounts = tempCounts;
          _categories = sortedCategories;
          _completedIds = completed;
          _loading = false;
          _errorMessage = '';
        });
      }
    } catch (e) {
      print('❌ Error loading categories: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Error loading questions: $e';
        });
      }
    }
  }

  Future<int> _getCompletedCountForCategory(String category) async {
    try {
      QuerySnapshot questionsSnapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('category', isEqualTo: category)
          .get();

      int completed = 0;
      for (var doc in questionsSnapshot.docs) {
        if (_completedIds.contains(doc.id)) {
          completed++;
        }
      }
      return completed;
    } catch (e) {
      return 0;
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
        title: const Text(
          "Choose Challenge",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : _categories.isEmpty
          ? _buildEmptyState()
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select a Skill 🚀",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "Complete challenges and earn XP",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_categories.length} Skills',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.9,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  String category = _categories[index];
                  int count = _categoryCounts[category] ?? 0;

                  return FutureBuilder<int>(
                    future: _getCompletedCountForCategory(category),
                    builder: (context, snapshot) {
                      int completed = snapshot.data ?? 0;
                      return _skillCard(
                        context,
                        category,
                        _categoryIcons[category] ?? Icons.quiz,
                        _categoryColors[category] ?? AppTheme.primaryColor,
                        count,
                        completed,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
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
            'No Questions Available!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Admin needs to add questions first',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _skillCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      int totalQuestions,
      int completedQuestions,
      ) {
    bool isComplete = totalQuestions > 0 && completedQuestions == totalQuestions;
    double progress = totalQuestions > 0
        ? completedQuestions / totalQuestions
        : 0;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (totalQuestions > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizScreen(  // ✅ AB YEH KAAM KAREGA
                skillName: title,
                category: title,
              ),
            ),
          ).then((_) {
            if (mounted) {
              _loadData();
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📚 No questions available in "$title" yet.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isComplete
              ? Border.all(color: AppTheme.secondaryColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(
                    icon,
                    color: color,
                    size: 35,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.quiz,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$totalQuestions Questions',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (totalQuestions > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          color: isComplete ? AppTheme.secondaryColor : color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isComplete
                        ? '✅ Completed!'
                        : '$completedQuestions/$totalQuestions Done',
                    style: TextStyle(
                      fontSize: 10,
                      color: isComplete ? AppTheme.secondaryColor : Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            if (isComplete)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}