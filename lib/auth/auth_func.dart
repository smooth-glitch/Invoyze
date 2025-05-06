import 'package:firebase_auth/firebase_auth.dart';

class AuthFunc {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print(e);
    }
  }
}
