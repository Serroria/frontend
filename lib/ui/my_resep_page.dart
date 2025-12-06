// lib/ui/my_resep_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/recipe_model.dart';
import '../widgets/card_recipe.dart';
import 'tambah_resep_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/detail_resep.dart';

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
  // int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  Future<void> _loadUserAndFetch() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Cek token secara eksplisit

    if (token == null) {
      if (!mounted) return;
      setState(() {
        _error = 'Anda harus login untuk melihat resep Anda.'; // Pesan khusus
        _loading = false;
      });
      return; // Stop jika tidak ada token
    }
    try {
      List<RecipeModel> data = await api.fetchMyRecipes();

      // final prefs = await SharedPreferences.getInstance();
      // final uid = prefs.getInt('userId');
      // _userId = uid;

      // List<RecipeModel> data = uid != null
      //     ? await api.fetchUserRecipes(uid)
      //     : await api.fetchRecipes();

      if (!mounted) return;
      setState(() {
        _myRecipes = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
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

    if (result == true) {
      await _loadUserAndFetch();
    }
  }

  void _navigateToDetailResep(RecipeModel resep) {
    String finalImageUrl = resep.image ?? '';
    if (finalImageUrl.isNotEmpty && !finalImageUrl.startsWith('http')) {
      finalImageUrl = '${api.baseUrl}/uploads/recipes/${finalImageUrl}';
    }

    final resepFinal = RecipeModel(
      id: resep.id,
      title: resep.title,
      kategori: resep.kategori,
      rating: resep.rating,
      ingredients: resep.ingredients,
      steps: resep.steps,
      description: resep.description,
      image: finalImageUrl, // Kirim URL gambar yang sudah lengkap
      time: resep.time,
      difficulty: resep.difficulty,
      author: resep.author,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetailResep(resep: resepFinal)),
    );
  }

  void _navigateToEditResep(RecipeModel resep) async {
    final result = await Navigator.push(
      context,
      // Asumsi TambahResepPage dimodifikasi untuk menerima data edit
      MaterialPageRoute(
        builder: (context) => TambahResepPage(recipeToEdit: resep),
      ),
    );

    if (result == true) {
      await _loadUserAndFetch(); // Refresh setelah edit
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

    // Tampilkan loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    try {
      print('DEBUG: Deleting recipe ID: $id');
      final ok = await api.deleteRecipe(id);

      if (mounted) {
        Navigator.pop(context); // close loading dialog
      }

      if (!mounted) return;

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
      if (mounted) {
        Navigator.pop(context); // close loading dialog
      }

      if (!mounted) return;

      print('DEBUG: Delete Error: $e');
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

      // --- BODY ---
      body: RefreshIndicator(
        onRefresh: _loadUserAndFetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            // Error state
            : _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Terjadi kesalahan: $_error',
                          textAlign: TextAlign.center,
                        ),
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
            // Empty state
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
            // List data
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _myRecipes.length,
                itemBuilder: (context, index) {
                  final r = _myRecipes[index];

                  // --- Build image url ---
                  String imageUrl = r.image ?? '';
                  if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                    imageUrl = '${api.baseUrl}/uploads/recipes/$imageUrl';
                  } else if (imageUrl.isEmpty) {
                    imageUrl = 'https://picsum.photos/200';
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        _navigateToDetailResep(r);
                      },
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
                            final r = _myRecipes[index];
                            if (val == 'edit') {
                              _navigateToEditResep(r);
                            } else if (val == 'delete') {
                              await _deleteRecipe(r.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
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
