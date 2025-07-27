import 'dart:io';
import 'package:d_info/d_info.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../service/place/database_place.dart';
import '../../widget/widget_support.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';

class AddUpdatePlace extends StatefulWidget {
  const AddUpdatePlace({super.key, this.placeItem});
  final Map? placeItem;

  @override
  State<AddUpdatePlace> createState() => _AddUpdatePlaceState();
}

class _AddUpdatePlaceState extends State<AddUpdatePlace> {
  final List<String> placeCategory = ['Taman Hiburan', 'Kuliner', 'Cagar Alam'];
  final List<String> availableFacilities = [
    'Parkir',
    'Wi-Fi',
    'Toilet',
    'Mushola',
    'Restoran',
    'ATM',
    'Playgroud',
    'Cocok Untuk Anak-anak',
    'Berkelompok',
    'Keluarga',
    'Mendaki',
    'Camping'
  ];

  String? selectedCategory;
  List<String> selectedFacilities = [];
  TextEditingController nameController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController rateController = TextEditingController();
  TextEditingController jmlUlasanController = TextEditingController();
  TextEditingController latitudeController = TextEditingController();
  TextEditingController longitudeController = TextEditingController();
  TextEditingController priceController = TextEditingController(); // Harga

  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  String? selectedImageUrl;

  Future getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);

    selectedImage = File(image!.path);
    setState(() {});
  }

  var _isLoading = false;
  void _onSubmit() async {
    setState(() => _isLoading = true);

    if (widget.placeItem == null) {
      await addPlace();
    } else {
      await updatePlace();
    }

    setState(() => _isLoading = false);
  }

  addPlace() async {
    try {
      // Validasi field lainnya
      if (nameController.text.isEmpty) {
        DInfo.dialogError(context, "Nama tidak boleh kosong.");
        return;
      }
      if (locationController.text.isEmpty) {
        DInfo.dialogError(context, "Lokasi tidak boleh kosong.");
        return;
      }
      if (descriptionController.text.isEmpty) {
        DInfo.dialogError(context, "Deskripsi tidak boleh kosong.");
        return;
      }

      if (rateController.text.isEmpty) {
        DInfo.dialogError(context, "Rating tidak boleh kosong.");
        return;
      }

      double rate = double.parse(rateController.text.replaceAll(',', '.'));
      if (rate < 1 || rate > 5) {
        DInfo.dialogError(context, "Rating harus antara 1 hingga 5.");
        return;
      }
      if (jmlUlasanController.text.isEmpty) {
        DInfo.dialogError(context, "Jumlah ulasan tidak boleh kosong.");
        return;
      }
      if (selectedCategory == null) {
        DInfo.dialogError(context, "Kategori tidak boleh kosong.");
        return;
      }
      if (priceController.text.isEmpty) {
        DInfo.dialogError(context, "Price tidak boleh kosong.");
        return;
      }
      String priceInput = priceController.text;
      if (priceInput.toLowerCase() != "gratis") {
        double? priceValue = double.tryParse(priceInput.replaceAll(',', '.'));
        if (priceValue == null || priceValue < 1000) {
          DInfo.dialogError(
              context, "Harga harus berupa angka di atas 1000 atau 'gratis'.");
          return;
        }
      }
      if (latitudeController.text.isEmpty) {
        DInfo.dialogError(context, "Latitude tidak boleh kosong.");
        return;
      }
      if (longitudeController.text.isEmpty) {
        DInfo.dialogError(context, "Longitude tidak boleh kosong.");
        return;
      }

      if (selectedFacilities.isEmpty) {
        DInfo.dialogError(context, "Fasilitas tidak boleh kosong.");
        return;
      }

      // Proses upload gambar dan penyimpanan data
      String addId = randomAlphaNumeric(10);
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child("blogImages").child(addId);
      final UploadTask task = firebaseStorageRef.putFile(selectedImage!);
      var downloadUrl = await (await task).ref.getDownloadURL();

      bool success = await SourcePlace.add({
        "Image": downloadUrl,
        "Name": nameController.text.toLowerCase(),
        "Location": locationController.text,
        "Description": descriptionController.text,
        "Rate": rate,
        "JmlUlasan": int.parse(jmlUlasanController.text.replaceAll('.', '')),
        "Latitude": double.parse(latitudeController.text),
        "Longitude": double.parse(longitudeController.text),
        "Category": selectedCategory,
        "Harga": priceInput,
        "Fasilitas": selectedFacilities,
        "id": ""
      });

      if (success) {
        if (!mounted) return;
        DInfo.dialogSuccess(context, 'Success Add Place');
        DInfo.closeDialog(context, actionAfterClose: () {
          Navigator.pop(context, true);
        });
      } else {
        if (!mounted) return;
        DInfo.dialogError(context, "Failed Add Place");
        DInfo.closeDialog(context);
      }
    } catch (e) {
      // Tangani error jika ada
      DInfo.dialogError(context, "Error: $e");
      DInfo.closeDialog(context);
    }
  }

  updatePlace() async {
    try {
      String? downloadUrl;

      double rate = double.parse(rateController.text.replaceAll(',', '.'));
      if (rate < 1 || rate > 5) {
        DInfo.dialogError(context, "Rating harus antara 1 hingga 5.");
        return;
      }

      // Cek apakah input adalah "gratis" atau angka
      String price = priceController.text;
      if (price.toLowerCase() != "gratis") {
        double? priceValue = double.tryParse(price.replaceAll(',', '.'));
        if (priceValue == null || priceValue < 1000) {
          DInfo.dialogError(
              context, "Harga harus berupa angka di atas 1000 atau 'gratis'.");
          return;
        }
      }

      if (selectedImage != null) {
        String addId = randomAlphaNumeric(10);
        Reference firebaseStorageRef =
            FirebaseStorage.instance.ref().child("blogImages").child(addId);
        final UploadTask task = firebaseStorageRef.putFile(selectedImage!);
        downloadUrl = await (await task).ref.getDownloadURL();
      } else {
        downloadUrl = widget.placeItem!["Image"];
      }

      bool success = await SourcePlace.update({
        "Image": downloadUrl,
        "Name": nameController.text.toLowerCase(),
        "Location": locationController.text,
        "Description": descriptionController.text,
        "Rate": rate,
        "JmlUlasan": int.parse(jmlUlasanController.text.replaceAll('.', '')),
        "Latitude": double.parse(latitudeController.text),
        "Longitude": double.parse(longitudeController.text),
        "Category": selectedCategory,
        "Harga": price,
        "Fasilitas": selectedFacilities,
        "id": widget.placeItem!['id']
      });

      if (success) {
        if (!mounted) return;
        DInfo.dialogSuccess(context, 'Success Update Place');
        DInfo.closeDialog(context, actionAfterClose: () {
          Navigator.pop(context, true);
        });
      } else {
        if (!mounted) return;
        DInfo.dialogError(context, "Failed Update Place");
        DInfo.closeDialog(context);
      }
    } catch (e) {
      // Tangani error jika ada
      DInfo.dialogError(context, "Error: $e");
      DInfo.closeDialog(context);
    }
  }

  @override
  void initState() {
    if (widget.placeItem != null) {
      selectedImageUrl = widget.placeItem!["Image"];
      nameController.text = widget.placeItem!["Name"];
      locationController.text = widget.placeItem!["Location"];
      descriptionController.text = widget.placeItem!["Description"];
      rateController.text = widget.placeItem!["Rate"].toString();
      jmlUlasanController.text = widget.placeItem!["JmlUlasan"].toString();
      latitudeController.text = widget.placeItem!["Latitude"].toString();
      longitudeController.text = widget.placeItem!["Longitude"].toString();
      selectedCategory = widget.placeItem!["Category"];
      selectedFacilities =
          List<String>.from(widget.placeItem!["Fasilitas"] ?? []);
      priceController.text = widget.placeItem!["Harga"] ?? "";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios_new_outlined,
              color: Color(0xFF373866),
            )),
        centerTitle: true,
        title: Text(
          widget.placeItem == null ? "Add Place" : "Update Place",
          style: AppWidget.headLineTextFeildStyle(),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(
              left: 20.0, right: 20.0, top: 20.0, bottom: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upload the Item Picture",
                style: AppWidget.semiBoldTextFeildStyle(),
              ),
              const SizedBox(height: 20.0),
              selectedImage == null
                  ? selectedImageUrl != null
                      ? Center(
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black, width: 1.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  selectedImageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () {
                            getImage();
                          },
                          child: Center(
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black, width: 1.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        )
                  : Center(
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 30.0),
              Text("Place Name", style: AppWidget.semiBoldTextFeildStyle()),
              const SizedBox(height: 10.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                    color: const Color(0xFFececf8),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter Place Name",
                      hintStyle: AppWidget.lightTextFeildStyle()),
                ),
              ),
              const SizedBox(height: 30.0),
              Text("Location", style: AppWidget.semiBoldTextFeildStyle()),
              const SizedBox(height: 10.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                    color: const Color(0xFFececf8),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter Location",
                      hintStyle: AppWidget.lightTextFeildStyle()),
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              Text(
                "Description",
                style: AppWidget.semiBoldTextFeildStyle(),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: const Color(0xFFececf8),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  maxLines: 6,
                  controller: descriptionController,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter Description",
                      hintStyle: AppWidget.lightTextFeildStyle()),
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              Text(
                "Rating",
                style: AppWidget.semiBoldTextFeildStyle(),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: const Color(0xFFececf8),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: rateController,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter Rating",
                      hintStyle: AppWidget.lightTextFeildStyle()),
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              Text(
                "Jumlah Ulasan",
                style: AppWidget.semiBoldTextFeildStyle(),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: const Color(0xFFececf8),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: jmlUlasanController,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter Jumlah Ulasan",
                      hintStyle: AppWidget.lightTextFeildStyle()),
                ),
              ),
              const SizedBox(
                height: 20.0,
              ),
              Text(
                "Select Category",
                style: AppWidget.semiBoldTextFeildStyle(),
              ),
              const SizedBox(
                height: 20.0,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: const Color(0xFFececf8),
                    borderRadius: BorderRadius.circular(10)),
                child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                  items: placeCategory
                      .map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(
                                fontSize: 18.0, color: Colors.black),
                          )))
                      .toList(),
                  onChanged: ((value) => setState(() {
                        selectedCategory = value;
                      })),
                  dropdownColor: Colors.white,
                  hint: const Text("Select Category"),
                  iconSize: 36,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                  ),
                  value: selectedCategory,
                )),
              ),
              const SizedBox(height: 30.0),
              Text("Price (IDR)", style: AppWidget.semiBoldTextFeildStyle()),
              const SizedBox(height: 10.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                    color: const Color(0xFFececf8),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter Price",
                      hintStyle: AppWidget.lightTextFeildStyle()),
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              Text(
                "Latitude",
                style: AppWidget.semiBoldTextFeildStyle(),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: const Color(0xFFececf8),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: latitudeController,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter Latitude",
                      hintStyle: AppWidget.lightTextFeildStyle()),
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              Text(
                "Longitude",
                style: AppWidget.semiBoldTextFeildStyle(),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: const Color(0xFFececf8),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: longitudeController,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter Longitude",
                      hintStyle: AppWidget.lightTextFeildStyle()),
                ),
              ),
              const SizedBox(
                height: 30.0,
              ),
              Text("Facilities", style: AppWidget.semiBoldTextFeildStyle()),
              const SizedBox(height: 10.0),
              Wrap(
                children: availableFacilities.map((facility) {
                  bool isSelected = selectedFacilities.contains(facility);
                  return ChoiceChip(
                    label: Text(facility),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        isSelected
                            ? selectedFacilities.remove(facility)
                            : selectedFacilities.add(facility);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 50.0),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onSubmit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          widget.placeItem == null
                              ? 'Add Place'
                              : 'Update Place',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
