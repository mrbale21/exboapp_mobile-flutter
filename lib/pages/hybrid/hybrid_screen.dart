import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_info/d_info.dart';
import 'package:exbo_appmobile/pages/detail_and_cbf/details_rec_place.dart';
import 'package:exbo_appmobile/pages/detail_and_cbf/maps.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../../service/hybrid/hybrid_service.dart';
import '../../shared_preferences/user_location_providers.dart';
import '../../widget/widget_support.dart';
import '../../shared_preferences/user_session.dart';
import 'package:geolocator/geolocator.dart';
import '../collaborative/collab_screen.dart';

var logger = Logger();

class HybridRecomendScreen extends StatefulWidget {
  const HybridRecomendScreen({super.key});

  @override
  State<HybridRecomendScreen> createState() => _HybridRecomendScreenState();
}

class _HybridRecomendScreenState extends State<HybridRecomendScreen> {
  String userID = UserSession().userID!; // Ambil userID dari UserSession
  Future<Position>? _userLocation;
  String _selectedFilter = 'Hybrid'; // Filter yang dipilih
  double? lat, lon;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Panggil fungsi pengambilan lokasi saat inisialisasi
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Jika izin ditolak, tampilkan pesan
        if (!mounted) return;
        DInfo.dialogError(context, "Location permission denied");
        DInfo.closeDialog(context);
        return;
      }
    }

    // Ambil lokasi dengan settings yang diatur
    setState(() {
      _userLocation = Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).then((position) {
        if (mounted) {
          Provider.of<UserLocationProvider>(context, listen: false)
              .updateUserLocation(); // Update lokasi pengguna
          lat = position.latitude;
          lon = position.longitude;
        }
        return position;
      });
    });
  }

  String formatHarga(String harga) {
    if (harga.toLowerCase() == 'gratis') {
      return 'Gratis';
    } else {
      double? hargaValue = double.tryParse(harga);
      if (hargaValue != null) {
        final formatter = NumberFormat('#,###', 'id_ID');
        return 'Rp. ${formatter.format(hargaValue)}';
      } else {
        return 'Harga tidak valid';
      }
    }
  }

  String capitalizeWords(String str) {
    return str
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Future<List<Map<String, dynamic>>> getFilteredRecommendations() async {
    final Position position = await _userLocation!;
    lat = position.latitude;
    lon = position.longitude;

    List<Map<String, dynamic>> recommendations =
        await getHybridRecommendation(userID, lat!, lon!);

    if (_selectedFilter == 'Hybrid') {
      recommendations.sort((a, b) => b["Score"].compareTo(a["Score"]));
    } else {
      recommendations.sort((a, b) => a["Distance"].compareTo(b["Distance"]));
    }

    return recommendations;
  }

  void navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Future<void> saveUserChoice(
      String userID, String placeID, String placeName, int rank) async {
    final docRef = FirebaseFirestore.instance.collection('UserChoices').doc(
        '$userID-$placeID'); // Menggunakan kombinasi userID dan placeID sebagai ID unik

    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      // Jika data sudah ada, update timestamp, jumlah klik, dan ranking
      await docRef.update({
        'timestamp': FieldValue.serverTimestamp(),
        'clickCount': FieldValue.increment(1), // Menambah jumlah klik
        'rank': rank, // Memperbarui ranking dengan ranking yang baru
      });
    } else {
      // Jika tidak ada, tambahkan entri baru
      await docRef.set({
        'userID': userID,
        'placeID': placeID,
        'placeName': placeName,
        'rank': rank, // Menyimpan ranking terbaru
        'timestamp': FieldValue.serverTimestamp(),
        'clickCount': 1, // Inisialisasi dengan satu klik
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _selectedFilter == 'Hybrid'
              ? 'Rekomendasi Hybrid'
              : 'Rekomendasi Lokasi Terdekat',
          style: AppWidget.semiBoldTextFeildStyle(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    // Tampilkan menu filter ketika teks "Filter" diklik
                    showMenu(
                      color: Colors.white,
                      shadowColor: Colors.grey,
                      context: context,
                      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
                      items: [
                        PopupMenuItem(
                          value: 'Hybrid',
                          enabled: _selectedFilter != 'Hybrid',
                          child: TextButton(
                            onPressed: _selectedFilter != 'Hybrid'
                                ? () {
                                    setState(() {
                                      _selectedFilter = 'Hybrid';
                                    });
                                    Navigator.pop(context);
                                  }
                                : null,
                            child: const Text('Hybrid'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'Lokasi Terdekat',
                          enabled: _selectedFilter != 'Lokasi Terdekat',
                          child: TextButton(
                            onPressed: _selectedFilter != 'Lokasi Terdekat'
                                ? () {
                                    setState(() {
                                      _selectedFilter = 'Lokasi Terdekat';
                                    });
                                    Navigator.pop(context);
                                  }
                                : null,
                            child: const Text('Lokasi Terdekat'),
                          ),
                        ),
                        PopupMenuItem(
                          child: TextButton(
                            onPressed: () {
                              navigateTo(const CollabRecomendScreen());
                            },
                            child: const Text('Collaborative'),
                          ),
                        ),
                      ],
                    );
                  },
                  child: const Text(
                    'Filter',
                    style: TextStyle(
                        fontWeight:
                            FontWeight.w500), // Gaya teks dapat disesuaikan
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    // Mengulangi fungsi untuk menampilkan menu filter
                    showMenu(
                      color: Colors.white,
                      shadowColor: Colors.grey,
                      context: context,
                      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
                      items: [
                        PopupMenuItem(
                          value: 'Hybrid',
                          enabled: _selectedFilter != 'Hybrid',
                          child: TextButton(
                            onPressed: _selectedFilter != 'Hybrid'
                                ? () {
                                    setState(() {
                                      _selectedFilter = 'Hybrid';
                                    });
                                    Navigator.pop(context);
                                  }
                                : null,
                            child: const Text('Hybrid'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'Lokasi Terdekat',
                          enabled: _selectedFilter != 'Lokasi Terdekat',
                          child: TextButton(
                            onPressed: _selectedFilter != 'Lokasi Terdekat'
                                ? () {
                                    setState(() {
                                      _selectedFilter = 'Lokasi Terdekat';
                                    });
                                    Navigator.pop(context);
                                  }
                                : null,
                            child: const Text('Lokasi Terdekat'),
                          ),
                        ),
                        PopupMenuItem(
                          child: TextButton(
                            onPressed: () {
                              navigateTo(const CollabRecomendScreen());
                            },
                            child: const Text('Collaborative'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Position>(
              future: _userLocation,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: getFilteredRecommendations(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                            child:
                                Text('Terjadi kesalahan: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Container(
                            color: const Color.fromARGB(255, 254, 202, 47),
                            padding: const EdgeInsets.all(10.0),
                            child: const Text(
                              'Tidak ada rekomendasi ditemukan!!\nBerikan rating terlebih dahulu ke beberapa tempat agar mendapatkan rekomendasi Hybrid!',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final recommendations = snapshot.data!;

                      return ListView.builder(
                        itemCount: min(recommendations.length, 10),
                        itemBuilder: (context, index) {
                          final placeItem = recommendations[index];
                          final imageUrl = placeItem["Image"] ?? '';
                          final placeName =
                              placeItem["Name"] ?? 'Unknown Place';
                          final distance =
                              placeItem["Distance"] ?? 'Unknown Distance';
                          final score =
                              placeItem["Score"]?.toStringAsFixed(2) ?? '';
                          final harga = placeItem["Harga"] ?? '';
                          final fasilitas = placeItem["Fasilitas"] ?? [];
                          final placeLat = placeItem["Latitude"];
                          final placeLon = placeItem["Longitude"];

                          return Container(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 5),
                            child: Material(
                              elevation: 3,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                                child: ExpansionTile(
                                  title: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: Image.network(
                                          imageUrl,
                                          height: 90,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              capitalizeWords(placeName),
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 15.0,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'Poppins',
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 5),
                                            if (_selectedFilter == 'Hybrid')
                                              Text(
                                                'Skor: $score',
                                                style: AppWidget
                                                    .semiLightTextFeildStyle(),
                                              ),
                                            const SizedBox(height: 5),
                                            Text(
                                              'Harga: ${formatHarga(harga)}',
                                              style: AppWidget
                                                  .semiLightTextFeildStyle(),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              'Jarak: $distance km',
                                              style: AppWidget
                                                  .semiLightTextFeildStyle(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16.0,
                                          right: 16.0,
                                          top: 8.0,
                                          bottom: 5.0),
                                      child: Text(
                                        'Fasilitas: ${fasilitas.join(", ")}',
                                        style:
                                            AppWidget.semiLightTextFeildStyle(),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      DetailsRecPlace(
                                                    clickedPlace: placeItem,
                                                  ),
                                                ),
                                              );
                                              // Simpan pilihan user saat mereka membuka detail
                                              if (_selectedFilter == 'Hybrid') {
                                                saveUserChoice(
                                                  userID,
                                                  placeItem["PlaceID"],
                                                  placeItem["Name"],
                                                  index +
                                                      1, // Menyimpan peringkat berdasarkan indeks
                                                );
                                              }
                                            },
                                            child: const Text(
                                              'Detail',
                                              style: TextStyle(
                                                  color: Colors.blue,
                                                  fontFamily: 'Poppins'),
                                            )),
                                        TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      MapScreen(
                                                    latitude: placeLat,
                                                    longitude: placeLon,
                                                    name: placeName,
                                                    latitudeUser: lat!,
                                                    longitudeUser: lon!,
                                                  ),
                                                ),
                                              );
                                              if (_selectedFilter == 'Hybrid') {
                                                saveUserChoice(
                                                  userID,
                                                  placeItem["PlaceID"],
                                                  placeItem["Name"],
                                                  index +
                                                      1, // Menyimpan peringkat berdasarkan indeks
                                                );
                                              }
                                            },
                                            child: const Text(
                                              'Lihat Lokasi',
                                              style: TextStyle(
                                                  color: Colors.blue,
                                                  fontFamily: 'Poppins'),
                                            )),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }
                return const Center(child: Text('Gagal mendapatkan lokasi'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
