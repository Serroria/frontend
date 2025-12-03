import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const String _handle = "@cook_180405000";
    const String _displayName = "Marsha Daviena";

    return DefaultTabController(
      length: 2, // "Resep Saya" & "Resep Disimpan"
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
                // Navigate to edit profile page
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
                  // Foto profil (sementara icon)
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
                        const Text(
                          "Resep: 2", // dummy data
                          style: TextStyle(fontSize: 13, color: Colors.black87),
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
                  Tab(text: "Resep Saya"),
                  Tab(text: "Resep Disimpan"),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ISI TAB
            const Expanded(
              child: TabBarView(
                children: [
                  _ProfileRecipeTab(
                    emptyText: "Belum ada resep yang kamu buat.",
                    isSavedRecipes: false, // Flag untuk card resep yang dibuat
                  ),
                  _ProfileRecipeTab(
                    emptyText: "Belum ada resep yang kamu simpan.",
                    isSavedRecipes: true, // Flag untuk card resep yang disimpan
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

class _ProfileRecipeTab extends StatelessWidget {
  final String emptyText;
  final bool isSavedRecipes;

  const _ProfileRecipeTab({
    required this.emptyText,
    this.isSavedRecipes = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal, // Horizontal scrolling
            children: isSavedRecipes
                ? [
                    _buildRecipeCard(
                      imageUrl: 'https://picsum.photos/id/204/200',
                      title: 'Kuotie Ayam',
                      description: 'Kuotie ayam lezat dengan sambal manis',
                      rating: 4.7,
                      duration: 30,
                      difficulty: 'Mudah',
                      username: 'susanti',
                    ),
                    _buildRecipeCard(
                      imageUrl: 'https://picsum.photos/id/203/200',
                      title: 'Wedang Kopi Jahe',
                      description: 'Kopi jahe hangat dengan rempah beraroma',
                      rating: 5.0,
                      duration: 25,
                      difficulty: 'Mudah',
                      username: 'meymey',
                    ),
                  ]
                : [
                    _buildRecipeCard(
                      imageUrl: 'https://picsum.photos/id/200/200',
                      title: 'Nasi Goreng Spesial',
                      description: 'Nasi goreng dengan bumbu rahasia keluarga',
                      rating: 4.8,
                      duration: 30,
                      difficulty: 'mudah',
                      username: 'Marsha Daviena',
                    ),
                    _buildRecipeCard(
                      imageUrl: 'https://picsum.photos/id/201/200',
                      title: 'Soto Ayam Lamongan',
                      description: 'Soto ayam dengan koya khas lamongan',
                      rating: 4.9,
                      duration: 45,
                      difficulty: 'Sedang',
                      username: 'Marsha Daviena',
                    ),
                  ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard({
    required String imageUrl,
    required String title,
    required String description,
    required double rating,
    required int duration,
    required String difficulty,
    required String username,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
        child: Column(
          children: [
            // Username di atas gambar resep
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '$username',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Gambar resep
            Image.network(imageUrl, width: 200, height: 120, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 16),
                Text('$rating'),
                const SizedBox(width: 8),
                const Icon(Icons.access_time, size: 16),
                Text('$duration min'),
                const SizedBox(width: 8),
                const Icon(Icons.flag, size: 16),
                Text(difficulty),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
