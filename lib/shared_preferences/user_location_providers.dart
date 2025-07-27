import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class UserLocationProvider with ChangeNotifier {
  Position? _userLocation;

  Position? get userLocation => _userLocation;

  Future<void> updateUserLocation() async {
    try {
      // Menggunakan LocationSettings untuk menentukan pengaturan lokasi
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high, // Menentukan akurasi lokasi
        distanceFilter:
            10, // Mengatur jarak minimal perubahan lokasi (dalam meter)
      );

      _userLocation = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings);
      notifyListeners(); // Notifikasi kepada listener bahwa data telah berubah
    } catch (e) {
      // Menangani error dengan menampilkan pesan kesalahan di console
      logger.e("Error getting location: $e");
    }
  }
}
