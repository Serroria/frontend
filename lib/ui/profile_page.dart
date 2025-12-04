import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Import untuk SharedPrefs
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
  final ApiService _api = ApiService(); // Digunakan untuk mendapatkan Base URL
  int? _userId;
  String _displayName = "Memuat...";
  String _handle = "@loading";
  int _totalRecipes = 0; // Akan diupdate oleh salah satu tab

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    // Di dunia nyata, Anda akan memanggil API profil dan SharedPrefs
    final prefs = await SharedPreferences.getInstance();
    // Asumsi ID user disimpan di SharedPrefs setelah login
    final fetchedUserId =
        prefs.getInt('userId') ?? 1; // Default ke ID 1 jika tidak ada

    // ASUMSI: Ambil data nama dan handle dari API /profile/{userId}
    // Untuk demo, kita set dummy
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      setState(() {
        _userId = fetchedUserId;
        _displayName = "Marsha Daviena";
        _handle = "@cook_180405000";
        // _totalRecipes akan diisi setelah tab resep selesai fetch
      });
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                );
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
            // HEADER PROFIL (foto + nama + total resep)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto profil
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.deepPurple,
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.white,
                    ),
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
                          _handle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Resep: $_totalRecipes",
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
                    userId: _userId, // ✅ Teruskan ID User
                    onCountUpdate: (count) {
                      // Callback untuk update total resep
                      setState(() => _totalRecipes = count);
                    },
                  ),
                  _ProfileRecipeTab(
                    emptyText: "Belum ada resep yang kamu simpan.",
                    isSavedRecipes: true,
                    userId: _userId, // ✅ Teruskan ID User
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
  final Function(int)? onCountUpdate; // Callback untuk update total resep

  const _ProfileRecipeTab({
    required this.emptyText,
    required this.isSavedRecipes,
    this.userId,
    this.onCountUpdate,
  });

  @override
  // Perbaiki typo "e" di _ProfileRecipeTabeState
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
    // Panggil fetch hanya jika userId sudah tersedia
    if (widget.userId != null) {
      _fetchRecipes();
    }
  }

  @override
  void didUpdateWidget(covariant _ProfileRecipeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Panggil fetch jika ID user baru tersedia (misal saat login selesai)
    if (widget.userId != oldWidget.userId && widget.userId != null) {
      _fetchRecipes();
    }
  }

  Future<void> _fetchRecipes() async {
    if (widget.userId == null) {
      if (mounted)
        setState(
          () => {_error = "User ID tidak ditemukan", _isLoading = false},
        );
      return;
    }

    try {
      List<RecipeModel> fetchedData = [];

      if (widget.isSavedRecipes) {
        final savedIds = await api.fetchSavedRecipeIds(widget.userId!);
        // ambil detail resep berdasarkan ID

        for (var id in savedIds) {
          final resep = await api.fetchUserRecipeById(id); // Buat fungsi baru
          if (resep != null) fetchedData.add(resep);
        }
      } else {
        // Ambil resep user langsung
        fetchedData = await api.fetchUserRecipes(widget.userId!);
      }

      if (mounted) {
        setState(() {
          _recipes = fetchedData;
          _isLoading = false;
          _error = null;
        });
        // Update total resep di ProfilePage
        if (!widget.isSavedRecipes && widget.onCountUpdate != null) {
          widget.onCountUpdate!(_recipes.length);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_recipes.isEmpty) {
      return Center(child: Text(widget.emptyText));
    }

    // Tampilan Grid untuk Resep
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        // ✅ SESUAIKAN ASPECT RATIO AGAR CARD MUAT VERTIKAL
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _recipes.length,
      itemBuilder: (context, index) {
        final resep = _recipes[index];

        // 1. Build URL Gambar
        String imageUrl = resep.image ?? '';
        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          // Ganti /uploads/receipes/ menjadi /uploads/recipes/ (perhatikan typo)
          imageUrl = '${api.baseUrl}/uploads/recipes/$imageUrl';
        } else if (imageUrl.isEmpty) {
          imageUrl = 'https://via.placeholder.com/200';
        }

        // ✅ NAVIGASI DAN CARD
        return GestureDetector(
          onTap: () {
            // Navigasi ke Detail Resep
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailResep(resep: resep),
              ),
            );
          },
          child: RecipeCard(
            imageUrl: imageUrl,
            title: resep.title,
            rating: resep.rating,
            kategori: resep.kategori,
            difficulty: resep.difficulty,
            author: resep.author,
          ),
        );
      },
    );
  }
}
