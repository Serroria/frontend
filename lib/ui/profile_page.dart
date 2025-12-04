import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'User';
    setState(() => _username = username);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final profile = await _api.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  void _openEdit() async {
    final updated = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(initialProfile: _profile),
      ),
    );

    if (updated != null) {
      setState(() {
        _profile = updated;
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
          title: const Text('Profil'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          actions: [
            TextButton(
              onPressed: _openEdit,
              child: const Text(
                'Edit',
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
            _loading
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _buildHeader(),
            const Divider(height: 1),
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
                  Tab(text: 'Resep Saya'),
                  Tab(text: 'Resep Disimpan'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                children: [
                  _ProfileRecipeTab(
                    emptyText: 'Belum ada resep yang kamu buat.',
                    isSavedRecipes: false,
                    username: _username,
                  ),
                  _ProfileRecipeTab(
                    emptyText: 'Belum ada resep yang kamu simpan.',
                    isSavedRecipes: true,
                    username: _username,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final displayName = _username.isNotEmpty ? _username : 'User';
    final handle =
        (_profile?['handle'] ?? _profile?['username'])?.toString() ?? '';
    final avatar = (_profile?['avatar'] ?? _profile?['avatar_url'])?.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.deepPurple,
            backgroundImage: avatar != null && avatar.isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar == null || avatar.isEmpty
                ? Text(
                    displayName.isNotEmpty ? displayName[0] : 'U',
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
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (handle.isNotEmpty)
                  Text(
                    handle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Resep: 2',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRecipeTab extends StatelessWidget {
  final String emptyText;
  final bool isSavedRecipes;
  final String username;

  const _ProfileRecipeTab({
    required this.emptyText,
    this.isSavedRecipes = false,
    required this.username,
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
                      username: username,
                    ),
                    _buildRecipeCard(
                      imageUrl: 'https://picsum.photos/id/201/200',
                      title: 'Soto Ayam Lamongan',
                      description: 'Soto ayam dengan koya khas lamongan',
                      rating: 4.9,
                      duration: 45,
                      difficulty: 'Sedang',
                      username: username,
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
