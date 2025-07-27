import 'package:exbo_appmobile/pages/home/all_place/all_place.dart';
import 'package:flutter/material.dart';
import 'package:exbo_appmobile/service/place/database_place.dart';
import 'package:exbo_appmobile/widget/widget_color.dart';
import 'package:exbo_appmobile/widget/widget_support.dart';
import 'package:provider/provider.dart';
import '../../../shared_preferences/providers_cek_recomend.dart';
import '../../../shared_preferences/user_session.dart';
import 'all_place_content.dart';
import 'categories_content.dart';
import 'popular_place.dart';
import 'search_content.dart';

class Contents extends StatefulWidget {
  const Contents({super.key});

  @override
  State<Contents> createState() => _ContentsState();
}

class _ContentsState extends State<Contents> {
  List<Map<String, dynamic>> places = [];
  TextEditingController controllerSearch = TextEditingController();
  bool allCategory = false,
      tamanHiburan = false,
      kuliner = false,
      cagarAlam = false;

  getPlace() async {
    places = await SourcePlace.gets();
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Menggunakan SingleChildScrollView
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchContent(
            controllerSearch: controllerSearch,
            search: search,
          ),
          const SizedBox(height: 20.0),
          Text("Kategori", style: AppWidget.semiBoldTextFeildStyle()),
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.only(right: 20),
            child: CategoriesContent(
              getPlace: getPlace,
              category: category,
              allCategory: allCategory,
              tamanHiburan: tamanHiburan,
              kuliner: kuliner,
              cagarAlam: cagarAlam,
              onCategoryChange: onCategoryChange,
            ),
          ),
          const SizedBox(height: 18.0),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Daftar Tempat Wisata",
                    style: AppWidget.semiBoldTextFeildStyle()),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllPlace(),
                      ),
                    ).then((_) {
                      if (context.mounted) {
                        // Memperbarui status rekomendasi dengan menggunakan provider
                        String? userID = UserSession()
                            .userID; // Ambil userID dari UserSession
                        Provider.of<RecommendationProvider>(context,
                                listen: false)
                            .checkRecommendations(context,
                                userID!); // Panggil fungsi dengan userID
                      }
                    });
                  },
                  child: Text("Lihat Semua",
                      style: TextStyle(
                          fontFamily: 'poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: WidgetColor.semiColor())),
                )
              ],
            ),
          ),
          const SizedBox(height: 10.0),
          SizedBox(
              height: 220,
              child: AllPlaceContent(
                places: places,
              )),
          const SizedBox(height: 10.0),
          Text("Terpopuler", style: AppWidget.boldTextFeildStyle()),
          const SizedBox(height: 20.0),
          // Menggunakan Container yang mengandung recommend
          const PopularPlaceContent(),
        ],
      ),
    );
  }
}
