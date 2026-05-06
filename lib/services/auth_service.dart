import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// USER Registration
  Future<UserModel?> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      final userModel = UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        role: 'user',
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());
      return userModel;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('An account with this email already exists.');
        case 'weak-password':
          throw Exception('Password is too weak. Use at least 6 characters.');
        case 'invalid-email':
          throw Exception('Invalid email address.');
        default:
          throw Exception(e.message ?? 'Registration failed.');
      }
    }
  }

  /// USER Login
  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      if (!doc.exists) throw Exception('User account not found.');
      final userModel = UserModel.fromMap(doc.data()!);
      if (userModel.role == 'admin') {
        await _auth.signOut();
        throw Exception('This is an admin account. Please use Admin Login.');
      }
      return userModel;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email.');
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('Incorrect password. Please try again.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        case 'too-many-requests':
          throw Exception('Too many attempts. Please try again later.');
        default:
          throw Exception(e.message ?? 'Login failed.');
      }
    }
  }

  /// ADMIN Login
  Future<UserModel?> loginAdmin({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final doc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      if (!doc.exists) throw Exception('Admin account not found.');
      final userModel = UserModel.fromMap(doc.data()!);
      if (userModel.role != 'admin') {
        await _auth.signOut();
        throw Exception('Not an admin account. Please use User Login.');
      }
      return userModel;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Admin account not found.');
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('Incorrect admin credentials.');
        default:
          throw Exception(e.message ?? 'Admin login failed.');
      }
    }
  }

  /// Logout (works for both roles)
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Get current user role from Firestore
  Future<String?> getCurrentUserRole() async {
    if (_auth.currentUser == null) return null;
    final doc = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();
    return doc.data()?['role'];
  }

  /// Get current UserModel
  Future<UserModel?> getCurrentUserModel() async {
    if (_auth.currentUser == null) return null;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }
}
