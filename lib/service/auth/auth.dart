import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mendapatkan userID dari pengguna yang sudah login
  static String? getCurrentUserID() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Mendaftarkan pengguna baru menggunakan email, password, dan nama dengan verifikasi email
  static Future<User?> registerWithEmail(
      String name, String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      // Simpan data pengguna ke Firestore
      if (user != null) {
        await _firestore.collection('Users').doc(user.uid).set({
          'userID': user.uid,
          'name': name,
          'email': user.email,
          'createdAt':
              FieldValue.serverTimestamp(), // Menyimpan waktu pendaftaran
        });

        // Mengirim email verifikasi
        await user.sendEmailVerification();

        return user;
      }
      return null;
    } catch (e) {
      logger.e('Error registering with email & password: $e');
      return null;
    }
  }

  // Mengecek apakah email sudah diverifikasi
  static Future<bool> isEmailVerified() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload(); // Reload untuk mendapatkan status terbaru
      return user.emailVerified;
    }
    return false;
  }

  // Kirim ulang email verifikasi
  static Future<void> sendVerificationEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Login menggunakan email dan password
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      logger.e('Error signing in with email & password: $e');
      return null;
    }
  }

  // Mengirimkan email untuk reset password
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      logger.e('Error sending password reset email: $e');
    }
  }

  // Logout dari akun
  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  // Fungsi untuk menghapus akun pengguna
  static Future<bool> deleteUser() async {
    User? user =
        FirebaseAuth.instance.currentUser; // Ambil pengguna yang sedang login
    if (user != null) {
      try {
        // Hapus data pengguna dari Firestore
        await _firestore.collection('Users').doc(user.uid).delete();

        // Hapus pengguna dari Firebase Auth
        await user.delete();

        return true; // Penghapusan berhasil
      } catch (e) {
        logger.e('Error deleting user: $e');
        return false; // Terjadi kesalahan saat menghapus
      }
    }
    return false; // Tidak ada pengguna yang sedang login
  }
}
