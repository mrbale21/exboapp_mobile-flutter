import 'package:d_info/d_info.dart';
import 'package:exbo_appmobile/pages/home/main_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../../service/hybrid/hybrid_service.dart';
import '../../shared_preferences/providers_cek_recomend.dart';
import '../../shared_preferences/user_location_providers.dart';
import '../../shared_preferences/user_session.dart';
import '../hybrid/hybrid_screen.dart';
import '../location/location_screen.dart';
import '../profile/profile_screen.dart';

var logger = Logger();

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  User? user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  // Daftar halaman yang akan ditampilkan pada setiap tab
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const Home(),
      const LocationPage(), // Placeholder untuk halaman lokasi
      const ProfileScreen(), // Berikan argumen user yang sesuai
    ];
    _checkRecommendations();
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // Jika mengklik ikon lokasi, ambil lokasi
      _getCurrentLocation();
    } else {
      // Jika tidak, cukup ubah halaman
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _checkRecommendations() async {
    String? userID = UserSession().userID;

    if (userID == null) return; // Pastikan userID tidak null

    try {
      final userLocationProvider =
          Provider.of<UserLocationProvider>(context, listen: false);
      final userLocation = userLocationProvider.userLocation;

      if (userLocation != null) {
        List<Map<String, dynamic>> recommendations =
            await getHybridRecommendation(
                userID, userLocation.latitude, userLocation.longitude);
        if (mounted) {
          Provider.of<RecommendationProvider>(context, listen: false)
              .setRecommendations(recommendations.isNotEmpty);
        }
      }
    } catch (e) {
      logger.e('Error checking recommendations: $e');
    }
  }

  void _onRecommendationButtonClick() {
    Provider.of<RecommendationProvider>(context, listen: false)
        .markAsSeen(); // Tandai rekomendasi telah dilihat

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HybridRecomendScreen()),
    ).then((_) {
      setState(() {
        _checkRecommendations(); // Panggil untuk memeriksa rekomendasi
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      // Jika izin ditolak, tampilkan pesan
      if (!mounted) return; // Cek jika widget masih terpasang
      DInfo.dialogError(context, "Location permission denied");
      DInfo.closeDialog(context);

      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    Position position =
        await Geolocator.getCurrentPosition(locationSettings: locationSettings);

    if (!mounted) return; // Cek jika widget masih terpasang
    // Navigasi ke halaman rekomendasi dengan koordinat yang didapat
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LocationReccomndScreen(
            latitude: position.latitude, longitude: position.longitude),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendationProvider = Provider.of<RecommendationProvider>(context);
    return Scaffold(
      // Tampilkan halaman sesuai index yang dipilih
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 1,
              spreadRadius: 0,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: BottomAppBar(
          height: 60,
          elevation: 0.0,
          color: const Color.fromRGBO(47, 143, 157, 100),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: Container(
              height: 60,
              color: Colors.transparent,
              child: Row(
                children: [
                  navItem(
                    Icons.home,
                    _selectedIndex == 0,
                    onTap: () => _onItemTapped(0),
                  ),
                  const SizedBox(width: 100), // Spacer untuk tombol tengah

                  navItem(
                    Icons.person,
                    _selectedIndex == 2, // Ubah menjadi 2 untuk profil
                    onTap: () => _onItemTapped(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 25),
        height: 64,
        width: 64,
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          elevation: 0,
          onPressed: () => _checkRecommendations(), // Fungsi langsung dipanggil
          shape: RoundedRectangleBorder(
            side: const BorderSide(
                width: 3, color: Color.fromRGBO(47, 143, 157, 100)),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: _onRecommendationButtonClick,
                icon: const Icon(
                  Icons.recommend,
                  size: 40,
                  color: Color.fromRGBO(47, 143, 157, 100),
                ),
              ),
              if (recommendationProvider.hasRecommendations &&
                  !recommendationProvider.hasSeenRecommendations)
                Positioned(
                  top: 3,
                  right: 13,
                  child: Container(
                    padding: const EdgeInsets.all(1.0),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '!',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget navItem(IconData icon, bool selected, {Function()? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: const Color.fromRGBO(47, 142, 157, 0),
        child: selected
            ? CircleAvatar(
                backgroundColor: const Color.fromARGB(46, 255, 255, 255),
                child: Icon(
                  icon,
                  color: Colors.white,
                ),
              )
            : Icon(
                icon,
                color: Colors.white24,
              ),
      ),
    );
  }
}

// Placeholder untuk halaman lokasi (bisa diubah sesuai kebutuhan)
class LocationPage extends StatelessWidget {
  const LocationPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Location Page'));
  }
}
