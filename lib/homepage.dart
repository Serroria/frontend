import 'package:flutter/material.dart';
import 'package:uasmoba/services/api_service.dart';
import 'package:uasmoba/services/the_meal_db_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uasmoba/models/recipe_model.dart'; // Tambahkan import model RecipeModel
// Asumsikan file login_page.dart berada di direktori yang sama
import 'ui/login_page.dart';
import 'ui/detail_resep.dart'; // Import DetailResep widget
// ✅ TAMBAHKAN IMPORT INI
import 'ui/search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService api = ApiService();
  final TheMealDbService dbApi = TheMealDbService();
  final TextEditingController _searchController = TextEditingController();

  List<RecipeModel> _recommendations = []; //dari TheMealDb
  List<RecipeModel> _localNewRecipes = []; //dari lokal CI4
  bool _isLoading = true;
  String? _error;
  String _username = "User"; // Akan diisi dari SharedPreferences

  String _selectedCategory = 'Dessert';

  //mapping kategori lokal ke kategori THemealdb
  final Map<String, String> _categoryMap = {
    'Nusantara': 'Chicken',
    'Asia': 'Seafood',
    'Internasional': 'Beef',
    'Vegan': 'Vegetarian',
    'Dessert': 'Dessert',
  };

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _fetchHomeData();
  }

  Future<void> _loadUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username') ?? 'User';
      if (mounted) {
        setState(() {
          _username = username;
        });
      }
    } catch (e) {
      print('Error loading username: $e');
      if (mounted) {
        setState(() {
          _username = 'User';
        });
      }
    }
  }

  // Fungsi untuk menangani logout dan navigasi ke halaman login
  void _handleLogout() {
    // Navigasi ke LoginPage dan menghapus semua rute sebelumnya
    // Ini memastikan user tidak bisa kembali ke HomePage setelah logout
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _onCategoryTap(String categoryTitle) {
    if (_selectedCategory != categoryTitle) {
      setState(() {
        _selectedCategory = categoryTitle;
        _isLoading = true;
        _error = null;
      });
      _fetchHomeData();
    }
  }

  Future<void> _fetchHomeData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final mealDbCategory = _categoryMap[_selectedCategory] ?? 'Dessert';
    List<RecipeModel> recommendations = [];
    List<RecipeModel> localFiltered = [];
    String? tempError;

    // 1. Ambil data rekomendasi (Eksternal)
    try {
      recommendations = await dbApi.fetchFilteredRecipes('c', mealDbCategory);
    } catch (e) {
      tempError = 'Gagal memuat rekomendasi TheMealDB: $e';
      debugPrint(tempError);
    }

    // 2. Ambil data resep lokal terbaru (CI4)
    try {
      // Gunakan fetchRecipes() yang fetch semua resep lokal
      // atau fallback ke kategori filter jika ada
      localFiltered = await api.fetchRecipes();
    } catch (e) {
      tempError = (tempError ?? '') + '\nGagal memuat resep lokal: $e';
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() {
        _recommendations = recommendations;
        // Perbarui _localNewRecipes dengan hasil filter
        _localNewRecipes = localFiltered;
        _isLoading = false;
        // Tetapkan error HANYA JIKA TIDAK ADA DATA SAMA SEKALI
        if (recommendations.isEmpty && localFiltered.isEmpty) {
          _error = tempError ?? 'Gagal memuat data resep.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Halo, $_username",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Mau masak apa hari ini?",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        // **START: PERUBAHAN UNTUK TOMBOL LOGOUT**
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.deepOrange),
            onPressed: _handleLogout, // Panggil fungsi logout
            tooltip: "Logout",
          ),
          const SizedBox(width: 8),
        ],
        // **END: PERUBAHAN UNTUK TOMBOL LOGOUT**
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Mau masak apa hari ini",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // 🔍 Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Coba cari resep...",
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Navigasi ke SearchPage dan kirimkan kata kunci
                      builder: (context) => SearchPage(initialQuery: query),
                    ),
                  );
                  // Opsional: kosongkan field setelah pencarian
                  _searchController.clear();
                }
              },
            ),

            const SizedBox(height: 20),

            // 🍲 Kategori
            const Text(
              "Kategori Resep",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _categoryItem("Nusantara", Icons.ramen_dining),
                  _categoryItem("Asia", Icons.set_meal),
                  _categoryItem("Internasional", Icons.public),
                  _categoryItem("Vegan", Icons.eco),
                  _categoryItem("Dessert", Icons.icecream),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 📌 Card Resep 1
            // const Text(
            //   "Cari Resep Terbaru",
            //   style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 12),
            // _recipeCard("Ayam Bakar Padang", 101),
            // const SizedBox(height: 20),

            //dianmis card utama
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text('Gagal memuat data: $_error'))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. Resep Terbaru (dari API Lokal CI4) ---
                  const Text(
                    "Cari Resep Terbaru (Lokal)",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_localNewRecipes.isEmpty)
                    const Text('Belum ada resep lokal terbaru.'),
                  // Loop data terbaru
                  ..._localNewRecipes.map((r) => _buildRecipeCard(r)).toList(),

                  const SizedBox(height: 20),

                  // --- 2. Resep Populer/Rekomendasi (dari TheMealDB) ---
                  Text(
                    "Rekomendasi Resep Populer: $_selectedCategory",
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_recommendations.isEmpty)
                    const Text('Gagal memuat resep rekomendasi.'),
                  // Loop data rekomendasi
                  ..._recommendations.map((r) => _buildRecipeCard(r)).toList(),

                  const SizedBox(height: 20),
                ],
              ),

            //   // 📌 Card Resep 2
            //   const Text(
            //     "Resep Populer",
            //     style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            //   ),
            //   const SizedBox(height: 12),
            //   _recipeCard("Mie Goreng Jawa", 250),
            //   _recipeCard("Rendang Daging", 244),
            //   _recipeCard("Klepon Gula Merah", 108),

            //   const SizedBox(height: 20),

            //   // 📌 Card Resep 3
            //   const Text(
            //     "Rekomendasi Untuk Kamu",
            //     style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            //   ),
            //   const SizedBox(height: 12),
            //   _recipeCard("Nasi Uduk Betawi", 209),
            //   _recipeCard("Kimchi Jjigae", 210),
            // ],
          ],
        ),
      ),

      // ⬇ Navbar Bawah
    );
  }

  Widget _categoryItem(String title, IconData icon) {
    final isActive = _selectedCategory == title;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _onCategoryTap(title),

        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isActive
                  ? Colors.deepOrange
                  : Colors.deepOrange.shade50,
              child: Icon(
                icon,
                size: 28,
                color: isActive ? Colors.white : Colors.deepOrange,
              ),
            ),

            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(RecipeModel resep) {
    // Cek apakah ini data lokal atau TheMealDB
    final isLocal = resep.author != 'TheMealDB';

    String imageUrl = resep.image ?? 'https://picsum.photos/200';

    // Jika lokal dan hanya nama file, bangun URL lengkap
    if (isLocal && !imageUrl.startsWith('http')) {
      // Pastikan resep.image TIDAK kosong
      if (resep.image != null && resep.image!.isNotEmpty) {
        // Periksa dan perbaiki jika image hanya nama file
        imageUrl = '${api.baseUrl}/uploads/recipes/${resep.image}';
      } else {
        // Atur URL ke placeholder jika gambar lokal kosong
        imageUrl = 'https://via.placeholder.com/200?text=No+Image';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          // Jika resep dari TheMealDB (hanya punya ID dan nama),
          // kita harus Lakukan Lookup Detail lagi sebelum navigasi.
          if (!isLocal) {
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
                const SnackBar(content: Text('Gagal memuat detail resep')),
              );
            }
          } else {
            // Jika resep lokal CI4 (sudah lengkap), langsung navigasi
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailResep(resep: resep),
              ),
            );
          }
        },
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 55,
              height: 55,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(resep.title),
          subtitle: Text(
            isLocal ? resep.kategori : 'External | Kategori: ${resep.kategori}',
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
}
