import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ WEB KE LIYE GOOGLE SIGN-IN WITH CLIENT ID
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '562492507504-nmpfss10179ou6eai5pe79afucljmo90.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // ✅ AUTO-LOGIN KE LIYE
  AuthService() {
    // ✅ LOCAL persistence set karein - User login rahega
    _auth.setPersistence(Persistence.LOCAL);
  }

  static const List<String> adminEmails = [
    'snobarakhtar25@gmail.com',
  ];

  // ✅ CREATE OR UPDATE USER DOCUMENT
  Future<void> createUserDocument(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      String role = 'user';
      if (adminEmails.contains(user.email)) {
        role = 'admin';
      }

      await userDoc.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'name': user.displayName ?? 'User',
        'photo': user.photoURL ?? '',
        'role': role,
        'xp': 0,
        'level': 1,
        'badges': [],
        'certificates': [],
        'completedChallenges': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // ✅ UPDATE ROLE AGAR ADMIN LIST MEIN HO
      Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
      if (data != null && adminEmails.contains(user.email) && data['role'] != 'admin') {
        await userDoc.update({'role': 'admin'});
      }
    }
  }

  // ✅ EMAIL/PASSWORD SIGN UP
  Future<User?> signUp(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await createUserDocument(result.user!);
      }

      return result.user;
    } catch (e) {
      print('SignUp Error: $e');
      return null;
    }
  }

  // ✅ EMAIL/PASSWORD LOGIN
  Future<User?> login(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await createUserDocument(result.user!);
      }

      return result.user;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  // ✅ GOOGLE SIGN-IN (WEB + MOBILE COMPATIBLE)
  Future<User?> signInWithGoogle() async {
    try {
      // ✅ Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        return null;
      }

      // ✅ Get Authentication Details
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // ✅ Create Firebase Credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ✅ Sign in to Firebase
      final UserCredential result = await _auth.signInWithCredential(credential);

      if (result.user != null) {
        await createUserDocument(result.user!);
      }

      return result.user;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  // ✅ CHECK ADMIN STATUS
  Future<bool> isAdmin(User? user) async {
    if (user == null) return false;

    try {
      // 🔍 FIRST CHECK: Static admin emails list
      if (adminEmails.contains(user.email)) {
        return true;
      }

      // 🔍 SECOND CHECK: Firestore database
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['role'] == 'admin') {
          return true;
        }
      }
    } catch (e) {
      print('Error checking admin role: $e');
    }

    return false;
  }

  // ✅ GET USER ROLE FROM FIRESTORE
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        return data['role'] as String?;
      }
    } catch (e) {
      print('Error getting user role: $e');
    }
    return null;
  }

  // ✅ SIGN OUT
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('SignOut Error: $e');
    }
  }

  // ✅ GET CURRENT USER
  User? get currentUser => _auth.currentUser;

  // ✅ GET USER DATA FROM FIRESTORE
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
    return null;
  }

  // ✅ UPDATE USER XP
  Future<void> updateUserXP(String uid, int xp) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'xp': FieldValue.increment(xp),
      });
    } catch (e) {
      print('Error updating XP: $e');
    }
  }

  // ✅ COMPLETE CHALLENGE
  Future<void> completeChallenge(String uid, String challengeId) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'completedChallenges': FieldValue.arrayUnion([challengeId]),
      });
    } catch (e) {
      print('Error completing challenge: $e');
    }
  }
}