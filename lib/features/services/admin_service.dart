import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;

    if (user == null) {
      print('❌ No user logged in');
      return false;
    }

    print('📧 EMAIL: ${user.email}');
    print('🆔 UID: ${user.uid}');

    try {

      final adminDoc = await _firestore
          .collection('admin')
          .doc(user.uid)
          .get();

      print(' ADMIN FOUND BY UID: ${adminDoc.exists}');

      if (adminDoc.exists) {
        print(' Admin document data: ${adminDoc.data()}');
        return true;
      }


      final emailQuery = await _firestore
          .collection('admin')
          .where('email', isEqualTo: user.email)
          .get();

      print(' ADMIN FOUND BY EMAIL: ${emailQuery.docs.isNotEmpty}');

      if (emailQuery.docs.isNotEmpty) {
        print(' Admin found by email!');
        return true;
      }

      return false;
    } catch (e) {
      print(' Error checking admin: $e');
      return false;
    }
  }

  // Method to add a user as admin
  Future<void> addAdmin(String uid, String email) async {
    try {
      await _firestore.collection('admin').doc(uid).set({
        'email': email,
        'uid': uid,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print(' User $uid added as admin');
    } catch (e) {
      print(' Error adding admin: $e');
    }
  }

  // Method to remove admin status
  Future<void> removeAdmin(String uid) async {
    try {
      await _firestore.collection('admin').doc(uid).delete();
      print('✅ User $uid removed as admin');
    } catch (e) {
      print('❌ Error removing admin: $e');
    }
  }

  // Method to check if user is admin (for debugging)
  Future<void> checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No user logged in');
      return;
    }

    try {
      final doc = await _firestore.collection('admin').doc(user.uid).get();
      print('📄 Document exists: ${doc.exists}');
      if (doc.exists) {
        print('📄 Document data: ${doc.data()}');
      }
    } catch (e) {
      print('❌ Error checking admin status: $e');
    }
  }
}