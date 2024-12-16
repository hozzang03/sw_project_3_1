import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  final Function(String) onSearch;

  const SearchBar({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onSubmitted: onSearch,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: "검색",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }
}
