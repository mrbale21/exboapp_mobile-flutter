import 'package:d_info/d_info.dart';
import 'package:exbo_appmobile/widget/widget_color.dart';
import 'package:exbo_appmobile/widget/widget_support.dart';
import 'package:flutter/material.dart';
import '../../service/auth/auth.dart';
import 'login.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  var _isLoading = false;

  void _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      setState(() =>
          _isLoading = true); // Set loading sebelum memulai proses pendaftaran
      final user = await AuthService.registerWithEmail(name, email, password);

      setState(() => _isLoading = false); // Set loading selesai setelah proses

      if (user != null) {
        if (!mounted) return; // Cek jika widget masih terpasang
        DInfo.dialogSuccess(context,
            'Pendaftaran berhasil. Silakan cek email untuk verifikasi.');

        // Tunggu hingga pengguna memverifikasi email
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return; // Cek jika widget masih terpasang
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        });
      } else {
        if (!mounted) return; // Cek jika widget masih terpasang
        DInfo.dialogError(context, 'Pendaftaran gagal. Silakan coba lagi.');
      }
    } else {
      DInfo.dialogError(context, 'Mohon lengkapi semua field.');
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
                  const SizedBox(height: 25.0),
                  Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height / 1.8,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20)),
                      child: Form(
                        child: Column(
                          children: [
                            const SizedBox(height: 30.0),
                            Text(
                              "Sign up",
                              style: AppWidget.headLineTextFeildStyle(),
                            ),
                            const SizedBox(height: 30.0),
                            TextFormField(
                              controller: _nameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please Enter Name';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                  hintText: 'Name',
                                  hintStyle: AppWidget.semiBoldTextFeildStyle(),
                                  prefixIcon:
                                      const Icon(Icons.person_outlined)),
                            ),
                            const SizedBox(height: 30.0),
                            TextFormField(
                              controller: _emailController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please Enter E-mail';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                  hintText: 'Email',
                                  hintStyle: AppWidget.semiBoldTextFeildStyle(),
                                  prefixIcon: const Icon(Icons.email_outlined)),
                            ),
                            const SizedBox(height: 30.0),
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
                            const SizedBox(height: 40.0),
                            Center(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: WidgetColor.semiHeadColor(),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14.0, horizontal: 45.0),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Color.fromRGBO(
                                              179, 232, 229, 100),
                                          strokeWidth: 6,
                                          backgroundColor:
                                              Color.fromRGBO(35, 103, 109, 100),
                                        ),
                                      )
                                    : const Text(
                                        "Register",
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
                  ),
                  const SizedBox(height: 50.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Sudah Punya Akun? ",
                            style: AppWidget
                                .semiBoldTextFeildStyle(), // Gaya untuk teks sebelumnya
                          ),
                          TextSpan(
                            text: "Login",
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
            ),
          ],
        ),
      ),
    );
  }
}
