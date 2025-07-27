import 'dart:math';
import 'package:logger/logger.dart';
import '../../service/collaborative/collab_service.dart';
import '../../service/content_based/database_content_based.dart';
import '../../service/location/location_service.dart';
import '../../shared_preferences/cbf_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

var logger = Logger();

Future<List<Map<String, dynamic>>> getHybridRecommendation(
    String currentUserId, double userLat, double userLon) async {
  // Ambil daftar tempat yang sudah dirating oleh user
  final ratedPlacesSnapshot = await FirebaseFirestore.instance
      .collection('Rating')
      .where('UserID', isEqualTo: currentUserId)
      .get();
  List<String> ratedPlaceIds =
      ratedPlacesSnapshot.docs.map((doc) => doc['PlaceID'] as String).toList();

  // Mendapatkan rekomendasi dari CF tanpa tempat yang sudah diberi rating
  List<Map<String, dynamic>> cfRecommendations =
      await getRecommendations(currentUserId);

  // Mendapatkan data tempat untuk CBF
  DatabaseContentBased firestoreService = DatabaseContentBased();
  List<Map<String, dynamic>> places = await firestoreService.getPlaces();

  // Mendapatkan data CBF dari shared_preferences
  List<Map<String, dynamic>> cbfScores = await CbfStorage.getCBFScores();

  // Normalisasi CF dan CBF
  double maxCF = cfRecommendations.isNotEmpty
      ? cfRecommendations
          .map<double>((place) => place['Score'] as double)
          .reduce(max)
      : 1.0;
  double minCF = cfRecommendations.isNotEmpty
      ? cfRecommendations
          .map<double>((place) => place['Score'] as double)
          .reduce(min)
      : 0.0;

  double maxCBF = cbfScores.isNotEmpty
      ? cbfScores
          .map<double>((cbfPlace) => cbfPlace['score'] as double)
          .reduce(max)
      : 1.0;
  double minCBF = cbfScores.isNotEmpty
      ? cbfScores
          .map<double>((cbfPlace) => cbfPlace['score'] as double)
          .reduce(min)
      : 0.0;

  List<Map<String, dynamic>> recommendedPlaces = [];

  // Tambahkan rekomendasi CF yang belum dirating
  for (var place in cfRecommendations) {
    if (!ratedPlaceIds.contains(place['PlaceID'])) {
      double normalizedCFScore =
          maxCF == minCF ? 1.0 : (place['Score'] - minCF) / (maxCF - minCF);

      recommendedPlaces.add({
        'Name': place['Name'],
        'PlaceID': place['PlaceID'],
        'CFScore': normalizedCFScore,
        'CBFScore': 0.0,
      });
    }
  }

  // Tambahkan skor CBF
  for (var cbfPlace in cbfScores) {
    String placeName = cbfPlace['place']['Name'];
    double normalizedCBFScore = maxCBF == minCBF
        ? 1.0
        : (cbfPlace['score'] - minCBF) / (maxCBF - minCBF);

    var placeInRecommendations = recommendedPlaces.firstWhere(
      (rec) => rec['Name'] == placeName,
      orElse: () => <String, dynamic>{},
    );
    if (placeInRecommendations.isNotEmpty) {
      placeInRecommendations['CBFScore'] = normalizedCBFScore;
    } else {
      recommendedPlaces.add({
        'Name': placeName,
        'CFScore': 0.0,
        'CBFScore': normalizedCBFScore,
      });
    }
  }

  // Tambahkan tempat tanpa CF dan CBF jika tidak ada skor pada keduanya
  for (var place in places) {
    if (!recommendedPlaces.any((rec) => rec['Name'] == place['Name'])) {
      recommendedPlaces.add({
        'Name': place['Name'],
        'CFScore': 0.0,
        'CBFScore': 0.0,
        'PlaceID': place['PlaceID'], // Menyimpan ID tempat di sini
      });
    }
  }

  // Menghitung skor akhir dari CF, CBF, Rate + JumlahUlasan, jarak, harga, dan fasilitas
  for (var entry in recommendedPlaces) {
    String imageUrl = '';
    String harga = '';
    List<String> facilities = [];
    double placeLat = 0.0;
    double placeLon = 0.0;
    double rate = 0.0;
    int jumlahUlasan = 0;
    String placeId = ''; // Menyimpan ID tempat

    for (var place in places) {
      if (place['Name'] == entry['Name']) {
        imageUrl = place['Image'] ?? '';
        harga = place['Harga'] ?? 'N/A';
        facilities = List<String>.from(place['Fasilitas'] ?? []);
        placeLat = place['Latitude'] ?? 0.0;
        placeLon = place['Longitude'] ?? 0.0;
        rate = place['Rate'] ?? 0.0;
        jumlahUlasan = place['JmlUlasan'] ?? 0;
        placeId = place['id'] ?? ''; // Ambil ID tempat di sini
        break;
      }
    }

    // Hitung weighted rating menggunakan formula IMDB
    double averageRating = 4.5; // Ganti dengan nilai rata-rata yang sesuai
    int minReviews = 1000; // Ambang batas jumlah ulasan minimum
    double weightedRating =
        calculateWeightedRating(rate, jumlahUlasan, averageRating, minReviews);

    // Normalisasi weightedRating
    double maxWeightedRating = 5.0; // Misalkan rating maksimum adalah 5
    double minWeightedRating = 0.0; // Misalkan rating minimum adalah 0
    double normalizedWeightedRating = (weightedRating - minWeightedRating) /
        (maxWeightedRating - minWeightedRating);

    // Hitung skor berdasarkan lokasi, harga, dan fasilitas
    double distance = DistanceCalculator.calculateDistance(
        userLat, userLon, placeLat, placeLon);
    double normalizedDistance = 1 / (1 + distance);
    double price =
        harga.toLowerCase() == 'gratis' ? 0.0 : double.tryParse(harga) ?? 0.0;
    double normalizedPrice = 1 / (1 + price);
    double facilityScore = facilities.length / 12;

    double finalScore = (0.20 * entry['CFScore'] +
        0.10 * entry['CBFScore'] +
        0.15 *
            normalizedWeightedRating + // Menggunakan normalizedWeightedRating
        0.30 * normalizedDistance +
        0.15 * normalizedPrice +
        0.10 * facilityScore);

    entry['PlaceID'] = placeId; // Menyimpan ID tempat ke dalam entry
    entry['Score'] = finalScore;
    entry['Image'] = imageUrl;
    entry['Harga'] = harga;
    entry['Fasilitas'] = facilities;
    entry['Latitude'] = placeLat;
    entry['Longitude'] = placeLon;
    entry['Distance'] = double.parse(distance.toStringAsFixed(1));
  }

  // Urutkan berdasarkan skor tertinggi
  recommendedPlaces.sort((a, b) => b['Score'].compareTo(a['Score']));

  logger.d('Final Hybrid Recommendations: $recommendedPlaces');

  return recommendedPlaces;
}

// Fungsi untuk menghitung weighted rating
double calculateWeightedRating(
    double rate, int jumlahUlasan, double averageRating, int minReviews) {
  // Cek apakah jumlah ulasan sudah memenuhi ambang batas
  if (jumlahUlasan < minReviews) {
    return averageRating; // Kembalikan rating rata-rata keseluruhan jika jumlah ulasan kurang dari ambang batas
  }

  // Hitung weighted rating
  return ((jumlahUlasan * rate) + (minReviews * averageRating)) /
      (jumlahUlasan + minReviews);
}
