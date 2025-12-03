// lib/ui/my_resep_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recipe_model.dart';
import '../widgets/card_recipe.dart';
import 'tambah_resep_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyResepPage extends StatefulWidget {
  const MyResepPage({super.key});

  @override
  State<MyResepPage> createState() => _MyResepPageState();
}

class _MyResepPageState extends State<MyResepPage> {
  final ApiService api = ApiService();
  List<RecipeModel> _myRecipes = [];
  bool _loading = true;
  String? _error;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  Future<void> _loadUserAndFetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('userId'); // pastikan login menyimpan userId
      List<RecipeModel> data;
      if (_userId != null) {
        data = await api.fetchUserRecipes(_userId!);
      } else {
        // fallback ambil semua
        data = await api.fetchRecipes();
      }

      setState(() {
        _myRecipes = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _navigateToTambahResep() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TambahResepPage()),
    );

    // jika TambahResepPage mengembalikan true/nilai sukses, refetch
    if (result == true) {
      await _loadUserAndFetch();
    }
  }

  Future<void> _deleteRecipe(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Resep'),
        content: const Text('Apakah Anda yakin ingin menghapus resep ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // coba hapus via API
    try {
      final ok = await api.deleteRecipe(id);
      if (ok) {
        setState(() {
          _myRecipes.removeWhere((r) => r.id == id);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Resep dihapus')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menghapus resep')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resep Saya'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.deepOrange),
            onPressed: _navigateToTambahResep,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserAndFetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                // wrap supaya pull-to-refresh tetap bekerja
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text('Terjadi kesalahan: $_error'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadUserAndFetch,
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _myRecipes.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 20),
                          const Text('Belum ada resep'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _navigateToTambahResep,
                            child: const Text('Tambah Resep'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _myRecipes.length,
                itemBuilder: (context, index) {
                  final r = _myRecipes[index];

                  // Bangun imageUrl: jika image hanya nama file, gabungkan base url
                  String imageUrl = r.image ?? '';
                  if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                    imageUrl = '${api.baseUrl}/uploads/recipes/$imageUrl';
                  } else if (imageUrl.isEmpty) {
                    imageUrl = 'https://picsum.photos/200'; // fallback
                  }

                  return GestureDetector(
                    onTap: () {
                      // TODO: buka detail halaman resep
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          r.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          r.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) async {
                            if (val == 'edit') {
                              // TODO: navigasi edit
                            } else if (val == 'delete') {
                              await _deleteRecipe(r.id);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToTambahResep,
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
