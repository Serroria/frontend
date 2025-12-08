import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/recipe_model.dart';
import '../widgets/card_recipe.dart';
import 'edit_profile_page.dart';
import './detail_resep.dart';

// =======================================================
// A. MAIN PROFILE PAGE (STATEFUL)
// =======================================================

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int? _userId;
  String _displayName = "Memuat...";
  Uint8List? _profileImage;
  int _recipeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final fetchedUserId = prefs.getInt('userId') ?? 1;
    final username = prefs.getString('username') ?? 'User';
    final profileImageBase64 = prefs.getString('profile_image');

    Uint8List? imageBytes;
    if (profileImageBase64 != null && profileImageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(profileImageBase64);
      } catch (e) {
        print('Error decoding image: $e');
      }
    }

    if (mounted) {
      setState(() {
        _userId = fetchedUserId;
        _displayName = username;
        _profileImage = imageBytes;
        _recipeCount = 0; // default, akan diisi segera
      });
    }

    // Ambil jumlah resep milik user (jangan block UI)
    if (fetchedUserId != 0) {
      try {
        final api = ApiService();
        final list = await api.fetchMyRecipes();
        // final list = await api.fetchUserRecipes(fetchedUserId);
        if (mounted) {
          setState(() {
            _recipeCount = list.length;
          });
        }
      } catch (e) {
        // Biarkan _recipeCount tetap 0 jika gagal
        print('Error fetching recipe count: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Profil"),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          actions: [
            TextButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                );
                // Reload profile after returning from edit
                await _loadProfileData();
              },
              child: const Text(
                "Edit",
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER PROFIL
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.deepPurple,
                    backgroundImage: _profileImage != null
                        ? MemoryImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Text(
                            _displayName.isNotEmpty ? _displayName[0] : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "@${_displayName.toLowerCase().replaceAll(' ', '_')}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Resep: $_recipeCount",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // TAB BAR: Resep Saya | Resep Disimpan
            Material(
              color: Colors.white,
              child: TabBar(
                indicatorColor: Colors.deepOrange,
                labelColor: Colors.deepOrange,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                indicatorWeight: 2,
                tabs: const [
                  Tab(text: "Resep Saya"), // Perbaiki typo "!!!"
                  Tab(text: "Resep Disimpan"),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ISI TAB
            Expanded(
              child: TabBarView(
                children: [
                  _ProfileRecipeTab(
                    emptyText: "Belum ada resep yang kamu buat.",
                    isSavedRecipes: false,
                    userId: _userId,
                  ),
                  _ProfileRecipeTab(
                    emptyText: "Belum ada resep yang kamu simpan.",
                    isSavedRecipes: true,
                    userId: _userId,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// B. PROFILE RECIPE TAB (STATEFUL)
// =======================================================

class _ProfileRecipeTab extends StatefulWidget {
  final String emptyText;
  final bool isSavedRecipes;
  final int? userId;

  const _ProfileRecipeTab({
    required this.emptyText,
    required this.isSavedRecipes,
    this.userId,
  });

  @override
  State<_ProfileRecipeTab> createState() => _ProfileRecipeTabState();
}

class _ProfileRecipeTabState extends State<_ProfileRecipeTab> {
  final ApiService api = ApiService();
  List<RecipeModel> _recipes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      List<RecipeModel> fetchedData = [];

      if (widget.isSavedRecipes) {
        print('DEBUG: Fetching saved recipes');
        fetchedData = await api.fetchSavedRecipes();
      } else {
        print('DEBUG: Fetching my recipes');
        fetchedData = await api.fetchMyRecipes();
      }

      if (mounted) {
        setState(() {
          _recipes = fetchedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      print('DEBUG: Error fetching recipes: $e');
    }
  }

  // Refresh ketika kembali ke tab
  Future<void> _refresh() async {
    await _fetchRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: _refresh, child: _buildContent());
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchRecipes,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_recipes.isEmpty) {
      return Center(child: Text(widget.emptyText));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.63,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _recipes.length,
      itemBuilder: (context, index) {
        final resep = _recipes[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailResep(resep: resep),
              ),
            );
          },

          child: RecipeCard(
            recipeId: resep.id,
            imageUrl: resep.image ?? '',
            title: resep.title,
            cookingTime: resep.time,
            kategori: resep.kategori,
            difficulty: resep.difficulty,
            author: resep.author,
            isSaved: widget.isSavedRecipes,
            onSaveTapped: () async {
              if (widget.isSavedRecipes) {
                // Hapus dari saved recipes
                try {
                  await api.removeSavedRecipe(resep.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Resep dihapus dari simpanan'),
                    ),
                  );
                  await _fetchRecipes(); // Refresh list
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e')),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }
}
// class _ProfileRecipeTabState extends State<_ProfileRecipeTab> {
//   final ApiService api = ApiService();
//   List<RecipeModel> _recipes = [];
//   bool _isLoading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     // Panggil fetch hanya jika userId sudah tersedia
//     if (widget.userId != null) {
//       _fetchRecipes();
//     }
//   }

//   @override
//   void didUpdateWidget(covariant _ProfileRecipeTab oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Panggil fetch jika ID user baru tersedia (misal saat login selesai)
//     if (widget.userId != oldWidget.userId && widget.userId != null) {
//       _fetchRecipes();
//     }
//   }

//   Future<void> _fetchRecipes() async {
//     if (widget.userId == null || widget.userId == 0) {
//       if (mounted) {
//         setState(() {
//           _recipes = [];
//           _error = "Silakan login untuk melihat data ini.";
//           _isLoading = false;
//         });
//       }
//       return;
//     }

//     try {
//       List<RecipeModel> fetchedData = [];

//       if (widget.isSavedRecipes) {
//         // print('DEBUG: Fetching saved recipes for user ${widget.userId}');
//         // var savedIds = await api.fetchSavedRecipeIds(widget.userId!);
//         /// print('DEBUG: Saved recipe IDs (server): $savedIds');
//         print('DEBUG: Fetching saved recipes (secure endpoint)');
//         fetchedData = await api.fetchSavedRecipes();
//         // Selalu gabungkan dengan saved IDs lokal sebagai fallback dan "source of truth" sementara
//         // Hal ini memastikan aksi simpan yang dilakukan secara lokal langsung terlihat di tab Profil
//         // final prefs = await SharedPreferences.getInstance();
//         // final localList = prefs.getStringList('local_saved_recipes') ?? [];
//         // final localIds = localList
//         //     .map((s) => int.tryParse(s) ?? 0)
//         //     .where((i) => i != 0)
//         //     .toSet();
//         // if (localIds.isNotEmpty) {
//         //   print('DEBUG: Saved recipe IDs (local): $localIds');
//       } else {
//         // ✅ LOGIKA AMAN UNTUK RESEP SAYA
//         print('DEBUG: Fetching my own recipes (secure endpoint)');
//         fetchedData = await api.fetchMyRecipes();
//       }

//       // Gabungkan server + lokal (lokal menang jika ada duplikasi)
//       // savedIds = {...savedIds, ...localIds};
//       // print('DEBUG: Saved recipe IDs (merged): $savedIds');

//       // ambil detail resep berdasarkan ID
//       // Jika fetch detail gagal, tambahkan placeholder agar item tetap terlihat di UI
//       //   for (var id in savedIds) {
//       //     try {
//       //       final resep = await api.fetchSavedRecipes(id);
//       //       if (resep != null) {
//       //         fetchedData.add(resep);
//       //       } else {
//       //         // buat placeholder minimal sehingga resep yang disimpan tetap tampil
//       //         fetchedData.add(
//       //           RecipeModel(
//       //             id: id,
//       //             title: 'Resep (ID: $id)',
//       //             kategori: '-',
//       //             rating: '0',
//       //             ingredients: '',
//       //             steps: '',
//       //             description: '',
//       //             image: null,
//       //             time: '',
//       //             difficulty: '',
//       //             author: '-',
//       //           ),
//       //         );
//       //       }
//       //     } catch (e) {
//       //       print('DEBUG: Gagal fetch detail resep $id: $e');
//       //       // tambahkan placeholder jika terjadi error
//       //       fetchedData.add(
//       //         RecipeModel(
//       //           id: id,
//       //           title: 'Resep (ID: $id)',
//       //           kategori: '-',
//       //           rating: '0',
//       //           ingredients: '',
//       //           steps: '',
//       //           description: '',
//       //           image: null,
//       //           time: '',
//       //           difficulty: '',
//       //           author: '-',
//       //         ),
//       //       );
//       //     }
//       //   }
//       // } else {
//       //   // Ambil resep user langsung
//       //   fetchedData = await api.fetchMyRecipes();
//       //   // fetchedData = await api.fetchUserRecipes(widget.userId!);
//       // }

//       if (mounted) {
//         setState(() {
//           _recipes = fetchedData;
//           _isLoading = false;
//           // _error = null;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _error = e.toString();
//           _isLoading = false;
//         });
//       }
//       print('DEBUG: Error fetching recipes: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     if (_error != null) {
//       return Center(child: Text('Error: $_error'));
//     }
//     if (_recipes.isEmpty) {
//       return Center(child: Text(widget.emptyText));
//     }

//     // Tampilan Grid untuk Resep
//     return GridView.builder(
//       padding: const EdgeInsets.all(16),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         // ✅ SESUAIKAN ASPECT RATIO AGAR CARD MUAT VERTIKAL
//         childAspectRatio: 0.7,
//         crossAxisSpacing: 10,
//         mainAxisSpacing: 10,
//       ),
//       itemCount: _recipes.length,
//       itemBuilder: (context, index) {
//         final resep = _recipes[index];

//         // 1. Build URL Gambar
//         String imageUrl = resep.image ?? '';
//         if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
//           // Ganti /uploads/receipes/ menjadi /uploads/recipes/ (perhatikan typo)
//           imageUrl = '${api.baseUrl}/uploads/recipes/$imageUrl';
//         } else if (imageUrl.isEmpty) {
//           imageUrl = 'https://via.placeholder.com/200';
//         }

//         // ✅ NAVIGASI DAN CARD
//         return GestureDetector(
//           onTap: () async {
//             // Navigasi ke Detail Resep
//             await Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => DetailResep(resep: resep),
//               ),
//             );
//             // Setelah kembali dari detail, refresh recipes (jika tab disimpan)
//             if (widget.isSavedRecipes) {
//               await _fetchRecipes();
//             }
//           },
//           child: RecipeCard(
//             imageUrl: imageUrl,
//             title: resep.title,
//             // rating: resep.rating,
//             cookingTime: resep.time,
//             kategori: resep.kategori,
//             difficulty: resep.difficulty,
//             author: resep.author,

//             isSaved: widget.isSavedRecipes,

//             onSaveTapped: widget.isSavedRecipes
//                 ? () async {
//                     try {
//                       await api.removeSavedRecipe(resep.id);
//                       // Tampilkan pesan sukses ke pengguna (Opsional)
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text(
//                             'Resep berhasil dihapus dari simpanan!',
//                           ),
//                         ),
//                       );

//                       // Refresh daftar untuk menghapus item yang baru saja di-unbookmark
//                       await _fetchRecipes();
//                     } catch (e) {
//                       print('DEBUG: Gagal menghapus bookmark: $e');
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(
//                             'Gagal menghapus simpanan: ${e.toString()}',
//                           ),
//                         ),
//                       );
//                     }
//                   }
//                 : null,
//           ),
//         );
//       },
//     );
//   }
// }
