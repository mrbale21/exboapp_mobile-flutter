import 'package:flutter/material.dart';
import '../../service/collaborative/collab_service.dart'; // Import file fungsi rekomendasi
import '../../widget/widget_support.dart';
import '../../shared_preferences/user_session.dart';

class CollabRecomendScreen extends StatefulWidget {
  const CollabRecomendScreen({super.key});

  @override
  State<CollabRecomendScreen> createState() => _CollabRecomendScreenState();
}

class _CollabRecomendScreenState extends State<CollabRecomendScreen> {
  String userID = UserSession().userID!; // Ambil userID dari UserSession

// fungsi untuk kapitalise pada text
  String capitalizeWords(String str) {
    return str
        .split(' ')
        .where((word) => word.isNotEmpty) // filter out empty words
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daftar Rekomendasi Collaborative',
          style: AppWidget.semiBoldTextFeildStyle(),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getRecommendations(userID), // Panggil fungsi di sini
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Menampilkan pesan kesalahan
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Menampilkan pesan jika tidak ada rekomendasi
            return Center(
              child: Container(
                color: const Color.fromARGB(255, 254, 202, 47),
                padding: const EdgeInsets.all(10.0),
                child: const Text(
                  'Tidak ada rekomendasi ditemukan!!\nBerikan rating terlebih dahulu ke beberapa tempat agar mendapatkan rekomendasi Collaborative!',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final recommendations = snapshot.data!;

          return ListView.builder(
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final placeItem = recommendations[index];

              // Memastikan bahwa 'Image', 'Name', dan 'Score' ada di dalam placeItem
              final imageUrl = placeItem["Image"] ?? '';
              final placeName = placeItem["Name"] ?? 'Unknown Place';
              final score = placeItem['Score'] != null
                  ? placeItem['Score'].toStringAsFixed(2)
                  : 'N/A';

              return Container(
                color: Colors.white,
                height: 75,
                margin: const EdgeInsets.only(
                    right: 20, bottom: 10, top: 5, left: 20),
                child: Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    margin: const EdgeInsets.only(left: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network(
                            imageUrl,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 60,
                                width: 60,
                                color: Colors.grey,
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 220,
                              child: Text(
                                capitalizeWords(placeName),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text('Skor Kemiripan: $score'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
