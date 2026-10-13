import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ AppTheme Import
import '../../theme/app_theme.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _level = 1;
  int _xp = 0;
  int _nextLevelXp = 50;
  int _completedChallenges = 0;
  int _certificateCount = 0;
  String _userName = 'User';
  bool _loading = true;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        _userName = data['name'] ?? user.displayName ?? 'User';
        _xp = data['xp'] ?? 0;
        _level = data['level'] ?? 1;

        if (data['completedChallenges'] is List) {
          _completedChallenges = (data['completedChallenges'] as List).length;
        } else {
          _completedChallenges = 0;
        }

        List<String> certificates = [];
        if (data['certificates'] is List) {
          certificates = List<String>.from(data['certificates']);
        }
        _certificateCount = certificates.length;

        _nextLevelXp = _level * 50;
      }

      QuerySnapshot categoriesSnapshot = await FirebaseFirestore.instance
          .collection('questions')
          .get();

      Set<String> uniqueCategories = {};
      for (var doc in categoriesSnapshot.docs) {
        String category = doc['category'] ?? 'General';
        if (category != 'Beginner' && category != 'Intermediate' && category != 'Advanced') {
          uniqueCategories.add(category);
        }
      }
      _categories = uniqueCategories.toList();

      setState(() => _loading = false);
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = _nextLevelXp > 0 ? _xp / _nextLevelXp : 0;
    if (progress > 1) progress = 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text("📊 My Progress"),
        centerTitle: true,
        foregroundColor: Colors.white,
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
              'Loading progress...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, $_userName! 👋",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Here's your learning progress",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Level $_level",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$_xp XP",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "${_xp} / $_nextLevelXp XP",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white30,
                      color: Colors.white,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${(progress * 100).toInt()}% to Level ${_level + 1}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: _buildStat(
                      "📚",
                      "$_completedChallenges",
                      "Completed",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStat(
                      "🎓",
                      "$_certificateCount",
                      "Certificates",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStat(
                      "📖",
                      "${_categories.length}",
                      "Skills",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _completedChallenges >= 10
                                ? "🌟 You're doing amazing!"
                                : _completedChallenges >= 5
                                ? "💪 Keep going! You're doing great!"
                                : "🚀 Start your journey today!",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _completedChallenges >= 10
                                ? "You've completed $_completedChallenges challenges! 🎉"
                                : "${10 - _completedChallenges} more challenges to your first milestone!",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Next Milestone (Certificate Progress)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "🎯 Your Certificates",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildMilestoneItem(
                      "🌱 Beginner Certificate",
                      _completedChallenges >= 10,
                      "10 challenges",
                      _completedChallenges,
                      10,
                    ),
                    _buildMilestoneItem(
                      "🚀 Intermediate Certificate",
                      _completedChallenges >= 25,
                      "25 challenges",
                      _completedChallenges,
                      25,
                    ),
                    _buildMilestoneItem(
                      "👑 Advanced Certificate",
                      _completedChallenges >= 50,
                      "50 challenges",
                      _completedChallenges,
                      50,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(
      String title,
      bool isComplete,
      String requirement,
      int current,
      int required,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isComplete ? AppTheme.secondaryColor.withOpacity(0.2) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? AppTheme.secondaryColor : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.lock_outline,
            color: isComplete ? AppTheme.secondaryColor : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isComplete ? AppTheme.secondaryColor : Colors.grey.shade700,
                  ),
                ),
                Text(
                  isComplete ? '✅ Earned!' : '📌 $requirement',
                  style: TextStyle(
                    fontSize: 12,
                    color: isComplete ? AppTheme.secondaryColor : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (!isComplete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$current/$required',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}