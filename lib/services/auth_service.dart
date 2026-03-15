import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> registerDonor({
    required String email, required String password, required String name,
    required String phone, required String bloodType,
    required int age, required String gender,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final fcmToken = await _fcm.getToken();
    final user = UserModel(
      uid: cred.user!.uid, name: name, email: email, phone: phone,
      bloodType: bloodType, age: age, gender: gender,
      role: 'donor', fcmToken: fcmToken, createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(cred.user!.uid).set(user.toMap());
    await _db.collection('eligibility').doc(cred.user!.uid).set({
      'donorId': cred.user!.uid, 'lastDonationDate': null,
      'nextEligibleDate': null, 'lastHealthStatus': 'healthy',
      'isPermanentlyIneligible': false,
    });
    return user;
  }

  Future<UserModel> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final fcmToken = await _fcm.getToken();
    await _db.collection('users').doc(cred.user!.uid).update({'fcmToken': fcmToken});
    final doc = await _db.collection('users').doc(cred.user!.uid).get();
    return UserModel.fromFirestore(doc);
  }

  Future<UserModel> loginAdmin(String email, String password) async {
    final user = await login(email, password);
    if (user.role != 'admin') {
      await _auth.signOut();
      throw Exception('Access denied. Admin account required.');
    }
    return user;
  }

  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> logout() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).update({'fcmToken': null});
    }
    await _auth.signOut();
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
