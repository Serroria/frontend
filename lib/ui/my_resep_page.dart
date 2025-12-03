// lib/ui/my_resep_page.dart
import 'package:flutter/material.dart';
import 'tambah_resep_page.dart';

class MyResepPage extends StatefulWidget {
  const MyResepPage({super.key});

  @override
  State<MyResepPage> createState() => _MyResepPageState();
}

class _MyResepPageState extends State<MyResepPage> {
  // Dummy data resep yang dibuat sendiri
  final List<Map<String, dynamic>> _myRecipes = [
    {
      'id': 1,
      'title': 'Nasi Goreng Spesial',
      'description': 'Nasi goreng dengan bumbu rahasia keluarga',
      'image': 'https://picsum.photos/id/201/200',
      'rating': 4.8,
      'time': '30 min',
      'difficulty': 'Mudah',
    },
    {
      'id': 2,
      'title': 'Soto Ayam Lamongan',
      'description': 'Soto ayam dengan koya khas Lamongan',
      'image': 'https://picsum.photos/id/202/200',
      'rating': 4.9,
      'time': '45 min',
      'difficulty': 'Sedang',
    },
  ];

  void _navigateToTambahResep() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TambahResepPage()),
    );

    // Jika ada resep baru yang ditambahkan
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _myRecipes.insert(0, result);
      });
    }
  }

  void _deleteRecipe(int id) {
    setState(() {
      _myRecipes.removeWhere((recipe) => recipe['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Resep Saya",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.deepOrange),
            onPressed: _navigateToTambahResep,
            tooltip: 'Tambah Resep',
          ),
        ],
      ),
      body: _myRecipes.isEmpty ? _buildEmptyState() : _buildRecipeList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToTambahResep,
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            "Belum ada resep",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tambahkan resep pertama Anda",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _navigateToTambahResep,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Tambah Resep",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan jumlah resep
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              "${_myRecipes.length} Resep Dibuat",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // List resep
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _myRecipes.length,
            itemBuilder: (context, index) {
              final recipe = _myRecipes[index];
              return _buildRecipeCard(recipe);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar resep
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    recipe['image'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),

                // Info resep
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Meta info
                      Row(
                        children: [
                          _buildMetaInfo(Icons.schedule, recipe['time']),
                          const SizedBox(width: 12),
                          _buildMetaInfo(Icons.star, '${recipe['rating']}'),
                          const SizedBox(width: 12),
                          _buildMetaInfo(Icons.flag, recipe['difficulty']),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tombol delete
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: () {
                _showRecipeOptions(recipe['id']);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.deepOrange),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  void _showRecipeOptions(int recipeId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Resep'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement edit functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Resep'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(recipeId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(int recipeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Resep'),
        content: const Text('Apakah Anda yakin ingin menghapus resep ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecipe(recipeId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
