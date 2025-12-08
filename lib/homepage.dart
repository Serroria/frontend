import 'package:flutter/material.dart';
import 'package:uasmoba/services/api_service.dart';
import 'package:uasmoba/services/the_meal_db_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uasmoba/models/recipe_model.dart';
import 'ui/login_page.dart';
import 'ui/detail_resep.dart';
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

  List<RecipeModel> _recommendations = [];
  List<RecipeModel> _localNewRecipes = [];
  bool _isLoading = true;
  String? _error;
  String _username = "User";

  String _selectedCategory = 'All';

  final Map<String, String> _categoryMap = {
    'All': 'Seafood',
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

  // ✅ TAMBAHKAN FUNGSI DEBUG INI
  Future<void> _showDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('userId');
    final username = prefs.getString('username');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🛠️ Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _debugItem('Token ditemukan', token != null ? '✅' : '❌'),
              _debugItem('Panjang Token', '${token?.length ?? 0} karakter'),
              _debugItem('User ID', userId?.toString() ?? 'null'),
              _debugItem('Username', username ?? 'null'),
              const SizedBox(height: 10),
              if (token != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Token Preview:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SelectableText(
                      token!.substring(
                        0,
                        token.length > 30 ? 30 : token.length,
                      ),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () async {
              await prefs.remove('token');
              await prefs.remove('userId');
              await prefs.remove('username');
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Token dihapus!')));
              if (mounted) {
                setState(() {
                  _username = 'User';
                });
              }
            },
            child: const Text(
              'Hapus Token',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _debugItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _handleLogout() {
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

    final mealDbCategory = _categoryMap[_selectedCategory] ?? 'Seafood';
    List<RecipeModel> recommendations = [];
    List<RecipeModel> localFiltered = [];
    String? tempError;

    try {
      if (_selectedCategory == 'All') {
        //recommendations = await dbApi.fetchPopularRecipesCI4();
        recommendations = await dbApi.fetchFilteredRecipes(
          'c',
          'Random',
        ); // Asumsi TheMealDB bisa filter 'Random'
        // JIKA TIDAK ADA, ambil kategori default saja, misal 'Seafood'
        recommendations = await dbApi.fetchFilteredRecipes('c', 'Seafood');
      } else {
        recommendations = await dbApi.fetchFilteredRecipes('c', mealDbCategory);
      }
    } catch (e) {
      tempError = 'Gagal memuat rekomendasi TheMealDB: $e';
      debugPrint(tempError);
    }

    try {
      if (_selectedCategory == 'All') {
        // ✅ LOGIC UNTUK 'ALL'
        localFiltered = await api.fetchRecipes(); // <-- Ambil semua resep lokal
      } else {
        localFiltered = await api.fetchFilteredLocalRecipes(_selectedCategory);
      }
    } catch (e) {
      tempError = (tempError ?? '') + '\nGagal memuat resep lokal: $e';
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() {
        _recommendations = recommendations;
        _localNewRecipes = localFiltered;
        _isLoading = false;
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
        // ✅ MODIFIKASI ACTIONS: TAMBAHKAN TOMBOL DEBUG SEBELUM LOGOUT
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.blue),
            onPressed: _showDebugInfo, // ← FUNGSI DEBUG BARU
            tooltip: "Debug Token",
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.deepOrange),
            onPressed: _handleLogout,
            tooltip: "Logout",
          ),
          const SizedBox(width: 8),
        ],
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
                      builder: (context) => SearchPage(initialQuery: query),
                    ),
                  );
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
                  _categoryItem("All", Icons.view_comfortable),
                  _categoryItem("Nusantara", Icons.ramen_dining),
                  _categoryItem("Asia", Icons.set_meal),
                  _categoryItem("Internasional", Icons.public),
                  _categoryItem("Vegan", Icons.eco),
                  _categoryItem("Dessert", Icons.icecream),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Konten utama
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text('Gagal memuat data: $_error'))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resep Lokal
                  const Text(
                    "Cari Resep Terbaru (Lokal)",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_localNewRecipes.isEmpty)
                    const Text('Belum ada resep lokal terbaru.'),
                  ..._localNewRecipes.map((r) => _buildRecipeCard(r)).toList(),

                  const SizedBox(height: 20),

                  // Resep TheMealDB
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
                  ..._recommendations.map((r) => _buildRecipeCard(r)).toList(),

                  const SizedBox(height: 20),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryItem(String title, IconData icon) {
    final isActive = _selectedCategory == title;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => _onCategoryTap(title),
        child: Column(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: isActive
                  ? Colors.deepOrange
                  : Colors.deepOrange.shade50,
              child: Icon(
                icon,
                size: 20,
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
    final isLocal = resep.author != 'TheMealDB';

    String imageUrl = resep.image ?? 'https://picsum.photos/200';

    if (isLocal && !imageUrl.startsWith('http')) {
      if (resep.image != null && resep.image!.isNotEmpty) {
        imageUrl = '${api.baseUrl}/uploads/recipes/${resep.image}';
      } else {
        imageUrl = 'https://via.placeholder.com/200?text=No+Image';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
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
