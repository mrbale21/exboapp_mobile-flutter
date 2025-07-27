import 'package:exbo_appmobile/service/location/location_service.dart';
import 'package:exbo_appmobile/widget/widget_support.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/place/database_place.dart';
import '../../widget/widget_handler_back.dart';
import '../bottom_nav/bottomnav.dart';

class LocationReccomndScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const LocationReccomndScreen(
      {super.key, required this.latitude, required this.longitude});

  @override
  State<LocationReccomndScreen> createState() => _LocationReccomndScreenState();
}

class _LocationReccomndScreenState extends State<LocationReccomndScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> places = [];
  List<Map<String, dynamic>> _recommendations = [];

  getPlace() async {
    places = await SourcePlace.gets();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    getPlace();
    _getRecommendations();
  }

  Future<void> _getRecommendations() async {
    QuerySnapshot snapshot = await _firestore.collection('Place').get();
    List<Map<String, dynamic>> places = snapshot.docs.map((doc) {
      return {
        'name': doc['Name'],
        'image': doc['Image'],
        'latitude': double.tryParse(doc['Latitude'].toString()) ?? 0.0,
        'longitude': double.tryParse(doc['Longitude'].toString()) ?? 0.0,
      };
    }).toList();

    // Hitung jarak dan simpan dalam list
    List<Map<String, dynamic>> recommendations = places.map((place) {
      double distance = DistanceCalculator.calculateDistance(
        widget.latitude,
        widget.longitude,
        place['latitude'],
        place['longitude'],
      );

      return {
        'image': place['image'],
        'name': place['name'],
        'distance': distance,
      };
    }).toList();

    // Urutkan berdasarkan jarak dan ambil 5 terdekat
    recommendations.sort((a, b) => a['distance'].compareTo(b['distance']));
    if (mounted) {
      setState(() {
        _recommendations = recommendations.take(10).toList();
      });
    }
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
    return BackPressHandler(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80.0,
          title: Text(
            'Daftar Tempat Terdekat\nLat: ${widget.latitude}\nLon: ${widget.longitude}',
            style: AppWidget.boldTextFeildStyle(),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const BottomNav()));
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 10.0, left: 15.0),
          child: ListView.builder(
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final placeItem = _recommendations[index];
              return Container(
                color: Colors.white,
                height: 75,
                margin: const EdgeInsets.only(right: 20, bottom: 10),
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
                            placeItem["image"],
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
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
                                capitalizeWords(placeItem["name"]),
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
                            Text(
                                "Jarak: ${placeItem['distance'].toStringAsFixed(2)} km"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
