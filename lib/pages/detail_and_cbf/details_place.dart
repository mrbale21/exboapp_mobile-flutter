import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_info/d_info.dart';
import 'package:exbo_appmobile/pages/detail_and_cbf/rating_screen.dart';
import 'package:exbo_appmobile/service/content_based/database_content_based.dart';
import 'package:exbo_appmobile/widget/widget_support.dart';
import 'package:flutter/material.dart';
import 'package:exbo_appmobile/service/content_based/similiarity_content_based.dart';
import 'package:exbo_appmobile/service/content_based/tf_idf_calculator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../widget/widget_color.dart';
import '../../shared_preferences/cbf_storage.dart';
import '../../shared_preferences/user_session.dart';
import 'maps.dart';

class DetailsPlace extends StatefulWidget {
  final Map<String, dynamic> clickedPlace;

  const DetailsPlace({super.key, required this.clickedPlace});

  @override
  State<DetailsPlace> createState() => _DetailsPlaceState();
}

class _DetailsPlaceState extends State<DetailsPlace> {
  List<Map<String, dynamic>> places = [];
  List<double> scores = [];
  final tfIdfCalculator = TfIdfCalculator();
  final similarityCalculator = SimilarityCalculator();
  final textPreprocessor = TextPreprocessor();
  String userID = UserSession().userID!;
  String _contentSelect = 'Tentang';
  bool showAlert = true; // Untuk mengatur visibilitas peringatan

  String formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]}.');
  }

  @override
  void initState() {
    super.initState();
    rankPlacesContentBased();

    // Timer untuk menyembunyikan peringatan setelah 5 detik
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showAlert = false;
        });
      }
    });
  }

  Future<void> rankPlacesContentBased() async {
    String clickedDescription =
        textPreprocessor.preprocess(widget.clickedPlace['Description'] ?? '');

    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('Place').get();
    List<QueryDocumentSnapshot> allPlacesDocs = snapshot.docs;

    List<Map<String, dynamic>> allPlaces =
        allPlacesDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    List<String> allDescriptions = allPlaces
        .map((place) => textPreprocessor.preprocess(place['Description'] ?? ''))
        .toList();

    List<double> similarityScores = [];

    for (String description in allDescriptions) {
      var clickedVector = tfIdfCalculator.computeTFIDFVector(
          clickedDescription, allDescriptions);
      var descVector =
          tfIdfCalculator.computeTFIDFVector(description, allDescriptions);

      double similarity = similarityCalculator.computeCosineSimilarity(
          clickedVector, descVector);
      similarityScores.add(similarity);
    }

    List<Map<String, dynamic>> placesWithScores = [];
    for (int i = 0; i < allDescriptions.length; i++) {
      if (similarityScores[i] > 0 &&
          allPlaces[i]['Name'] != widget.clickedPlace['Name']) {
        placesWithScores.add({
          'place': allPlaces[i],
          'score': similarityScores[i],
        });
      }
    }

    placesWithScores.sort((a, b) => b['score'].compareTo(a['score']));

    List<Map<String, dynamic>> top5Places = placesWithScores.take(5).toList();

    // Menyimpan score ke shared_preferences menggunakan helper di file cbf_storage.dart
    await CbfStorage.saveCBFScores(top5Places);

    // Menggunakan setState() untuk update state UI
    setState(() {
      places = top5Places
          .map((item) => item['place'] as Map<String, dynamic>)
          .toList();
      scores = top5Places.map((item) => item['score'] as double).toList();
    });
  }

// Pastikan array fasilitas bukan null dan memiliki data
  Widget fasilitasWidget() {
    final fasilitasList = (widget.clickedPlace['Fasilitas'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        [];

    return Wrap(
      spacing: 4.0, // Jarak antar chip
      children: fasilitasList.map((fasilitas) {
        return Chip(
            label: Text(
              fasilitas,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            backgroundColor: const Color.fromRGBO(35, 103, 109, 100),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.transparent)));
      }).toList(),
    );
  }

  // fungsi untuk kapitalise pada text
  String capitalizeWords(String str) {
    return str
        .split(' ')
        .where((word) => word.isNotEmpty) // filter out empty words
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
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

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      // Jika izin ditolak, tampilkan pesan
      if (!mounted) return; // Cek jika widget masih terpasang
      DInfo.dialogError(context, "Location permission denied");
      DInfo.closeDialog(context);

      return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    Position position =
        await Geolocator.getCurrentPosition(locationSettings: locationSettings);

    if (!mounted) return; // Cek jika widget masih terpasang
    // Navigasi ke halaman rekomendasi dengan koordinat yang didapat
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          latitudeUser: position.latitude,
          longitudeUser: position.longitude,
          latitude: widget.clickedPlace["Latitude"],
          longitude: widget.clickedPlace["Longitude"],
          name: widget.clickedPlace['Name'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Stack(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 320,
                  child: Image.network(
                    widget.clickedPlace['Image'],
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 45,
                  left: 20,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Container(
                      height: 30.0,
                      width: 30.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15.0),
                        color: const Color.fromARGB(131, 123, 123, 123),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 15,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(left: 15.0, top: 10.0, right: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      // Peringatan "Beri rating!" yang muncul selama 5 detik
                      Visibility(
                        visible: showAlert,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 255.0, top: 20),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Rating disini!',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 230.0,
                            child: Text(
                              capitalizeWords(widget.clickedPlace['Name']),
                              style: AppWidget.boldTextFeildStyle(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              bool? result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RatingScreen(
                                    userID: userID,
                                    placeID: widget.clickedPlace["id"],
                                    placeName: widget.clickedPlace["Name"],
                                  ),
                                ),
                              );

                              if (result == true) {
                                // Pastikan data sudah terupdate di Firestore
                                await Future.delayed(
                                    const Duration(seconds: 1)); // Jeda sejenak
                                setState(() {});
                              }
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                              ),
                              height: 25,
                              width: 85,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star_border,
                                      size: 18,
                                      color:
                                          Color.fromARGB(220, 255, 255, 255)),
                                  StreamBuilder<DocumentSnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('Place')
                                        .doc(widget.clickedPlace["id"])
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircularProgressIndicator();
                                      }

                                      if (!snapshot.hasData ||
                                          !snapshot.data!.exists) {
                                        return const Text('Place not found');
                                      }

                                      var placeData = snapshot.data!.data()
                                          as Map<String, dynamic>;

                                      return Row(
                                        children: [
                                          Text(
                                            placeData['Rate'].toString(),
                                            style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromARGB(
                                                    220, 255, 255, 255)),
                                          ),
                                          Text(
                                            '(${formatNumber(placeData["JmlUlasan"])})',
                                            style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: Color.fromARGB(
                                                    200, 255, 255, 255)),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 225,
                    child: Text(
                      widget.clickedPlace['Location'].toString(),
                      style: AppWidget.lightTextFeildStyle(),
                      overflow: TextOverflow.clip,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      InkWell(
                        onTap: _contentSelect != 'Tentang'
                            ? () {
                                setState(() {
                                  _contentSelect = 'Tentang';
                                });
                              }
                            : null,
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        child: Column(
                          children: [
                            Text(
                              'Tentang',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _contentSelect == 'Tentang'
                                    ? Colors.black54
                                    : Colors.black,
                              ),
                            ),
                            // Garis bawah
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 2,
                              width: 50,
                              color: _contentSelect == 'Tentang'
                                  ? const Color.fromRGBO(35, 103, 109, 100)
                                  : Colors
                                      .transparent, // Warna garis jika aktif
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20.0),
                      InkWell(
                        onTap: _contentSelect != 'Fasilitas'
                            ? () {
                                setState(() {
                                  _contentSelect = 'Fasilitas';
                                });
                              }
                            : null,
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        child: Column(
                          children: [
                            Text(
                              'Fasilitas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _contentSelect == 'Fasilitas'
                                    ? Colors.black54
                                    : Colors.black,
                              ),
                            ),
                            // Garis bawah
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 2,
                              width: 50,
                              color: _contentSelect == 'Fasilitas'
                                  ? const Color.fromRGBO(35, 103, 109, 100)
                                  : Colors
                                      .transparent, // Warna garis jika aktif
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_contentSelect == 'Tentang')
                    Text(
                      widget.clickedPlace['Description'].toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  if (_contentSelect == 'Fasilitas') fasilitasWidget(),
                  const SizedBox(height: 15),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Harga: ',
                          style: AppWidget.semiBoldTextFeildStyle(),
                        ),
                        TextSpan(
                          text: formatHarga(
                              widget.clickedPlace['Harga'].toString()),
                          style: AppWidget.semiBoldTextFeildStyle().copyWith(
                            color: const Color.fromARGB(255, 134, 134, 134),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () {
                        _getCurrentLocation();
                      },
                      child: Text(
                        'Lihat Lokasi',
                        style: TextStyle(
                            color: WidgetColor.semiHeadColor(),
                            fontFamily: 'Poppins',
                            fontSize: 12),
                      )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[100],
                ),
                height: 180,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                        widget.clickedPlace['Latitude'],
                        widget.clickedPlace[
                            'Longitude']), // Center the map over London
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      // Display map tiles from any source
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // OSMF's Tile Server
                      userAgentPackageName: 'com.example.app',
                      // And many more recommended properties!
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            widget.clickedPlace['Latitude'],
                            widget.clickedPlace['Longitude'],
                          ),
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rekomendasi Content-Based',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 270,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: places.length,
                      itemBuilder: (context, index) {
                        final placeItem = places[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailsPlace(clickedPlace: placeItem),
                              ),
                            );
                          },
                          child: Container(
                            width: 180,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[100],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(10)),
                                    child: Image.network(
                                      placeItem['Image'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        placeItem['Name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        formatHarga(
                                            placeItem['Harga'].toString()),
                                        style: const TextStyle(
                                            color: Color.fromRGBO(
                                                59, 172, 182, 100)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
