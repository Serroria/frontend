import 'package:flutter/material.dart';
import '../widgets/card_recipe.dart';
import '../services/api_service.dart';
import '../models/recipe_model.dart';
import './detail_resep.dart';
import '../services/the_meal_db_service.dart';

class HalamanResep extends StatefulWidget {
  const HalamanResep({super.key});

  @override
  State<HalamanResep> createState() => _HalamanResepState();
}

class _HalamanResepState extends State<HalamanResep> {
  late Future<List<RecipeModel>> _futureRecipes;
  final ApiService apiService = ApiService();
  final TheMealDbService dbApiService = TheMealDbService();

  Set<int> _savedRecipeIds = {};
  // ✅ DUMMY USER ID: Ganti dengan ID user yang sebenarnya dari SharedPrefs
  final int _currentUserId = 1;

  @override
  void initState() {
    super.initState();
    // Panggil _loadSavedRecipes sebelum _fetchAndMergeRecipes
    _loadSavedRecipes();
    _futureRecipes = _fetchAndMergeRecipes();
  }

  // 👇 FUNGSI LENGKAP: Memuat ID Resep yang Disimpan
  Future<void> _loadSavedRecipes() async {
    // ASUMSI: Anda punya API endpoint yang mengembalikan LIST ID yang disimpan
    // API Service Anda harus memiliki metode seperti 'fetchSavedRecipeIds(userId)'
    // Untuk demo, kita set dummy ID
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      try {
        // Contoh: Mengambil ID dari API
        // final savedIds = await apiService.fetchSavedRecipeIds(_currentUserId);

        // Menggunakan data dummy untuk demonstrasi
        final savedIds = {52857, 101, 53049};

        setState(() {
          _savedRecipeIds = savedIds;
        });
        debugPrint('Resep yang disimpan dimuat: $_savedRecipeIds');
      } catch (e) {
        debugPrint('Gagal memuat resep yang disimpan: $e');
        // Biarkan _savedRecipeIds kosong jika gagal
      }
    }
  }
  // 👆 FUNGSI LENGKAP

  // 👇 FUNGSI LENGKAP: Menangani Tombol Simpan/Hapus Simpan
  void _handleSaveToggle(RecipeModel recipe) async {
    if (recipe.id == null || recipe.id == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID Resep tidak valid.')));
      return;
    }

    final isCurrentlySaved = _savedRecipeIds.contains(recipe.id);
    final recipeId = recipe.id!;

    // 1. Feedback UI cepat (Optimistic Update)
    setState(() {
      if (isCurrentlySaved) {
        _savedRecipeIds.remove(recipeId);
      } else {
        _savedRecipeIds.add(recipeId);
      }
    });

    // 2. Panggil API untuk Menyimpan/Menghapus
    try {
      if (isCurrentlySaved) {
        // Panggil API HAPUS
        await apiService.removeSavedRecipe(_currentUserId, recipeId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resep "${recipe.title}" dihapus dari simpanan.'),
          ),
        );
      } else {
        // Panggil API SIMPAN
        await apiService.saveRecipe(_currentUserId, recipeId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resep "${recipe.title}" berhasil disimpan!')),
        );
      }
    } catch (e) {
      // 3. Rollback UI jika API gagal (Pessimistic Update)
      if (mounted) {
        setState(() {
          if (isCurrentlySaved) {
            _savedRecipeIds.add(recipeId); // Tambahkan kembali jika gagal hapus
          } else {
            _savedRecipeIds.remove(recipeId); // Hapus kembali jika gagal simpan
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: $e')),
        );
      }
    }
  }
  // 👆 FUNGSI LENGKAP

  Future<List<RecipeModel>> _fetchAndMergeRecipes() async {
    List<RecipeModel> combinedRecipes = [];
    // Kita akan ambil semua resep lokal, dan beberapa resep dari TheMealDB
    // Contoh: Ambil resep dari kategori "Seafood" di TheMealDB

    try {
      final localRecipes = await apiService.fetchRecipes();
      combinedRecipes.addAll(localRecipes);
    } catch (e) {
      // 💡 Tampilkan peringatan, tapi JANGAN GAGAL TOTAL
      debugPrint('Peringatan: Gagal memuat resep lokal: $e');
    }

    // Panggilan API 2: Eksternal (TheMealDB)
    try {
      final externalRecipes = await dbApiService.fetchFilteredRecipes(
        'c',
        'Seafood',
      );
      combinedRecipes.addAll(externalRecipes);
    } catch (e) {
      // 💡 Tampilkan peringatan, tapi JANGAN GAGAL TOTAL
      debugPrint('Peringatan: Gagal memuat resep eksternal: $e');
    }

    // Jika kedua API gagal
    if (combinedRecipes.isEmpty) {
      throw Exception('Gagal memuat semua resep dari kedua sumber.');
    }

    // Gabungkan dan kembalikan resep yang berhasil dimuat
    return combinedRecipes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resep Praktis')),
      body: FutureBuilder<List<RecipeModel>>(
        // 💡 Menggunakan FutureBuilder
        future: _futureRecipes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}. Cek Koneksi CI4!'),
            );
          } else if (snapshot.hasData) {
            final List<RecipeModel> recipes = snapshot.data!;

            if (recipes.isEmpty) {
              return const Center(
                child: Text('Tidak ada data resep yang tersedia.'),
              );
            }
            return RefreshIndicator(
              // 💡 Tambahkan RefreshIndicator untuk memuat ulang data
              onRefresh: () async {
                setState(() {
                  // Muat ulang daftar resep dan status tersimpan
                  _futureRecipes = _fetchAndMergeRecipes();
                  _loadSavedRecipes();
                });
                await _futureRecipes; // Tunggu hingga selesai
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recipes.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    final isExternal = recipe.author == 'TheMealDB';
                    final isSaved = _savedRecipeIds.contains(
                      recipe.id,
                    ); // 💡 Cek status tersimpan

                    // Meneruskan data dari Model ke Partial Card
                    return GestureDetector(
                      onTap: () async {
                        if (isExternal) {
                          // Jika dari TheMealDB, fetch detail lengkap sebelum navigasi
                          final detail = await dbApiService.lookupMealDetail(
                            recipe.id.toString(),
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
                                content: Text(
                                  'Detail resep eksternal gagal dimuat',
                                ),
                              ),
                            );
                          }
                        } else {
                          // Jika resep lokal CI4, langsung navigasi (data sudah lengkap)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailResep(resep: recipe),
                            ),
                          );
                        }
                      },
                      child: RecipeCard(
                        imageUrl: recipe.image ?? '',
                        title: recipe.title,
                        kategori: recipe.kategori,
                        rating: recipe.rating.toString(),
                        difficulty: recipe.difficulty,
                        author: recipe.author,
                        // 💡 Tambahkan properti untuk menangani simpanan
                        isSaved: isSaved,
                        onSaveTapped: () =>
                            _handleSaveToggle(recipe), // 💡 Panggil handler
                      ),
                    );
                  },
                ),
              ),
            );
          }
          return const Center(child: Text('Memulai pengambilan data..'));
        },
      ),
    );
  }
}
