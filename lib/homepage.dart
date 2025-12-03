import 'package:flutter/material.dart';
// Asumsikan file login_page.dart berada di direktori yang sama
import 'ui/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _username = "User"; // Nanti diganti saat login dari backend

  // Fungsi untuk menangani logout dan navigasi ke halaman login
  void _handleLogout() {
    // Navigasi ke LoginPage dan menghapus semua rute sebelumnya
    // Ini memastikan user tidak bisa kembali ke HomePage setelah logout
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
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

            // 📌 Card Resep 1
            const Text(
              "Cari Resep Terbaru",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _recipeCard("Ayam Bakar Padang", 101),
            const SizedBox(height: 20),

            // 📌 Card Resep 2
            const Text(
              "Resep Populer",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _recipeCard("Mie Goreng Jawa", 250),
            _recipeCard("Rendang Daging", 244),
            _recipeCard("Klepon Gula Merah", 108),

            const SizedBox(height: 20),

            // 📌 Card Resep 3
            const Text(
              "Rekomendasi Untuk Kamu",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _recipeCard("Nasi Uduk Betawi", 209),
            _recipeCard("Kimchi Jjigae", 210),
          ],
        ),
      ),

      // ⬇ Navbar Bawah
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

  // ✅ Kita pertahankan 1 function recipe card
  Widget _recipeCard(String title, int id) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            "https://picsum.photos/id/$id/200",
            width: 55,
            height: 55,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
