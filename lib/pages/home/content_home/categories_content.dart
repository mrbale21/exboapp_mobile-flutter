import 'package:flutter/material.dart';
import '../../../widget/widget_color.dart';
import '../../../widget/widget_support.dart'; // Ganti dengan path yang sesuai

class CategoriesContent extends StatelessWidget {
  final Function getPlace;
  final Function category;
  final bool allCategory;
  final bool tamanHiburan;
  final bool kuliner;
  final bool cagarAlam;
  final Function onCategoryChange; // Tambahkan fungsi untuk mengubah kategori

  const CategoriesContent({
    super.key,
    required this.getPlace,
    required this.category,
    required this.allCategory,
    required this.tamanHiburan,
    required this.kuliner,
    required this.cagarAlam,
    required this.onCategoryChange, // Tambahkan parameter ini
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildCategory(
          imagePath: "assets/images/all_categories.png",
          label: 'Semua',
          isActive: allCategory,
          onTap: () async {
            onCategoryChange(true, false, false,
                false); // Panggil fungsi untuk mengubah kategori
            await getPlace();
          },
        ),
        buildCategory(
          imagePath: "assets/images/taman_hiburan.png",
          label: 'Hiburan',
          isActive: tamanHiburan,
          onTap: () async {
            onCategoryChange(false, true, false, false);
            await category("Taman Hiburan");
          },
        ),
        buildCategory(
          imagePath: "assets/images/kuliner.png",
          label: 'Kuliner',
          isActive: kuliner,
          onTap: () async {
            onCategoryChange(false, false, true, false);
            await category("Kuliner");
          },
        ),
        buildCategory(
          imagePath: "assets/images/cagar_alam.png",
          label: 'Alam',
          isActive: cagarAlam,
          onTap: () async {
            onCategoryChange(false, false, false, true);
            await category("Cagar Alam");
          },
        ),
      ],
    );
  }

  Widget buildCategory({
    required String imagePath,
    required String label,
    required bool isActive,
    required Function onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => onTap(),
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color:
                        isActive ? WidgetColor.semiHeadColor() : Colors.white,
                    width: 2),
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(2),
              child: Image.asset(
                imagePath,
                height: 55,
                width: 55,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: AppWidget.semiLightTextFeildStyle(),
        ),
      ],
    );
  }
}
