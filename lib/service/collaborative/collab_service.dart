import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:logger/logger.dart';

var logger = Logger();

// Menghitung adjusted cosine similarity
double calculateAdjustedSimilarity(
    List<double> userRatings1, List<double> userRatings2) {
  double averageA = userRatings1.reduce((a, b) => a + b) / userRatings1.length;
  double averageB = userRatings2.reduce((a, b) => a + b) / userRatings2.length;

  double numerator = 0;
  double denominatorA = 0;
  double denominatorB = 0;

  for (int i = 0; i < userRatings1.length; i++) {
    if (userRatings1[i] > 0 && userRatings2[i] > 0) {
      // Hanya menghitung untuk rating yang ada
      double adjustedA = userRatings1[i] - averageA;
      double adjustedB = userRatings2[i] - averageB;

      numerator += adjustedA * adjustedB;
      denominatorA += pow(adjustedA, 2);
      denominatorB += pow(adjustedB, 2);
    }
  }

  if (denominatorA == 0 || denominatorB == 0) {
    return 0; // Jika salah satu denominator 0, kembalikan 0
  }

  return numerator / (sqrt(denominatorA) * sqrt(denominatorB));
}

// Mendapatkan rekomendasi
Future<List<Map<String, dynamic>>> getRecommendations(
    String currentUserId) async {
  final firestore = FirebaseFirestore.instance;

  // Ambil semua rating dan tempat
  QuerySnapshot ratingSnapshot = await firestore.collection('Rating').get();
  QuerySnapshot placeSnapshot = await firestore.collection('Place').get();

  // Membuat map untuk menyimpan rating per pengguna
  Map<String, List<double>> userRatings = {};
  Map<String, String> placeIds = {}; // Menyimpan ID tempat untuk akses cepat

  // Mengisi data rating per pengguna
  for (var doc in placeSnapshot.docs) {
    placeIds[doc['id']] = doc['Name']; // Simpan nama tempat
  }

  for (var doc in ratingSnapshot.docs) {
    String userId = doc['UserID'];
    String placeId = doc['PlaceID'];
    double rating = doc['rating'].toDouble();

    if (!userRatings.containsKey(userId)) {
      userRatings[userId] = List.filled(placeSnapshot.docs.length, 0.0);
    }

    int placeIndex =
        placeSnapshot.docs.indexWhere((place) => place['id'] == placeId);
    if (placeIndex != -1) {
      userRatings[userId]![placeIndex] = rating;
    }
  }

  // Hitung kemiripan dengan pengguna lain
  Map<String, double> similarityScores = {};
  List<double> currentUserRatings =
      userRatings[currentUserId] ?? List.filled(placeSnapshot.docs.length, 0.0);

  // Memastikan pengguna memiliki lebih dari 2 rating
  if (currentUserRatings.where((rating) => rating > 0).length >= 2) {
    userRatings.forEach((userId, ratings) {
      if (userId != currentUserId &&
          ratings.where((rating) => rating > 0).length >= 2) {
        double similarity =
            calculateAdjustedSimilarity(currentUserRatings, ratings);
        if (similarity > 0) {
          similarityScores[userId] = similarity;
        }
      }
    });
  }

  // Rekomendasi berdasarkan score kemiripan
  Map<String, double> recommendations = {};
  double maxRating = 5.0; // Misalnya, rating maksimum yang mungkin

  for (var entry in similarityScores.entries) {
    String similarUserId = entry.key;
    double similarityScore = entry.value;

    for (var doc in ratingSnapshot.docs) {
      if (doc['UserID'] == similarUserId) {
        String placeId = doc['PlaceID'];
        double rating = doc['rating'].toDouble();

        // Pastikan pengguna saat ini belum memberi rating pada tempat ini
        int currentUserPlaceIndex =
            placeSnapshot.docs.indexWhere((place) => place['id'] == placeId);
        if (currentUserPlaceIndex != -1 &&
            currentUserRatings[currentUserPlaceIndex] == 0) {
          // Menghitung weighted sum dengan normalisasi
          recommendations[placeId] = (recommendations[placeId] ?? 0) +
              (rating * similarityScore) / maxRating;
        }
      }
    }
  }

  // Mengambil data tempat
  List<Map<String, dynamic>> recommendedPlaces = [];

  for (var entry in recommendations.entries) {
    String placeId = entry.key;
    double score = entry.value;

    if (score > 0) {
      var placeDoc =
          placeSnapshot.docs.firstWhere((doc) => doc['id'] == placeId);
      recommendedPlaces.add({
        'Name': placeDoc['Name'],
        'Image': placeDoc['Image'],
        'Score': score,
      });
    }
  }

  // Mengurutkan berdasarkan score tertinggi
  recommendedPlaces.sort((a, b) => b['Score'].compareTo(a['Score']));

  return recommendedPlaces;
}
