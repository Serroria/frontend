import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  int _currentUserId = 1; // Default, akan diset dari SharedPreferences

  String _getRecipeImageUrl(RecipeModel recipe) {
    final isExternal = recipe.author == 'TheMealDB';
    String imageUrl = recipe.image ?? '';

    if (!isExternal && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      // Ini adalah resep lokal, tambahkan base URL CI4
      return '${apiService.baseUrl}/uploads/recipes/$imageUrl';
    } else if (imageUrl.isEmpty) {
      // Placeholder jika tidak ada gambar
      return 'https://via.placeholder.com/200x200?text=No+Image';
    }
    // Jika eksternal atau sudah berupa URL lengkap
    return imageUrl;
  }

  @override
  void initState() {
    super.initState();
    _futureRecipes = _fetchAndMergeRecipes();
    // Muat userId dari SharedPreferences terlebih dahulu
    _initializeUserId();
  }

  Future<void> _initializeUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId') ?? 1;
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
      // Setelah userId siap, load saved recipes dan fetch data
      await _loadSavedRecipes();
      if (mounted) {
        setState(() {
          _futureRecipes = _fetchAndMergeRecipes();
        });
      }
    }
  }

  // 👇 FUNGSI LENGKAP: Memuat ID Resep yang Disimpan dari API
  Future<void> _loadSavedRecipes() async {
    if (mounted) {
      try {
        // Ambil ID resep yang disimpan dari API
        // final savedIds = await apiService.fetchSavedRecipes(_currentUserId);
        // // Juga gabungkan dengan saved IDs lokal (fallback jika backend tidak menyimpan)
        // final prefs = await SharedPreferences.getInstance();
        // final localList = prefs.getStringList('local_saved_recipes') ?? [];
        // final localIds = localList
        //     .map((s) => int.tryParse(s) ?? 0)
        //     .where((i) => i != 0)
        //     .toSet();
        final List<RecipeModel> savedRecipes = await apiService
            .fetchSavedRecipes();
        final Set<int> savedIds = savedRecipes.map((r) => r.id).toSet();
        //  final merged = {...savedIds, ...localIds};
        final prefs = await SharedPreferences.getInstance();
        final localList = prefs.getStringList('local_saved_recipes') ?? [];
        final localIds = localList
            .map((s) => int.tryParse(s) ?? 0)
            .where((i) => i != 0)
            .toSet();
        final merged = {...savedIds, ...localIds};
        if (mounted) {
          setState(() {
            _savedRecipeIds = merged;
          });
        }
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
    final isExternal = recipe.author == 'TheMealDB';
    int recipeId = recipe.id;
    final isCurrentlySaved = _savedRecipeIds.contains(recipe.id);
    if (recipe.id == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID Resep tidak valid.')));
      return;
    }

    //final recipeId = recipe.id;

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
        //await apiService.removeSavedRecipe(_currentUserId, recipeId);
        await apiService.removeSavedRecipe(recipeId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resep "${recipe.title}" dihapus dari simpanan.'),
          ),
        );
        // Hapus juga dari penyimpanan lokal
        final prefs = await SharedPreferences.getInstance();
        final list = prefs.getStringList('local_saved_recipes') ?? [];
        list.remove(recipeId.toString());
        await prefs.setStringList('local_saved_recipes', list);
        debugPrint('DEBUG: local_saved_recipes after remove: $list');
      } else {
        if (isExternal) {
          // 2a. Jika resep eksternal, kita ambil detail lengkapnya dulu
          final externalId = recipeId.toString(); // ID TheMealDB
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mengambil detail resep eksternal...'),
            ),
          );
          final detailedRecipe = await dbApiService.lookupMealDetail(
            externalId,
          );

          if (detailedRecipe == null) {
            throw Exception('Gagal mendapatkan detail resep eksternal.');
          }

          // 2b. Simpan resep lengkap ke database lokal (CI4)
          final savedRecipe = await apiService.saveExternalRecipe(
            detailedRecipe,
          );

          // 2c. Ganti ID resep dengan ID lokal yang baru DIBUAT
          recipeId = savedRecipe.id;

          if (mounted) {
            setState(() {
              _savedRecipeIds.remove(recipe.id); // Hapus ID lama (TheMealDB)
              _savedRecipeIds.add(recipeId); // Tambahkan ID baru (CI4)
            });
          }
        } else {
          // Panggil API SIMPAN
          await apiService.saveRecipe(recipeId);
        }
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Resep "${recipe.title}" berhasil disimpan!')),

        // Simpan juga secara lokal sebagai fallback jika backend tidak expose saved list
        final prefs = await SharedPreferences.getInstance();
        final list = prefs.getStringList('local_saved_recipes') ?? [];
        if (!list.contains(recipeId.toString())) {
          list.add(recipeId.toString());
          await prefs.setStringList('local_saved_recipes', list);
        }
        debugPrint('DEBUG: local_saved_recipes after add: $list');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Resep "${recipe.title}" berhasil disimpan! (ID Baru: $recipeId)',
            ),
          ),
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
                    childAspectRatio: 0.6,
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
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailResep(resep: detail),
                              ),
                            );
                            // Setelah kembali, reload saved status
                            await _loadSavedRecipes();
                            if (mounted) {
                              setState(() {});
                            }
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
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailResep(resep: recipe),
                            ),
                          );
                          // Setelah kembali, reload saved status
                          await _loadSavedRecipes();
                          if (mounted) {
                            setState(() {});
                          }
                        }
                      },
                      child: RecipeCard(
                        imageUrl: _getRecipeImageUrl(recipe),
                        title: recipe.title,
                        kategori: recipe.kategori,
                        // rating: recipe.rating.toString(),
                        cookingTime: recipe.time,
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
