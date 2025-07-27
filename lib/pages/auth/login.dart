import 'package:d_info/d_info.dart';
import 'package:exbo_appmobile/pages/auth/register.dart';
import 'package:exbo_appmobile/pages/auth/reset_password.dart';
import 'package:exbo_appmobile/pages/bottom_nav/bottomnav.dart';
import 'package:exbo_appmobile/widget/widget_color.dart';
import 'package:exbo_appmobile/widget/widget_support.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../shared_preferences/user_session.dart';
import '../admin/admin_login.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  var _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // Ambil data pengguna dari Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('Users').doc(user.uid).get();

        // Tanggal batas untuk pengguna yang memerlukan verifikasi email
        final verificationCutoffDate = DateTime(2024, 10, 11);

        // Ambil tanggal pendaftaran pengguna
        Timestamp createdAt = userDoc['createdAt'];
        DateTime registrationDate = createdAt.toDate();

        // Cek apakah pengguna terdaftar setelah batas verifikasi
        if (registrationDate.isAfter(verificationCutoffDate)) {
          // Cek apakah email sudah diverifikasi
          if (!user.emailVerified) {
            const expiredDuration = Duration(hours: 24);
            final now = Timestamp.now();
            final timeDifference = now.toDate().difference(createdAt.toDate());

            // Jika sudah melewati 24 jam dan email belum diverifikasi
            if (timeDifference > expiredDuration) {
              // Hapus akun dari Firebase dan Firestore
              await user.delete();
              await _firestore.collection('Users').doc(user.uid).delete();

              if (!mounted) return;
              DInfo.dialogError(context,
                  'Akun dihapus karena tidak memverifikasi email dalam 24 jam.');
              return;
            } else {
              if (!mounted) return;
              DInfo.dialogError(
                  context, 'Email belum diverifikasi. Silakan cek email Anda.');
              await FirebaseAuth.instance.signOut(); // Logout otomatis
              return;
            }
          }
        }

        // Jika email sudah diverifikasi atau pengguna terdaftar sebelum batas waktu
        if (userDoc.exists) {
          String userID = userDoc['userID']; // Simpan userID

          // Simpan userID di UserSession dan SharedPreferences
          await UserSession().saveUserID(userID);

          if (!mounted) return; // Cek jika widget masih terpasang
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BottomNav()),
          );
        } else {
          if (!mounted) return; // Cek jika widget masih terpasang
          DInfo.dialogError(context, 'User tidak ditemukan di Database');
        }
      }
    } catch (e) {
      if (!mounted) return; // Cek jika widget masih terpasang
      DInfo.dialogError(context, 'Login gagal: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        height: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.5,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                    Color.fromRGBO(35, 103, 109, 100),
                    Color.fromRGBO(47, 143, 157, 100)
                  ])),
            ),
            Container(
              margin:
                  EdgeInsets.only(top: MediaQuery.of(context).size.height / 3),
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40))),
              child: const Text(""),
            ),
            Container(
              margin: const EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
              child: Column(
                children: [
                  Center(
                    child: Image.asset(
                      "assets/images/logo_exbo.png",
                      width: MediaQuery.of(context).size.width / 1.3,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height / 2,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 20.0,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(''),
                              const SizedBox(width: 2.0),
                              Text(
                                "Login",
                                style: AppWidget.headLineTextFeildStyle(),
                              ),
                              IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const AdminLogin()),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.admin_panel_settings_sharp,
                                    size: 25,
                                  )),
                            ],
                          ),
                          const SizedBox(
                            height: 30.0,
                          ),
                          TextFormField(
                            controller: _emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please Enter Email';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: AppWidget.semiBoldTextFeildStyle(),
                                prefixIcon: const Icon(Icons.email_outlined)),
                          ),
                          const SizedBox(
                            height: 30.0,
                          ),
                          TextFormField(
                            controller: _passwordController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please Enter Password';
                              }
                              return null;
                            },
                            obscureText: true,
                            decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: AppWidget.semiBoldTextFeildStyle(),
                                prefixIcon:
                                    const Icon(Icons.password_outlined)),
                          ),
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
                                alignment: Alignment.topRight,
                                child: Text(
                                  "Lupa Password?",
                                  style: AppWidget.semiBoldTextFeildStyle(),
                                )),
                          ),
                          const SizedBox(
                            height: 40.0,
                          ),
                          Center(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: WidgetColor.semiHeadColor(),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14.0, horizontal: 45.0)),
                              child: _isLoading
                                  ? Container(
                                      width: 24,
                                      height: 24,
                                      padding: const EdgeInsets.all(2.0),
                                      child: const CircularProgressIndicator(
                                        color: Color.fromARGB(255, 65, 60, 60),
                                        strokeWidth: 6,
                                      ),
                                    )
                                  : const Text(
                                      "Login",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 40.0,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()));
                    },
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Belum Punya Akun? ",
                            style: AppWidget
                                .semiBoldTextFeildStyle(), // Gaya untuk teks sebelumnya
                          ),
                          TextSpan(
                            text: "Daftar",
                            style: AppWidget.semiBoldTextFeildStyle().copyWith(
                              color: WidgetColor.headColor(),
                            ), // Gaya untuk kata "Daftar"
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
