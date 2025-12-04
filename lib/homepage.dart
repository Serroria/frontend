import 'package:flutter/material.dart';
// Asumsikan file login_page.dart berada di direktori yang sama
import 'ui/login_page.dart';
import 'services/api_service.dart';

// Model Sederhana untuk Data Resep
class Recipe {
  final String title;
  final String imageUrl;

  Recipe({required this.title, required this.imageUrl});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _username; // akan diisi dari backend / SharedPreferences
  final ApiService _apiService = ApiService();

  // 📝 Daftar Resep Statis dengan URL Gambar yang Disesuaikan
  final List<Recipe> _allRecipes = [
    Recipe(
      title: "Ayam Bakar Padang",
      imageUrl: "https://example.com/images/ayam_bakar_padang.jpg",
    ), // Ganti dengan URL gambar Ayam Bakar Padang
    Recipe(
      title: "Mie Goreng Jawa",
      imageUrl: "https://example.com/images/mie_goreng_jawa.jpg",
    ), // Ganti dengan URL gambar Mie Goreng Jawa
    Recipe(
      title: "Rendang Daging",
      imageUrl: "https://example.com/images/rendang_daging.jpg",
    ), // Ganti dengan URL gambar Rendang Daging
    Recipe(
      title: "Klepon Gula Merah",
      imageUrl: "https://example.com/images/klepon_gula_merah.jpg",
    ), // Ganti dengan URL gambar Klepon
    Recipe(
      title: "Nasi Uduk Betawi",
      imageUrl: "https://example.com/images/nasi_uduk_betawi.jpg",
    ), // Ganti dengan URL gambar Nasi Uduk
    Recipe(
      title: "Kimchi Jjigae",
      imageUrl: "https://example.com/images/kimchi_jjigae.jpg",
    ), // Ganti dengan URL gambar Kimchi Jjigae
    Recipe(
      title: "Sate Lilit Bali",
      imageUrl: "https://example.com/images/sate_lilit_bali.jpg",
    ), // Contoh resep tambahan
    Recipe(
      title: "Spaghetti Carbonara",
      imageUrl: "https://example.com/images/spaghetti_carbonara.jpg",
    ), // Contoh resep tambahan
  ];

  // Fungsi untuk mendapatkan subset resep berdasarkan kategori/judul
  List<Recipe> _getRecipesForSection(String sectionTitle) {
    if (sectionTitle == "Cari Resep Terbaru") {
      // Ambil 1 resep terbaru
      return [_allRecipes.first];
    } else if (sectionTitle == "Resep Populer") {
      // Ambil 3 resep populer (misalnya: indeks 1, 2, 3)
      return _allRecipes.sublist(1, 4);
    } else if (sectionTitle == "Rekomendasi Untuk Kamu") {
      // Ambil 2 resep rekomendasi (misalnya: indeks 4 dan 5)
      return _allRecipes.sublist(4, 6);
    }
    return [];
  }

  // Fungsi untuk menangani logout dan navigasi ke halaman login
  void _handleLogout() {
    // Navigasi ke LoginPage dan menghapus semua rute sebelumnya
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final name = await _apiService.getUsername();
    if (!mounted) return;
    setState(() {
      _username = name ?? 'User';
    });
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
              "Halo, ${_username ?? 'User'}",
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.deepOrange),
            onPressed: _handleLogout, // Panggil fungsi logout
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
              "Temukan Resep Terbaik",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // 🔍 Search Bar
            TextField(
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

            // 📌 Bagian Resep Terbaru
            _buildRecipeSection("Cari Resep Terbaru"),
            const SizedBox(height: 20),

            // 📌 Bagian Resep Populer
            _buildRecipeSection("Resep Populer"),
            const SizedBox(height: 20),

            // 📌 Bagian Rekomendasi
            _buildRecipeSection("Rekomendasi Untuk Kamu"),
            const SizedBox(height: 20),
          ],
        ),
      ),

      // ⬇ Navbar Bawah
      // ... (jika ada)
    );
  }

  // 📦 Widget untuk membangun setiap bagian daftar resep
  Widget _buildRecipeSection(String title) {
    final recipes = _getRecipesForSection(title);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Menggunakan ListView.builder jika daftar resep panjang
        // Untuk saat ini menggunakan Column karena daftar pendek
        ...recipes.map((recipe) => _recipeCard(recipe)).toList(),
      ],
    );
  }

  Widget _categoryItem(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepOrange.shade50,
            child: Icon(icon, size: 28, color: Colors.deepOrange),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // ✅ Fungsi recipe card diubah untuk menerima objek Recipe
  Widget _recipeCard(Recipe recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            // Menggunakan URL gambar dari objek Recipe
            recipe.imageUrl,
            width: 55,
            height: 55,
            fit: BoxFit.cover,
            // 💡 Tambahkan placeholder saat gambar gagal dimuat (penting untuk network image)
            errorBuilder: (context, error, stackTrace) => Container(
              width: 55,
              height: 55,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
            // Opsional: placeholder loading
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 55,
                height: 55,
                color: Colors.grey.shade200,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.deepOrange,
                    ),
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
        // Menggunakan title dari objek Recipe
        title: Text(
          recipe.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text("Cocok untuk menu harian kamu"),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.deepOrange,
        ),
      ),
    );
  }
}
