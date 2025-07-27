import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widget/widget_color.dart';
import '../../../widget/widget_support.dart';
import '../../detail_and_cbf/details_place.dart';
import '../../../shared_preferences/providers_cek_recomend.dart';
import '../../../shared_preferences/user_session.dart';

class AllPlaceContent extends StatelessWidget {
  final List<Map<String, dynamic>> places; // Parameter untuk data tempat

  const AllPlaceContent({super.key, required this.places});

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
    return places.isEmpty
        ? const Center(
            child: Text("Data Kosong"), // Menampilkan pesan jika data kosong
          )
        : ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: min(places.length, 5), // Menampilkan maksimal 5 tempat
            shrinkWrap: true,
            scrollDirection: Axis.horizontal, // Scroll horizontal untuk tempat
            itemBuilder: (context, index) {
              Map<String, dynamic> placeItem = places[index];

              return GestureDetector(
                onTap: () async {
                  // Navigate to the DetailsPlace screen
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailsPlace(
                        clickedPlace: placeItem,
                      ),
                    ),
                  );

                  // Check if the widget is still mounted before accessing the context
                  if (context.mounted) {
                    String? userID =
                        UserSession().userID; // Ambil userID dari UserSession

                    // Update the recommendations status using the provider
                    Provider.of<RecommendationProvider>(context, listen: false)
                        .checkRecommendations(
                            context, userID!); // Panggil fungsi dengan userID
                  }
                },
                child: Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 4, right: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gambar tempat wisata dengan Material dan shadow
                      Material(
                        elevation: 8.0,
                        borderRadius: BorderRadius.circular(10),
                        shadowColor: WidgetColor.semiHeadColor(),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            placeItem["Image"], // Field "Image" dari tempat
                            height: 160,
                            width: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Placeholder jika gambar gagal dimuat
                              return Container(
                                height: 160,
                                width: 220,
                                color: Colors.grey,
                                child: const Center(
                                  child: Icon(Icons.error, color: Colors.red),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Nama tempat wisata
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        width: 220,
                        child: Text(
                          capitalizeWords(placeItem[
                              "Name"]), // Nama tempat dengan kapitalisasi
                          style: AppWidget.semiBoldTextFeildStyle(),
                          overflow: TextOverflow
                              .ellipsis, // Potong teks jika terlalu panjang
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Lokasi tempat wisata
                      Container(
                        padding: const EdgeInsets.only(left: 5, right: 8),
                        width: 220,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 150, // Batas lebar teks lokasi
                                  child: Text(
                                    placeItem['Location'], // Field "Location"
                                    style: AppWidget.lightTextFeildStyle(),
                                    overflow: TextOverflow
                                        .ellipsis, // Potong teks jika terlalu panjang
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
