import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();

  factory UserSession() {
    return _instance;
  }

  UserSession._internal();

  String? userID;

  // Simpan userID ke SharedPreferences
  Future<void> saveUserID(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userID', id);
    userID = id;
  }

  // Ambil userID dari SharedPreferences dan kembalikan hasilnya
  Future<bool> loadUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userID = prefs.getString('userID');
    return userID != null; // Kembalikan true jika userID tidak null
  }

  // Hapus userID dari SharedPreferences
  Future<void> clearUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userID');
    userID = null;
  }

  // Cek apakah userID ada
  bool hasUserID() {
    return userID != null;
  }
}
