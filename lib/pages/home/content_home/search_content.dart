import 'package:flutter/material.dart';
import '../../../widget/widget_color.dart';

class SearchContent extends StatelessWidget {
  final TextEditingController controllerSearch;
  final Function(String) search;

  const SearchContent({
    super.key,
    required this.controllerSearch,
    required this.search,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Material(
        elevation: 5.0,
        borderRadius: BorderRadius.circular(8),
        child: TextField(
          controller: controllerSearch,
          style: const TextStyle(color: Colors.grey),
          onChanged: search, // Setiap perubahan input akan memanggil search
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            filled: true,
            fillColor: const Color.fromARGB(255, 255, 255, 255),
            hintText: 'Search',
            hintStyle: const TextStyle(color: Colors.grey),
            suffixIcon: Container(
              decoration: BoxDecoration(
                color: WidgetColor.semiHeadColor(),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: const Icon(
                Icons.search,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
