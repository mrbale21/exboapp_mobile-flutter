import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_info/d_info.dart';
import 'package:exbo_appmobile/pages/onboard/onboard_screen.dart';
import 'package:exbo_appmobile/pages/profile/manage_user.dart';
import 'package:exbo_appmobile/widget/widget_handler_back.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../service/auth/auth.dart';
import '../../shared_preferences/cbf_storage.dart';
import '../../shared_preferences/providers_cek_recomend.dart';
import '../../shared_preferences/user_session.dart';
import '../../widget/widget_color.dart';
import '../../widget/widget_support.dart';
import '../collaborative/collab_screen.dart';
import 'rating_user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userName;
  var userID = UserSession().userID; // Ambil userID dari UserSession

  @override
  void initState() {
    super.initState();
    userID = UserSession().userID!; // Ambil userID dari UserSession
    _getUserName();
  }

  Future<void> _getUserName() async {
    if (userID == null) {
      // Jika userID tidak tersedia, bisa tampilkan pesan atau lakukan penanganan lain
      return;
    }

    try {
      // Mengambil data user dari Firestore berdasarkan userID
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userID)
          .get();

      // Mendapatkan nama user dari dokumen
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'];
        });
      }
    } catch (e) {
      // Jika terjadi kesalahan, bisa ditangani di sini
      if (mounted) {
        setState(() {});
      }
    }
  }

  // Fungsi untuk logout
  Future<void> logout() async {
    await AuthService.logout(); // Memanggil fungsi logout dari AuthService
    await UserSession().clearUserID(); // Hapus userID dari SharedPreferences
    await CbfStorage.clearCBFScores(); // hapus cbf score dari sahredpref
    if (!mounted) return; // Cek jika widget masih terpasang
    DInfo.dialogSuccess(context, 'Berhasil Logout');
    DInfo.closeDialog(context, actionAfterClose: () {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Onboard()),
          (route) => false); // Navigasi ke halaman login
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackPressHandler(
      child: Scaffold(
        body: _userName == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(
                              top: 45.0, left: 20.0, right: 20.0),
                          height: MediaQuery.of(context).size.height / 4.3,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                              color: WidgetColor.semiHeadColor(),
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.elliptical(
                                      MediaQuery.of(context).size.width,
                                      105.0))),
                        ),
                        Center(
                          child: Container(
                            margin: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height / 6.5),
                            child: Material(
                                elevation: 10.0,
                                borderRadius: BorderRadius.circular(60),
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.asset(
                                      "assets/images/no_images.png",
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ))),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 70.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_userName ?? 'User',
                                  style: AppWidget.boldTextFeildStyle()),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    const Padding(
                      padding: EdgeInsets.only(left: 20.0, bottom: 5.0),
                      child: Align(
                        alignment: Alignment
                            .centerLeft, // Menempatkan teks di sisi kiri
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ManageUserScreen()));
                      },
                      child: buildInfoCard(Icons.settings, 'Manage User',
                          Icons.arrow_right_outlined),
                    ),
                    const SizedBox(height: 30.0),
                    const Padding(
                      padding: EdgeInsets.only(left: 20.0, bottom: 5.0),
                      child: Align(
                        alignment: Alignment
                            .centerLeft, // Menempatkan teks di sisi kiri
                        child: Text(
                          'Recommendation',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RatingsUserScreen(),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            // Memperbarui status rekomendasi dengan menggunakan provider
                            String? userID = UserSession()
                                .userID; // Ambil userID dari UserSession

                            Provider.of<RecommendationProvider>(context,
                                    listen: false)
                                .checkRecommendations(context,
                                    userID!); // Panggil fungsi dengan userID
                          }
                        });
                      },
                      child: buildInfoCard(Icons.notes, 'Daftar Rating',
                          Icons.arrow_right_outlined),
                    ),
                    const SizedBox(height: 10.0),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const CollabRecomendScreen()));
                      },
                      child: buildInfoCard(
                          Icons.recommend,
                          'Rekomendasi Collaborative',
                          Icons.arrow_right_outlined),
                    ),
                    const SizedBox(height: 10.0),
                    // GestureDetector(
                    //   onTap: () {
                    //     Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //             builder: (context) =>
                    //                 const HybridRecomendScreen()));
                    //   },
                    //   child: buildInfoCard(Icons.recommend,
                    //       'Rekomendasi Hybrid', Icons.arrow_right_outlined),
                    // ),
                    const SizedBox(height: 30.0),
                    GestureDetector(
                        onTap: () {
                          // Tampilkan konfirmasi sebelum menghapus akun
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("SignOut"),
                                content: const Text(
                                    "Apakah Anda yakin keluar dari akun ini?"),
                                actions: [
                                  TextButton(
                                    child: const Text("Batal",
                                        style: TextStyle(color: Colors.blue)),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Tutup dialog
                                    },
                                  ),
                                  TextButton(
                                    child: const Text("SignOut",
                                        style: TextStyle(color: Colors.red)),
                                    onPressed: () {
                                      logout(); // Panggil fungsi hapus akun
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 100,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Material(
                              borderRadius: BorderRadius.circular(10),
                              elevation: 2.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15.0,
                                  horizontal: 10.0,
                                ),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sign Out',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget buildInfoCard(IconData icon, String value, IconData icon2) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        elevation: 2.0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 15.0,
            horizontal: 10.0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: WidgetColor.semiHeadColor(),
                  ),
                  const SizedBox(width: 10.0),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Icon(
                icon2,
                color: WidgetColor.semiHeadColor(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
