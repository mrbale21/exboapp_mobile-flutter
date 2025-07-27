import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/hybrid/hybrid_service.dart';
import 'user_location_providers.dart';

class RecommendationProvider with ChangeNotifier {
  bool hasRecommendations = false;
  bool hasSeenRecommendations = false;

  void setRecommendations(bool value) {
    hasRecommendations = value;
    notifyListeners();
  }

  void markAsSeen() {
    hasSeenRecommendations = true;
    notifyListeners();
  }

  Future<void> checkRecommendations(BuildContext context, String userID) async {
    // Ambil lokasi pengguna dari UserLocationProvider
    final userLocationProvider =
        Provider.of<UserLocationProvider>(context, listen: false);
    final userLocation = userLocationProvider.userLocation;

    if (userLocation == null) return; // Pastikan lokasi pengguna tidak null

    double latitude = userLocation.latitude;
    double longitude = userLocation.longitude;

    // Ambil rekomendasi berdasarkan userID, latitude, dan longitude
    List<Map<String, dynamic>> recommendations =
        await getHybridRecommendation(userID, latitude, longitude);

    // Perbarui status berdasarkan hasil rekomendasi
    hasRecommendations = recommendations.isNotEmpty;
    hasSeenRecommendations = false; // Reset status setelah rekomendasi baru
    notifyListeners(); // Pemberitahuan kepada pendengar bahwa status telah diperbarui
  }
}
