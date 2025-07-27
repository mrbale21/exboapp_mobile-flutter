import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:d_info/d_info.dart';
import 'package:exbo_appmobile/pages/detail_and_cbf/rating_screen.dart';
import 'package:flutter/material.dart';

import '../../shared_preferences/user_session.dart';
import '../../widget/widget_support.dart';

class RatingsUserScreen extends StatefulWidget {
  const RatingsUserScreen({super.key});

  @override
  State<RatingsUserScreen> createState() => _RatingsUserScreenState();
}

class _RatingsUserScreenState extends State<RatingsUserScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userID;

  @override
  void initState() {
    super.initState();
    userID = UserSession().userID; // Ambil userID dari UserSession
  }

  Stream<QuerySnapshot> getUserRatingsStream() {
    // Mengambil stream data rating berdasarkan UserID
    return _firestore
        .collection(
            'Rating') // Pastikan koleksi ini sesuai dengan nama yang benar
        .where('UserID', isEqualTo: userID)
        .snapshots();
  }

  Future<void> deleteRating(String ratingID) async {
    await _firestore
        .collection('Rating')
        .doc(ratingID)
        .delete(); // Menghapus rating berdasarkan ID
    if (!mounted) return; // Cek jika widget masih terpasang
    DInfo.dialogSuccess(context, 'Success Hapus Rating');
    DInfo.closeDialog(context, actionAfterClose: () {
      Navigator.pop(context, true);
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Rating Saya'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getUserRatingsStream(), // Stream rating dari Firestore
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada rating.'));
          }

          var userRatings = snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            var placeID = data['PlaceID'];
            return {
              'ratingID': doc.id, // ID dokumen rating
              'placeID': placeID,
              'rating': data['rating'],
            };
          }).toList();

          return ListView.builder(
            itemCount: userRatings.length,
            itemBuilder: (context, index) {
              final ratingData = userRatings[index];
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore
                    .collection('Place')
                    .doc(ratingData['placeID'])
                    .get(),
                builder: (context, placeSnapshot) {
                  if (placeSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (!placeSnapshot.hasData || !placeSnapshot.data!.exists) {
                    return const ListTile(
                      title: Text('Tempat tidak ditemukan'),
                    );
                  }

                  var placeData =
                      placeSnapshot.data!.data() as Map<String, dynamic>;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 20.0),
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.all(Radius.circular(18))),
                        padding: const EdgeInsets.all(5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    placeData['Image'],
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 15.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 130,
                                      child: Text(
                                        capitalizeWords(placeData['Name']),
                                        style:
                                            AppWidget.semiBoldTextFeildStyle(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text('Rating: ${ratingData['rating']}'),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.update,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    bool? result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RatingScreen(
                                          userID: userID!,
                                          placeID: ratingData['placeID'],
                                          placeName: placeData['Name'],
                                        ),
                                      ),
                                    );

                                    if (result == true) {
                                      // Data sudah terupdate, stream otomatis menangani pembaruan
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    // Tampilkan konfirmasi sebelum menghapus rating
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Hapus Rating"),
                                          content: const Text(
                                              "Apakah Anda yakin hapus rating ini?"),
                                          actions: [
                                            TextButton(
                                              child: const Text("Batal",
                                                  style: TextStyle(
                                                      color: Colors.blue)),
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Tutup dialog
                                              },
                                            ),
                                            TextButton(
                                              child: const Text("Hapus",
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                              onPressed: () {
                                                deleteRating(ratingData[
                                                    'ratingID']); // Menghapus rating menggunakan ID
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
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
          );
        },
      ),
    );
  }
}
