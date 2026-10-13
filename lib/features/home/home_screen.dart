import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import '../challenge/challenge_screen.dart';
import '../certificates/certificates_screen.dart';
import '../ progress/progress_screen.dart';
import '../ leaderboard/leaderboard_screen.dart';
import '../auth/login_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _xp = 0;
  int _level = 1;
  int _certificateCount = 0;
  int _completedChallenges = 0;
  bool _loading = true;
  String _userName = 'User';
  List<String> _skills = [];
  List<String> _filteredSkills = [];
  TextEditingController _searchController = TextEditingController();
  bool _noSkillFound = false;
  int _currentIndex = 0;

  static const List<String> adminEmails = [
    'snobarakhtar25@gmail.com',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSkills();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _userName = 'Guest';
          });
        }
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && mounted) {
        var data = userDoc.data() as Map<String, dynamic>;
        _userName = data['name'] ?? user.displayName ?? 'User';
        _xp = data['xp'] ?? 0;
        _level = data['level'] ?? 1;
        _certificateCount = (data['certificates'] as List?)?.length ?? 0;
        _completedChallenges = (data['completedChallenges'] as List?)?.length ?? 0;
      }

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ✅ SKILLS LOAD - General Skip + Trim
  Future<void> _loadSkills() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('questions')
          .get();

      Set<String> uniqueSkills = {};
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('category')) {
          String category = data['category'] ?? '';
          String trimmedCategory = category.trim(); // ✅ Trim karein

          if (trimmedCategory.isNotEmpty) {
            // ✅ Skip Beginner/Intermediate/Advanced/General
            if (trimmedCategory != 'Beginner' &&
                trimmedCategory != 'Intermediate' &&
                trimmedCategory != 'Advanced' &&
                trimmedCategory != 'General') {
              uniqueSkills.add(trimmedCategory);
            }
          }
        }
      }

      print('📚 Skills loaded: $uniqueSkills');

      if (mounted) {
        setState(() {
          _skills = uniqueSkills.toList();
          _filteredSkills = uniqueSkills.toList();
          _noSkillFound = false;
        });
      }
    } catch (e) {
      print('Error loading skills: $e');
      if (mounted) {
        setState(() {
          _skills = [];
          _filteredSkills = [];
          _noSkillFound = false;
        });
      }
    }
  }

  // ✅ SEARCH SKILLS
  void _searchSkills(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSkills = _skills;
        _noSkillFound = false;
      } else {
        String lowerQuery = query.toLowerCase().trim();
        _filteredSkills = _skills.where((skill) {
          return skill.toLowerCase().contains(lowerQuery);
        }).toList();
        _noSkillFound = _filteredSkills.isEmpty;
        print('🔍 Searching: "$query" → Found: ${_filteredSkills.length}');
      }
    });
  }

  void _resetSearch() {
    setState(() {
      _searchController.clear();
      _filteredSkills = _skills;
      _noSkillFound = false;
    });
  }

  bool _isLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  void _goToChallenge(String? skill) {
    if (!_isLoggedIn()) {
      _showLoginRequiredDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeScreen(initialSkill: skill),
      ),
    ).then((_) {
      _loadUserData();
      _loadSkills();
    });
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('🔒 Login Required'),
        content: const Text(
          'You need to login first to access challenges and earn certificates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Skill Challenge',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (user == null)
            IconButton(
              icon: const Icon(Icons.login),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) setState(() {});
              },
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadUserData();
              _loadSkills();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor,
        ),
      )
          : _currentIndex == 0
          ? _buildHomeContent()
          : _currentIndex == 1
          ? const CertificatesScreen()
          : const LeaderboardScreen(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Certificates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadUserData();
        await _loadSkills();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hello 👋",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$_userName! Ready for today's challenge?",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        "$_xp XP",
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
            const SizedBox(height: 20),

            // ✅ SEARCH BAR
            TextField(
              controller: _searchController,
              onChanged: _searchSkills,
              decoration: InputDecoration(
                hintText: "Search skills...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _resetSearch,
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 25),

            // ✅ DAILY CHALLENGE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🔥 Daily Challenge",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Complete 3 skills today to earn XP",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _goToChallenge(null),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text(
                        "Start Challenge",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // ✅ STATS
            const Text(
              "Your Stats",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProgressScreen(),
                        ),
                      );
                    },
                    child: _buildStat("Level", "$_level", Icons.emoji_events),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProgressScreen(),
                        ),
                      );
                    },
                    child: _buildStat("XP", "$_xp", Icons.star),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CertificatesScreen(),
                        ),
                      );
                    },
                    child: _buildStat("Certificates", "$_certificateCount", Icons.verified),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // ✅ RECOMMENDED
            const Text(
              "Recommended Skills",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildRecommendedCard(
                    'Flutter',
                    Icons.phone_android,
                    Colors.blue,
                        () => _goToChallenge('Flutter'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRecommendedCard(
                    'Data Science',
                    Icons.analytics,
                    Colors.deepPurple,
                        () => _goToChallenge('Data Science'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRecommendedCard(
                    'Cyber Security',
                    Icons.security,
                    Colors.red,
                        () => _goToChallenge('Cyber Security'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // ✅ ALL SKILLS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchController.text.isEmpty ? "All Skills" : "Search Results",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  TextButton(
                    onPressed: _resetSearch,
                    child: const Text('Show All'),
                  ),
              ],
            ),
            const SizedBox(height: 15),

            if (_skills.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Text(
                    'No skills available yet.\nAdmin needs to add questions!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else if (_noSkillFound)
              Container(
                padding: const EdgeInsets.all(30),
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
                    Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No Skill Found!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try searching with different keywords',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _resetSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Show All Skills'),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _filteredSkills.map((skill) {
                  return GestureDetector(
                    onTap: () => _goToChallenge(skill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.code, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            skill,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Level $_level • $_xp XP',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                }
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Skill Challenge v1.0',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildStat(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}