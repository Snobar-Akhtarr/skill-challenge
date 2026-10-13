import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ AppTheme Import
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../certificates/certificates_screen.dart';
import '../ progress/progress_screen.dart';  // ✅ FIXED - space remove
import '../ leaderboard/leaderboard_screen.dart';  // ✅ FIXED - space remove

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isAdmin = false;
  bool checkingAdmin = true;
  String adminError = '';
  String _userName = '';
  int _xp = 0;
  int _level = 1;
  int _certificateCount = 0;
  int _completedChallenges = 0;

  // ✅ Admin UID list
  static const List<String> adminUids = [
    '7gm1UTDzwEbqCfItHjpZtBW3zap2',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => checkingAdmin = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => checkingAdmin = false);
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

        List<String> certificates = List<String>.from(data['certificates'] ?? []);
        _certificateCount = certificates.length;

        List<String> completed = List<String>.from(data['completedChallenges'] ?? []);
        _completedChallenges = completed.length;

        isAdmin = adminUids.contains(user.uid);
        print('👤 User UID: ${user.uid}');
        print('✅ Is Admin: $isAdmin');
      }

      setState(() => checkingAdmin = false);
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        checkingAdmin = false;
        adminError = e.toString();
      });
    }
  }

  Future<void> refreshData() async {
    await _loadUserData();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String username = _userName.isNotEmpty ? _userName : (user?.email?.split('@')[0] ?? 'User');
    final String email = user?.email ?? 'No email';

    int nextLevelXp = _level * 50;
    double progress = nextLevelXp > 0 ? _xp / nextLevelXp : 0;
    if (progress > 1) progress = 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '👤 Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: refreshData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              email,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 25),

            // Level Card
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
                children: [
                  Text(
                    'Level $_level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white30,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$_xp / $nextLevelXp XP',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('🎓', '$_certificateCount', 'Certificates'),
                ),
                Expanded(
                  child: _buildStatCard('✅', '$_completedChallenges', 'Completed'),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // ✅ My Certificates
            _buildTile(
              Icons.emoji_events,
              'My Certificates',
              'View earned certificates',
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CertificatesScreen(),
                  ),
                );
              },
            ),

            // ✅ My Progress
            _buildTile(
              Icons.bar_chart,
              'My Progress',
              'Track your learning',
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProgressScreen(),
                  ),
                );
              },
            ),

            // ✅ Leaderboard
            _buildTile(
              Icons.leaderboard,
              'Leaderboard',
              'See your ranking',
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LeaderboardScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // ✅ Admin Status
            if (checkingAdmin)
              const Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Checking admin status...'),
                  ],
                ),
              ),

            if (!checkingAdmin) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isAdmin ? AppTheme.secondaryColor.withOpacity(0.2) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAdmin ? AppTheme.secondaryColor : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAdmin ? Icons.check_circle : Icons.person,
                      color: isAdmin ? AppTheme.secondaryColor : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isAdmin ? '✅ Admin Access' : '👤 User Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? AppTheme.secondaryColor : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ Admin Panel Button (Sirf Admin ko dikhe)
              if (isAdmin) ...[
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 2,
                    ),
                  ),
                  child: _buildTile(
                    Icons.admin_panel_settings,
                    'Admin Panel',
                    'Manage app data',
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],

            if (adminError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(15),
                child: Text(
                  'Error: $adminError',
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 20),

            // Logout Button
            _buildTile(
              Icons.logout,
              'Logout',
              'Sign out from app',
              _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(15),
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
          Text(
            emoji,
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
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

  Widget _buildTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}