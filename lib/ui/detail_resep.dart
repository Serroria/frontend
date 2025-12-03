import 'package:flutter/material.dart';

class DetailResep extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String ingredients;
  final String steps;
  const DetailResep({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.deepOrange),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16.0)),
    );
  }
}
