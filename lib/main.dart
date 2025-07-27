import 'package:exbo_appmobile/pages/onboard/onboard_screen.dart';
import 'package:exbo_appmobile/pages/bottom_nav/bottomnav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'shared_preferences/providers_cek_recomend.dart';
import 'shared_preferences/user_location_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => RecommendationProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              UserLocationProvider(), // Tambahkan provider untuk lokasi
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          scaffoldBackgroundColor:
              Colors.white, // Background putih untuk seluruh aplikasi
        ),
        home:
            const SessionChecker(), // Cek session saat pertama kali membuka aplikasi
      ),
    );
  }
}

// Kelas UserSession untuk menyimpan dan mengambil userID dari SharedPreferences
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

  // Ambil userID dari SharedPreferences
  Future<void> loadUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userID = prefs.getString('userID');
  }

  // Hapus userID dari SharedPreferences
  Future<void> clearUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userID');
    userID = null;
  }
}

class SessionChecker extends StatefulWidget {
  const SessionChecker({super.key});

  @override
  State<SessionChecker> createState() => _SessionCheckerState();
}

class _SessionCheckerState extends State<SessionChecker> {
  @override
  void initState() {
    super.initState();
    checkUserSession(); // Panggil fungsi untuk cek session
  }

  void checkUserSession() async {
    await UserSession().loadUserID(); // Ambil userID dari SharedPreferences
    String? userID = UserSession().userID;

    if (!mounted) return; // Cek jika widget masih terpasang
    if (userID != null) {
      // Jika userID ditemukan, arahkan ke halaman BottomNav
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNav()),
      );
    } else {
      // Jika tidak ada userID, arahkan ke halaman login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Onboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ), // Tampilkan loading sementara
    );
  }
}
