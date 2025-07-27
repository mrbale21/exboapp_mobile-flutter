import 'package:d_info/d_info.dart';
import 'package:exbo_appmobile/pages/admin/add_update_place.dart';
import 'package:exbo_appmobile/service/place/database_place.dart';
import 'package:flutter/material.dart';
import '../../widget/widget_support.dart';
import 'rekomendasi_user.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  List<Map<String, dynamic>> list = [];

  getPlace() async {
    list = await SourcePlace.getsAsc();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    getPlace();
    super.initState();
  }

  delete(String id) async {
    // Tampilkan dialog konfirmasi terlebih dahulu
    bool? isYes = await DInfo.dialogConfirmation(
      context,
      'Delete?',
      'Are you sure you want to delete the place data?',
    );

    // Jika pengguna mengonfirmasi (Yes), baru lakukan penghapusan
    if (isYes ?? false) {
      bool success = await SourcePlace.delete(id);
      if (success) {
        if (!mounted) return; // Cek jika widget masih terpasang
        DInfo.dialogSuccess(context, 'Success Delete Place');
        // Menunggu dialog ditutup sebelum melakukan refresh
        DInfo.closeDialog(context, actionAfterClose: () {
          getPlace(); // Refresh list setelah penghapusan berhasil
        });
      } else {
        if (!mounted) return; // Cek jika widget masih terpasang
        DInfo.dialogError(context, "Failed Delete Place");
        DInfo.closeDialog(context);
      }
    } else {
      if (!mounted) return; // Cek jika widget masih terpasang
      DInfo.dialogError(context, "Delete Canceled");
      DInfo.closeDialog(context);
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Home Admin',
              style: AppWidget.boldTextFeildStyle(),
            ),
            IconButton(
              icon: const Icon(Icons.people_alt),
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UserRecommendationsPage()));
              },
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: list.isEmpty
          ? const Center(
              child: Text("Data Kosong"),
            )
          : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                //Get the item at this index
                Map<String, dynamic> placeItem = list[index];
                //REturn the widget for the list items
                return Container(
                  margin: const EdgeInsets.only(
                      right: 20.0, bottom: 20.0, left: 20),
                  child: Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(20))),
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
                                  placeItem['Image'],
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
                                      capitalizeWords(placeItem['Name']),
                                      style: AppWidget.semiBoldTextFeildStyle(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    placeItem['Category'],
                                    style: AppWidget.lightTextFeildStyle(),
                                  ),
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
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => AddUpdatePlace(
                                              placeItem: placeItem))).then(
                                      (value) {
                                    if (value ?? false) {
                                      getPlace();
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 0),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  delete(placeItem['id']);
                                },
                              ),
                            ],
                          ),
                          // GestureDetector(
                          //     onTap: () {
                          //       Navigator.of(context).push(MaterialPageRoute(
                          //           builder: (context) =>
                          //               detailPlaceAdmin((thisItem['id']))));
                          //     },
                          //     child: Icon(Icons.update))
                        ],
                      ),
                    ),
                  ),
                );
              }),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black38,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AddUpdatePlace())).then((value) {
            if (value ?? false) {
              getPlace();
            }
          });
        },
        tooltip: 'Increment',
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ), //Display a l
    );
  }
}
