import 'package:flutter/material.dart';

class BackPressHandler extends StatelessWidget {
  final Widget child; // Halaman yang akan dibungkus

  const BackPressHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Keluar Aplikasi?'),
            content: const Text('Apakah kamu yakin ingin keluar?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context)
                    .pop(false), // Kembali dengan nilai 'false'
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(true); // Kembali dengan nilai 'true'
                },
                child: const Text('Keluar'),
              ),
            ],
          ),
        );

        // Jika pengguna memilih untuk keluar
        if (shouldExit == true) {
          // Keluar dari aplikasi
          return true; // Mengizinkan aplikasi untuk keluar
        }

        return false; // Mencegah aplikasi keluar
      },
      child: child, // Konten halaman yang dibungkus
    );
  }
}
