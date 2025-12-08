// lib/ui/search_page.dart

import 'package:flutter/material.dart';
import 'package:uasmoba/widgets/card_recipe.dart';
import '../services/the_meal_db_service.dart';
import '../models/recipe_model.dart';
import 'detail_resep.dart'; // Import halaman detail
import '../services/api_service.dart';

class SearchPage extends StatefulWidget {
  final String initialQuery;

  const SearchPage({super.key, required this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ApiService api = ApiService();
  final TheMealDbService dbApi = TheMealDbService();
  List<RecipeModel> _searchResults = [];
  bool _isLoading = true;
  String? _error;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _performSearch(widget.initialQuery);
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    List<RecipeModel> localResults = [];
    List<RecipeModel> externalResults = [];
    String? tempError; // Untuk mencatat error
    try {
      // 1. Panggil API Lokal (CI4)
      localResults = await api.searchLocalRecipes(query);
    } catch (e) {
      tempError = 'Gagal memuat resep lokal: $e';
      debugPrint(tempError);
    }

    // 2. Panggil API Eksternal (TheMealDB)
    try {
      // 💡 CATATAN: Anda belum mengimplementasikan dbApi.searchMeals(query)
      // Gunakan fungsi searchMealsByName yang sudah Anda buat
      // Cek kode TheMealDbService, Future searchMeals(String query) async {}
      // Hapus fungsi searchMeals yang kosong dan ganti panggilannya di sini:
      externalResults = await dbApi.searchMealsByName(query);
    } catch (e) {
      tempError = (tempError ?? '') + '\nGagal memuat resep eksternal: $e';
      debugPrint(e.toString());
    }

    // Gabungkan hasilnya
    final combinedResults = [...localResults, ...externalResults];

    if (mounted) {
      setState(() {
        _searchResults = combinedResults;
        _isLoading = false;
        // Tampilkan error hanya jika TIDAK ADA data sama sekali
        if (combinedResults.isEmpty && tempError != null) {
          _error = tempError;
        } else {
          _error = null;
        }
      });
    }
  }

  // Widget untuk menampilkan tiap resep di hasil pencarian
  Widget _buildSearchResultCard(RecipeModel resep) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          // Karena data hasil search sudah cukup lengkap, kita bisa langsung navigasi.
          // (Atau jika butuh detail lengkap, panggil lookupMealDetail lagi seperti di HomePage)
          final detail = await dbApi.lookupMealDetail(resep.id.toString());
          if (detail != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailResep(resep: detail),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Detail resep gagal dimuat')),
            );
          }
        },
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              resep.image ?? 'https://picsum.photos/55',
              width: 55,
              height: 55,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            resep.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Kategori: ${resep.kategori} | Area: ${resep.description}',
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.deepOrange,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true, // Fokuskan kursor saat masuk halaman
          decoration: InputDecoration(
            hintText: "Cari resep...",
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (value) =>
              _performSearch(value), // Lakukan pencarian saat tekan enter
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hasil Pencarian",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // --- Loading State ---
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            // --- Error State ---
            else if (_error != null)
              Expanded(child: Center(child: Text('Error: $_error')))
            // --- Empty State ---
            else if (_searchResults.isEmpty)
              const Expanded(
                child: Center(child: Text('Resep tidak ditemukan.')),
              )
            // --- Data State ---
            else
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Dua kolom
                    childAspectRatio:
                        0.63, // Sesuaikan rasio agar pas (tinggi lebih panjang dari lebar)
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final resep = _searchResults[index];
                    final isLocal = resep.author != 'TheMealDB';

                    // Buat URL gambar lengkap (jika perlu)
                    String imageUrl = resep.image ?? '';

                    if (isLocal &&
                        imageUrl.isNotEmpty &&
                        !imageUrl.startsWith('http')) {
                      // Diperlukan akses ke ApiService untuk mendapatkan BaseUrl
                      // Pastikan 'api' (ApiService) sudah diinisialisasi di State class Anda
                      imageUrl = '${api.baseUrl}/uploads/recipes/$imageUrl';
                    }

                    // Jaga-jaga jika masih kosong
                    if (imageUrl.isEmpty) {
                      imageUrl =
                          'https://via.placeholder.com/200x200?text=No+Image';
                    }

                    // ✅ BUNGKUS DENGAN INKWELL UNTUK MENGAKTIFKAN KLIK
                    return InkWell(
                      onTap: () async {
                        if (isLocal) {
                          // ✅ RESEP LOKAL: Langsung navigasi, data sudah lengkap
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailResep(resep: resep),
                            ),
                          );
                        } else {
                          // ✅ RESEP EKSTERNAL: Lakukan Lookup Detail
                          final detail = await dbApi.lookupMealDetail(
                            resep.id.toString(),
                          );
                          if (detail != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailResep(resep: detail),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Detail resep gagal dimuat'),
                              ),
                            );
                          }
                        }
                      },
                      // ✅ PANGGIL WIDGET RECIPECARD
                      child: RecipeCard(
                        imageUrl: imageUrl,
                        title: resep.title,
                        // rating: resep
                        //     .rating, // Atau rating dari model (misalnya '4.5')
                        cookingTime: resep.time,
                        kategori: resep.kategori,
                        difficulty: resep.difficulty,
                        author: resep.author,
                        // steps: 0, // Hapus jika di RecipeCard Anda dihapus
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
