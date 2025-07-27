import 'package:d_info/d_info.dart';
import 'package:exbo_appmobile/pages/auth/register.dart';
import 'package:exbo_appmobile/widget/widget_color.dart';
import 'package:flutter/material.dart';
import '../../service/auth/auth.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  var _isLoading = false;

  void _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isNotEmpty) {
      await AuthService.sendPasswordResetEmail(email);

      if (!mounted) return; // Cek jika widget masih terpasang
      DInfo.dialogSuccess(
          context, 'Email reset password telah dikirim ke email anda.');
      DInfo.closeDialog(context, actionAfterClose: () {
        // Kembali ke halaman login
        Navigator.pop(context, true);
      });
    } else {
      DInfo.dialogError(context, 'Mohon masukkan email yang valid.');
      DInfo.closeDialog(context);
    }
    setState(() => _isLoading = true);
    Future.delayed(
      const Duration(seconds: 7),
      () => setState(() => _isLoading = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      height: double.infinity,
      color: const Color.fromARGB(156, 1, 35, 39),
      child: Column(children: [
        const SizedBox(
          height: 70.0,
        ),
        Container(
          alignment: Alignment.topCenter,
          child: const Text(
            "Pemulihan Password",
            style: TextStyle(
                color: Colors.white,
                fontSize: 30.0,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(
          height: 50.0,
        ),
        const Text(
          "Enter your mail",
          style: TextStyle(
              color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.only(left: 10.0, right: 10.0),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.only(left: 10.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 2.0),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please Enter Email';
                    }
                    return null;
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      hintText: "Email",
                      hintStyle: TextStyle(fontSize: 18.0, color: Colors.white),
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.white70,
                        size: 30.0,
                      ),
                      border: InputBorder.none),
                ),
              ),
              const SizedBox(
                height: 40.0,
              ),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: WidgetColor.lightColor(),
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
                          "Reset Passowrd",
                          style: TextStyle(
                              color: Colors.white, fontFamily: 'Poppins'),
                        ),
                ),
              ),
              const SizedBox(
                height: 50.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Tidak Punya Akun?",
                    style: TextStyle(fontSize: 18.0, color: Colors.white),
                  ),
                  const SizedBox(
                    width: 5.0,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()));
                    },
                    child: const Text(
                      "Daftar",
                      style: TextStyle(
                          color: Color.fromRGBO(179, 232, 229, 100),
                          fontSize: 20.0,
                          fontWeight: FontWeight.w500),
                    ),
                  )
                ],
              )
            ],
          ),
        ))
      ]),
    ));
  }
}
