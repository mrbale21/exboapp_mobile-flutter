import 'package:cloud_firestore/cloud_firestore.dart';

class SourcePlace {
  static final db = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> gets() async {
    QuerySnapshot<Map<String, dynamic>> response = await db
        .collection("Place")
        .orderBy("JmlUlasan", descending: true)
        .get();
    return response.docs.map((e) => e.data()).toList();
  }

  static Future<List<Map<String, dynamic>>> getsAsc() async {
    QuerySnapshot<Map<String, dynamic>> response =
        await db.collection("Place").orderBy("Name", descending: false).get();
    return response.docs.map((e) => e.data()).toList();
  }

  static Future<bool> add(Map<String, dynamic> data) async {
    final response = await db.collection("Place").add(data);
    response.update({"id": response.id});
    return true;
  }

  static Future<bool> update(Map<String, dynamic> data) async {
    await db.collection("Place").doc(data['id']).update(data);
    return true;
  }

  static Future<bool> delete(String id) async {
    await db.collection("Place").doc(id).delete();
    return true;
  }

  static Future<List<Map<String, dynamic>>> search(String name) async {
    String normalizedQuery = name.toLowerCase();
    QuerySnapshot<Map<String, dynamic>> response = await db
        .collection("Place")
        .where('Name', isGreaterThanOrEqualTo: normalizedQuery)
        .where('Name', isLessThanOrEqualTo: '$normalizedQuery\uf8ff')
        .get();
    return response.docs.map((e) => e.data()).toList();
  }

  static Future<List<Map<String, dynamic>>> category(String name) async {
    QuerySnapshot<Map<String, dynamic>> response =
        await db.collection("Place").where("Category", isEqualTo: name).get();
    return response.docs.map((e) => e.data()).toList();
  }
}
