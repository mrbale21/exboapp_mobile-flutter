import 'dart:convert'; // Untuk parsing JSON
import 'package:shared_preferences/shared_preferences.dart';

class CbfStorage {
  // Fungsi untuk mendapatkan skor CBF dari SharedPreferences
  static Future<List<Map<String, dynamic>>> getCBFScores() async {
    final prefs = await SharedPreferences.getInstance();

    // Mendapatkan data dari SharedPreferences sebagai String
    String? cbfScoresJson = prefs.getString('cbf_scores');

    if (cbfScoresJson != null) {
      // Parsing JSON ke dalam List<Map<String, dynamic>>
      List<dynamic> decodedList = jsonDecode(cbfScoresJson);

      // Mengonversi List<dynamic> menjadi List<Map<String, dynamic>>
      List<Map<String, dynamic>> cbfScores =
          decodedList.map((e) => e as Map<String, dynamic>).toList();

      return cbfScores;
    }

    // Jika tidak ada data yang ditemukan, kembalikan list kosong
    return [];
  }

  // Fungsi untuk menyimpan skor CBF ke SharedPreferences
  static Future<void> saveCBFScores(
      List<Map<String, dynamic>> cbfScores) async {
    final prefs = await SharedPreferences.getInstance();

    // Mengubah List<Map<String, dynamic>> menjadi JSON string
    String encodedList = jsonEncode(cbfScores);

    // Simpan data ke SharedPreferences
    await prefs.setString('cbf_scores', encodedList);
  }

  // Fungsi untuk menghapus skor CBF dari SharedPreferences (saat logout)
  static Future<void> clearCBFScores() async {
    final prefs = await SharedPreferences.getInstance();

    // Menghapus entri 'cbf_scores' dari SharedPreferences
    await prefs.remove('cbf_scores');
  }
}
