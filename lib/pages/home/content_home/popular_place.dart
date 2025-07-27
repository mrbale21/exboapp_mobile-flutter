import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../detail_and_cbf/details_place.dart';
import 'package:logger/logger.dart';

import '../../../shared_preferences/providers_cek_recomend.dart';
import '../../../shared_preferences/user_session.dart';

class PopularPlaceContent extends StatefulWidget {
  const PopularPlaceContent({super.key});

  @override
  State<PopularPlaceContent> createState() => _PopularPlaceContentState();
}

class _PopularPlaceContentState extends State<PopularPlaceContent> {
  List<Map<String, dynamic>> places = [];
  int currentPage = 0;
  final int itemsPerPage = 6;
  var logger = Logger();

  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }

  // Fungsi untuk mengambil dan mengurutkan tempat berdasarkan rating dan jumlah ulasan
  void fetchPlaces() async {
    FirebaseFirestore.instance
        .collection('Place')
        .orderBy('Rate',
            descending: true) // Urutkan berdasarkan Rate (Rating tertinggi)
        .orderBy('JmlUlasan',
            descending: true) // Urutkan juga berdasarkan Jumlah Ulasan
        .get()
        .then((querySnapshot) {
      List<Map<String, dynamic>> tempPlaces = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> placeData = doc.data();

        // Pastikan Rate dalam bentuk double
        if (placeData['Rate'] is String) {
          placeData['Rate'] = double.tryParse(placeData['Rate']) ??
              0.0; // Konversi dari string ke double
        }

        // Pastikan JmlUlasan dalam bentuk integer
        if (placeData['JmlUlasan'] is String) {
          placeData['JmlUlasan'] = int.tryParse(placeData['JmlUlasan']) ?? 0;
        }

        tempPlaces.add(placeData);
      }
      setState(() {
        places = tempPlaces;
      });
    }).catchError((e) {
      logger.e("Error fetching places: $e");
    });
  }

  // Fungsi untuk memformat angka dengan pemisah ribuan
  String formatNumber(int number) {
    final formatter = NumberFormat("#,##0", "en_US");
    return formatter.format(number);
  }

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
    int totalPlaces = places.length;
    int totalPages = (totalPlaces / itemsPerPage).ceil();

    List<Map<String, dynamic>> paginatedPlaces =
        places.skip(currentPage * itemsPerPage).take(itemsPerPage).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.73,
      child: Column(
        children: [
          Expanded(
            child: paginatedPlaces.isEmpty
                ? const Center(
                    child: Text("Data Kosong"),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: paginatedPlaces.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      Map<String, dynamic> placeItem = paginatedPlaces[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsPlace(
                                clickedPlace: placeItem,
                              ),
                            ),
                          ).then((_) {
                            if (context.mounted) {
                              // Memperbarui status rekomendasi dengan menggunakan provider
                              String? userID = UserSession()
                                  .userID; // Ambil userID dari UserSession
                              Provider.of<RecommendationProvider>(context,
                                      listen: false)
                                  .checkRecommendations(context,
                                      userID!); // Panggil fungsi dengan userID
                            }
                          });
                        },
                        child: Container(
                          color: Colors.white,
                          height: 75,
                          margin: const EdgeInsets.only(right: 20, bottom: 10),
                          child: Material(
                            elevation: 3,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              margin: const EdgeInsets.only(left: 9),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: Image.network(
                                      placeItem["Image"],
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 220,
                                        child: Text(
                                          capitalizeWords(placeItem["Name"]),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Poppins',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 15,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            placeItem['Rate'].toString(),
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 13),
                                          ),
                                          Text(
                                            '(${formatNumber(placeItem['JmlUlasan'] ?? 0)})',
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20.0, bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: currentPage > 0
                      ? () {
                          setState(() {
                            currentPage--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_circle_left),
                  iconSize: 30,
                ),
                IconButton(
                  onPressed: currentPage < totalPages - 1
                      ? () {
                          setState(() {
                            currentPage++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_circle_right),
                  iconSize: 30,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
