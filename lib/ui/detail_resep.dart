import 'package:flutter/material.dart';
import '../models/recipe_model.dart';

class DetailResep extends StatelessWidget {
  final RecipeModel resep;

  const DetailResep({super.key, required this.resep});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(resep.title),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resep.image != null && resep.image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  resep.image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(child: Text('Gagal Memuat Ga,bar')),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

            Text(
              'Kategori: ${resep.kategori} | Waktu: ${resep.time}menit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              'Deskripsi:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(resep.description),
            const SizedBox(height: 20),
            const Text(
              'Bahan-bahan:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(resep.ingredients),
            const SizedBox(height: 20),
            const Text(
              'Langkah-langkah:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(resep.steps),
          ],
        ),
      ),
    );
  }
}
