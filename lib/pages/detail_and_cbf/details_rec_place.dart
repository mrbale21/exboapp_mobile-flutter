import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exbo_appmobile/pages/detail_and_cbf/rating_screen.dart';
import 'package:exbo_appmobile/service/content_based/database_content_based.dart';
import 'package:exbo_appmobile/widget/widget_support.dart';
import 'package:flutter/material.dart';
import 'package:exbo_appmobile/service/content_based/similiarity_content_based.dart';
import 'package:exbo_appmobile/service/content_based/tf_idf_calculator.dart';
import 'package:intl/intl.dart';
import '../../shared_preferences/user_session.dart';

class DetailsRecPlace extends StatefulWidget {
  final Map<String, dynamic> clickedPlace;

  const DetailsRecPlace({super.key, required this.clickedPlace});

  @override
  State<DetailsRecPlace> createState() => _DetailsRecPlaceState();
}

class _DetailsRecPlaceState extends State<DetailsRecPlace> {
  List<Map<String, dynamic>> places = [];
  List<double> scores = [];
  final tfIdfCalculator = TfIdfCalculator();
  final similarityCalculator = SimilarityCalculator();
  final textPreprocessor = TextPreprocessor();
  String userID = UserSession().userID!;
  bool showAlert = true;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          showAlert = false;
        });
      }
    });
  }

  String formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match match) => '${match[1]}.');
  }

  Widget fasilitasWidget() {
    final fasilitasList =
        (widget.clickedPlace['Fasilitas'] as List<dynamic>? ?? [])
            .map((item) => item.toString())
            .toList();

    return Wrap(
      spacing: 4.0,
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
            side: const BorderSide(color: Colors.transparent),
          ),
        );
      }).toList(),
    );
  }

  String capitalizeWords(String str) {
    return str
        .split(' ')
        .where((word) => word.isNotEmpty)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Place')
            .doc(widget.clickedPlace["PlaceID"])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Place not found'));
          }

          var placeData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
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
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  margin:
                      const EdgeInsets.only(left: 15.0, top: 10.0, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 220.0,
                            child: Text(
                              capitalizeWords(
                                  widget.clickedPlace['Name'].toString()),
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
                                    placeID: widget.clickedPlace["PlaceID"],
                                    placeName: widget.clickedPlace["Name"],
                                  ),
                                ),
                              );

                              if (result == true) {
                                await Future.delayed(
                                    const Duration(seconds: 1));
                                setState(() {});
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                  height: 25,
                                  width: 70,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.star_border,
                                          size: 17, color: Colors.white),
                                      Row(
                                        children: [
                                          Text(
                                            placeData['Rate'].toString(),
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  220, 255, 255, 255),
                                            ),
                                          ),
                                          Text(
                                            '(${formatNumber(placeData["JmlUlasan"])})',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  220, 255, 255, 255),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Visibility(
                                  visible: showAlert,
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                        top: 20, left: 10),
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Rating disini!',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        placeData['Description'] ?? '',
                        style: AppWidget.semiLightTextFeildStyle(),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Color.fromARGB(255, 35, 103, 109)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 280,
                            child: Text(
                              placeData['Location'] ?? '',
                              style: const TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                  color: Color.fromARGB(255, 75, 75, 75)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.attach_money,
                              color: Color.fromARGB(255, 35, 103, 109)),
                          const SizedBox(width: 8),
                          Text(
                            formatHarga(placeData['Harga'] ?? ''),
                            style: const TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 75, 75, 75),
                                fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Fasilitas',
                          style:
                              TextStyle(fontSize: 17, fontFamily: 'Poppins')),
                      const SizedBox(height: 5),
                      fasilitasWidget(),
                      const SizedBox(height: 20),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
                ...places.map((place) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 5),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5.0,
                          offset: Offset(0.0, 3.0),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      // onTap: () {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) => DetailsPlace(place: place),
                      //     ),
                      //   );
                      // },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 200.0,
                            child: Text(
                              place['Name'],
                              style: AppWidget.boldTextFeildStyle(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: Color.fromARGB(255, 35, 103, 109)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}
