import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class DatabaseContentBased {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getPlaces() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('Place').get();
      return snapshot.docs.map((doc) {
        Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
        docData['id'] = doc.id; // Menyimpan ID untuk referensi
        return docData;
      }).toList();
    } catch (e) {
      logger.e('Error fetching places: $e');
      return [];
    }
  }
}

class TextPreprocessor {
  final Set<String> _stopWords = {
    'seorang',
    'tentang',
    'yang',
    'di',
    'karena',
    'dan',
    'atau',
    'jika',
    'kemudian',
    'setelah',
    'pada',
    'berada',
    'yaitu',
    'serta',
    'jadi',
    'begitu',
    'sebuah',
    'kalau',
    'itu',
    'lagi',
    'semua',
    'bisa',
    'pergi',
    'dari',
    'untuk',
    'saya',
    'butuh',
    'mati',
    'hidup',
    'apa',
    'terlalu',
    'dia',
    'sangat',
    'adalah',
    'keluar',
    'kamu',
    'ketika',
    'bagaimana',
    'kapan',
    'ulang',
    'kenapa',
    'seseorang',
    'dimana',
    'kemana',
    'anda',
    'engkau',
    'tempat',
    'masuk',
    'apapun',
    'kalian',
  };

  // Fungsi untuk preprocessing teks
  String preprocess(String text) {
    // Mengubah teks menjadi huruf kecil
    String lowerCaseText = text.toLowerCase();

    // Menghapus karakter non-alfabet
    String cleanedText = lowerCaseText.replaceAll(RegExp(r'[^a-z\s]'), '');

    // Menghapus kata-kata yang tidak penting (stop words)
    List<String> words = cleanedText
        .split(' ')
        .where((word) => !_stopWords.contains(word) && word.isNotEmpty)
        .toList();

    // Mengembalikan teks yang telah diproses
    return words.join(' ');
  }
}
