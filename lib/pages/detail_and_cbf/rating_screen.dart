import 'package:d_info/d_info.dart';
import 'package:exbo_appmobile/widget/widget_support.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingScreen extends StatefulWidget {
  final String userID;
  final String placeID;
  final String placeName;

  const RatingScreen(
      {super.key,
      required this.userID,
      required this.placeID,
      required this.placeName});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double _currentRating = 0;

  @override
  void initState() {
    super.initState();
    _fetchCurrentRating();
  }

  // Mengambil rating yang sudah ada sebelumnya untuk Place dan User tertentu
  void _fetchCurrentRating() async {
    final ratingSnapshot = await _firestore
        .collection('Rating')
        .where('UserID', isEqualTo: widget.userID)
        .where('PlaceID', isEqualTo: widget.placeID)
        .get();

    if (ratingSnapshot.docs.isNotEmpty) {
      setState(() {
        _currentRating =
            (ratingSnapshot.docs.first['rating'] as num).toDouble();
      });
    }
  }

  void _submitRating() async {
    // Validasi rating
    if (_currentRating == 0.0) {
      DInfo.dialogError(context, "Silakan pilih rating sebelum melanjutkan.");
      return; // Hentikan eksekusi jika rating tidak valid
    }

    final ratingRef = _firestore.collection('Rating');
    final placeRef = _firestore.collection('Place').doc(widget.placeID);

    // Ambil dokumen Place yang ingin diperbarui
    final placeSnapshot = await placeRef.get();
    if (placeSnapshot.exists) {
      final placeData = placeSnapshot.data();
      if (placeData != null) {
        // Ambil nilai Rate dan JmlUlasan yang ada
        double existingRate = (placeData['Rate'] as num).toDouble();
        int existingJmlUlasan = (placeData['JmlUlasan'] as num).toInt();

        // Hitung nilai total rate sebelumnya (Rate * JmlUlasan)
        double totalRating = existingRate * existingJmlUlasan;

        // Cek apakah user sudah pernah memberi rating untuk place ini
        final ratingSnapshot = await ratingRef
            .where('UserID', isEqualTo: widget.userID)
            .where('PlaceID', isEqualTo: widget.placeID)
            .get();

        bool isNewRating = ratingSnapshot.docs.isEmpty;

        if (!isNewRating) {
          // Jika user sudah memberi rating, kurangi rating lama dari total
          double previousRating =
              (ratingSnapshot.docs.first['rating'] as num).toDouble();
          totalRating -= previousRating; // Kurangi rating lama dari total
        } else {
          // Jika ini rating baru dari user, tambahkan 1 ke JmlUlasan
          existingJmlUlasan += 1;
        }

        // Tambahkan rating baru dari user
        totalRating += _currentRating;

        // Hitung rata-rata baru
        double newRate = totalRating / existingJmlUlasan;
        newRate = double.parse(
            newRate.toStringAsFixed(1)); // Format ke 1 angka desimal

        if (!isNewRating) {
          // Jika rating sudah ada, update dokumen tersebut
          final existingRatingID = ratingSnapshot.docs.first.id;
          await ratingRef.doc(existingRatingID).update({
            'rating': _currentRating,
            'timestamp': FieldValue.serverTimestamp(),
          });
          if (!mounted) return; // Cek jika widget masih terpasang
          DInfo.dialogSuccess(context, 'Rating berhasil diperbarui!');
          DInfo.closeDialog(context);
        } else {
          // Jika rating belum ada, tambahkan dokumen baru
          await ratingRef.add({
            'UserID': widget.userID,
            'PlaceID': widget.placeID,
            'rating': _currentRating,
            'timestamp': FieldValue.serverTimestamp(),
          });
          if (!mounted) return; // Cek jika widget masih terpasang
          DInfo.dialogSuccess(context, 'Rating berhasil ditambahkan!');
          DInfo.closeDialog(context);
        }

        // Perbarui data di koleksi Place
        await placeRef.update({
          'Rate': newRate,
          'JmlUlasan': existingJmlUlasan, // Update hanya jika ulasan baru
        });

        if (!mounted) return; // Cek jika widget masih terpasang
        // Setelah berhasil, kembalikan nilai 'true' ke halaman DetailsPlace
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Rating',
            style: AppWidget.boldTextFeildStyle(),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Berikan Rating untuk ${widget.placeName}',
              style: AppWidget.semiBoldTextFeildStyle(),
            ),
            const SizedBox(height: 20),
            RatingBar.builder(
              initialRating: _currentRating,
              minRating: 0,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _currentRating = rating;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitRating,
              child: const Text('Kirim Rating'),
            ),
          ],
        ),
      ),
    );
  }
}
