import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exbo_appmobile/pages/home/content_home/main_content.dart';
import 'package:exbo_appmobile/widget/widget_handler_back.dart';
import 'package:exbo_appmobile/widget/widget_support.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../../shared_preferences/user_location_providers.dart';
import '../onboard/onboard_screen.dart';
import '../../shared_preferences/user_session.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _isLoading = true;
  String? _userName;
  var logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadUserID();
    _loadUserLocation(); // Memanggil fungsi untuk memuat lokasi pengguna
  }

  Future<void> _loadUserID() async {
    await UserSession().loadUserID();
    String? userID = UserSession().userID;

    if (!mounted) return; // Cek jika widget masih terpasang
    if (userID == null) {
      // Arahkan ke halaman login jika userID null
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Onboard()),
      );
    } else {
      // Jika userID tidak null, ambil nama pengguna dan periksa rekomendasi
      await _getUserName(userID);
      if (mounted) {
        setState(() {
          _isLoading = false; // Set loading ke false setelah data diambil
        });
      }
    }
  }

  Future<void> _loadUserLocation() async {
    await Provider.of<UserLocationProvider>(context, listen: false)
        .updateUserLocation();
  }

  Future<void> _getUserName(String userID) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userID)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'];
        });
      }
    } catch (e) {
      logger.e('Error fetching user name: $e');
    }
  }

  // fungsi untuk kapitalise pada text
  String capitalizeWords(String str) {
    return str
        .split(' ')
        .where((word) => word.isNotEmpty) // filter out empty words
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return BackPressHandler(
      child: Scaffold(
        body: _isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(), // Tampilkan loading indicator saat proses berlangsung
              )
            : SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.only(top: 50.0, left: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    capitalizeWords(
                                        "Hii ${_userName ?? 'User'}"),
                                    style: AppWidget.boldTextFeildStyle()),
                                Text("Ayo! Explore Wisata Bogor disini!",
                                    style: AppWidget.semiLightTextFeildStyle()),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      const Contents(), // Widget untuk menampilkan data dari Firestore
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
