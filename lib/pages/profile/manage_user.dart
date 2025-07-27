import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_info/d_info.dart';
import 'package:exbo_appmobile/pages/onboard/onboard_screen.dart';
import 'package:flutter/material.dart';
import '../../service/auth/auth.dart';
import '../../shared_preferences/user_session.dart';
import '../../widget/widget_color.dart';
import '../../widget/widget_support.dart';
import '../auth/reset_password.dart';

class ManageUserScreen extends StatefulWidget {
  const ManageUserScreen({super.key});

  @override
  State<ManageUserScreen> createState() => _ManageUserScreenState();
}

class _ManageUserScreenState extends State<ManageUserScreen> {
  String? _userName, _email;
  String userID = UserSession().userID!; // Ambil userID dari UserSession

  Future<void> _getUserName() async {
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
          _email = userDoc['email'];
        });
      }
    } catch (e) {
      setState(() {});
    }
  }

  // Fungsi untuk menghapus akun pengguna
  Future<void> deleteUser() async {
    bool success = await AuthService
        .deleteUser(); // Memanggil fungsi deleteUser dari AuthService
    await UserSession().clearUserID(); // Hapus userID dari SharedPreferences
    if (success) {
      if (!mounted) return; // Cek jika widget masih terpasang
      DInfo.dialogSuccess(context, 'Berhasil Menghapus Akun');
      DInfo.closeDialog(context, actionAfterClose: () {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Onboard()),
            (route) => false); // Navigasi ke halaman login
      });
    } else {
      if (!mounted) return; // Cek jika widget masih terpasang
      DInfo.dialogError(context, "Gagal menghapus akun.");
      DInfo.closeDialog(context);
    }
  }

  @override
  void initState() {
    _getUserName();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 30.0, left: 20.0),
                          child: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  Color.fromARGB(86, 158, 158, 158),
                              child: Icon(
                                Icons.arrow_back,
                                size: 20,
                                color: Color.fromARGB(224, 255, 255, 255),
                              )),
                        ),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: Container(
                              margin: EdgeInsets.only(
                                  top:
                                      MediaQuery.of(context).size.height / 6.5),
                              child: Material(
                                  elevation: 10.0,
                                  borderRadius: BorderRadius.circular(60),
                                  child: ClipRRect(
                                      child: Image.asset(
                                    "assets/images/no_images.png",
                                    height: 120,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ))),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 35.0, top: 70.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Manage User',
                                    style: AppWidget.boldTextFeildStyle()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                            // Tampilkan konfirmasi sebelum menghapus akun
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Hapus Akun"),
                                  content: const Text(
                                      "Apakah Anda yakin ingin menghapus akun ini?"),
                                  actions: [
                                    TextButton(
                                      child: const Text(
                                        "Batal",
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(); // Tutup dialog
                                      },
                                    ),
                                    TextButton(
                                      child: const Text(
                                        "Hapus",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onPressed: () {
                                        deleteUser(); // Panggil fungsi hapus akun
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
                              width: 110,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10),
                              child: Material(
                                borderRadius: BorderRadius.circular(10),
                                elevation: 2.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 10.0,
                                  ),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Hapus Akun',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                  buildInfoCard(Icons.person, _userName ?? 'User'),
                  const SizedBox(
                    height: 20.0,
                  ),
                  buildInfoCard(Icons.email, _email ?? 'email'),
                  const SizedBox(
                    height: 20.0,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ResetPasswordScreen()));
                    },
                    child: Container(
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
                              // Icon di kiri
                              CircleAvatar(
                                backgroundColor:
                                    Colors.grey[200], // Warna latar belakang
                                child: const Icon(
                                  Icons.password_sharp,
                                  color: Colors.black,
                                ),
                              ),
                              // Text di tengah, dengan Expanded agar menyesuaikan ruang
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Ubah Password?',
                                        style:
                                            AppWidget.semiBoldTextFeildStyle(),
                                        overflow: TextOverflow
                                            .ellipsis, // Jika teks terlalu panjang
                                      ),
                                      const CircleAvatar(
                                          radius: 12,
                                          backgroundColor:
                                              Color.fromARGB(43, 158, 158, 158),
                                          child:
                                              Icon(Icons.arrow_right_rounded))
                                    ],
                                  ),
                                ),
                              ),
                              // Icon di kanan
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildInfoCard(
    IconData icon,
    String value,
  ) {
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
              // Icon di kiri
              CircleAvatar(
                backgroundColor: Colors.grey[200], // Warna latar belakang
                child: Icon(
                  icon,
                  color: Colors.black,
                ),
              ),
              // Text di tengah, dengan Expanded agar menyesuaikan ruang
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    value,
                    style: AppWidget.semiBoldTextFeildStyle(),
                    overflow:
                        TextOverflow.ellipsis, // Jika teks terlalu panjang
                  ),
                ),
              ),
              // Icon di kanan
            ],
          ),
        ),
      ),
    );
  }
}
