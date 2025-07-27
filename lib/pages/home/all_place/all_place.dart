import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../detail_and_cbf/details_place.dart';
import 'package:exbo_appmobile/service/place/database_place.dart';
import '../content_home/categories_content.dart';

class AllPlace extends StatefulWidget {
  const AllPlace({super.key});

  @override
  State<AllPlace> createState() => _AllPlaceState();
}

class _AllPlaceState extends State<AllPlace> {
  List<Map<String, dynamic>> places = [];
  TextEditingController controllerSearch = TextEditingController();
  bool allCategory = false,
      tamanHiburan = false,
      kuliner = false,
      cagarAlam = false;

  int currentPage = 0;
  final int itemsPerPage = 10;

  getPlace() async {
    places = await SourcePlace.getsAsc();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    getPlace();
    super.initState();
  }

  search(String name) async {
    if (name.isNotEmpty) {
      places = await SourcePlace.search(name);
      setState(() {});
    } else {
      getPlace();
    }
  }

  category(String name) async {
    places = await SourcePlace.category(name);
    setState(() {});
  }

  void onCategoryChange(bool all, bool taman, bool kulinerr, bool alam) {
    setState(() {
      allCategory = all;
      tamanHiburan = taman;
      kuliner = kulinerr;
      cagarAlam = alam;
    });
  }

  String formatNumber(int number) {
    final formatter = NumberFormat("#,##0", "en_US");
    return formatter.format(number);
  }

  String capitalizeWords(String str) {
    return str
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    int totalPlaces = places.length;
    int totalPages = (totalPlaces / itemsPerPage).ceil();

    List<Map<String, dynamic>> paginatedPlaces =
        places.skip(currentPage * itemsPerPage).take(itemsPerPage).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40.0,
        title: const Text('Daftar Semua Tempat'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            CategoriesContent(
              getPlace: getPlace,
              category: category,
              allCategory: allCategory,
              tamanHiburan: tamanHiburan,
              kuliner: kuliner,
              cagarAlam: cagarAlam,
              onCategoryChange: onCategoryChange,
            ),
            Padding(
              padding:
                  const EdgeInsets.only(top: 100.0), // Jarak untuk semua sisi
              child: Column(
                children: [
                  Expanded(
                    child: paginatedPlaces.isEmpty
                        ? const Center(
                            child: Text("Data Kosong"),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: paginatedPlaces.length,
                            shrinkWrap: true,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.9,
                            ),
                            itemBuilder: (context, index) {
                              Map<String, dynamic> placeItem =
                                  paginatedPlaces[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailsPlace(
                                        clickedPlace: placeItem,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                          top: Radius.circular(10),
                                        ),
                                        child: Image.network(
                                          placeItem["Image"],
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              capitalizeWords(
                                                  placeItem["Name"]),
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14.0,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              overflow: TextOverflow.ellipsis,
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
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  '(${formatNumber(placeItem['JmlUlasan'] ?? 0)})',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
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
                  Row(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
