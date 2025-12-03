import 'package:flutter/material.dart';
import '../widgets/card_recipe.dart';
import '../services/api_service.dart';
import '../models/recipe_model.dart';

class HalamanResep extends StatefulWidget {
  const HalamanResep({super.key});

  @override
  State<HalamanResep> createState() => _HalamanResepState();
}

class _HalamanResepState extends State<HalamanResep> {
  late Future<List<RecipeModel>> _futureRecipes;

  @override
  void initState() {
    super.initState();
    _futureRecipes = ApiService().fetchRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resep Praktis')),
      body: FutureBuilder<List<RecipeModel>>(
        // 💡 Menggunakan FutureBuilder
        future: _futureRecipes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}. Cek Koneksi CI4!'),
            );
          } else if (snapshot.hasData) {
            final List<RecipeModel> recipes = snapshot.data!;

            if (recipes.isEmpty) {
              return const Center(
                child: Text('Tidak ada data resep yang tersedia.'),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recipes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                  childAspectRatio: 0.7,
                ),
                itemBuilder: (context, index) {
                  final recipe = recipes[index];

                  // Meneruskan data dari Model ke Partial Card
                  return RecipeCard(
                    // Ganti dengan nama widget Card Anda
                    imageUrl: recipe.image ?? '',
                    title: recipe.title,
                    kategori: recipe.kategori,
                    rating: recipe.rating
                        .toString(), // Convert to String if rating is a number
                    steps: int.tryParse(recipe.steps) ?? 0,
                    difficulty: recipe.difficulty,
                    author: recipe.author,
                  );
                },
              ),
            );
          }
          return const Center(child: Text('Memulai pengambilan data..'));
        },
      ),
    );
  }
}

// class HalamanResep extends StatelessWidget {
  // Simulasi Data yang sudah di-fetch dan di-decode dari JSON
  // static const List<Map<String, dynamic>> dummyRecipes = [
  //   {
  //     'title': 'Bening Sawi Jagung',
  //     'imageUrl':
  //         'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ-i5vY9awY9Ql0bKrXHmecMC2kfCVWPGDIZOJJIx1gHR5lFMBW0ISMp9DwAS9oevv3FkKfzd4cfo_DqjiQfD79X3mdfniidbacWUiXw9UX&s=10',
  //     'rating': 5.0,
  //     'steps': 5,
  //     'kategori': 'asia',
  //     'difficulty': 'sedang',
  //     'author': 'Ovie Kholifatun',
  //   },
  //   {
  //     'title': 'Alpukat Kocok',
  //     'imageUrl': 'URL_ALPUKAT_KOCOK',
  //     'rating': 4.6,
  //     'steps': 5,
  //     'kategori': 'asia',
  //     'difficulty': 'sedang',
  //     'author': 'Yummy Official',
  //   },
  //   {
  //     'title': 'Bumbu Dasar Putih #YummyResepDasar',
  //     'imageUrl': 'URL_BUMBU_PUTIH',
  //     'rating': 4.8,
  //     'steps': 20,
  //     'kategori': 'asia',
  //     'difficulty': 'sedang',
  //     'author': 'Yummy Official',
  //   },
  //   {
  //     'title': 'Pisang Caramel',
  //     'imageUrl': 'URL_PISANG_CARAMEL',
  //     'rating': 4.9,
  //     'steps': 5,
  //     'kategori': 'asia',
  //     'difficulty': 'sedang',
  //     'author': 'Mama Queen',
  //   },
  // ];

  // final List<Map<String, dynamic>> recipes = dummyRecipes;

//   const HalamanResep({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // TODO: implement build
//     return Scaffold(
//       appBar: AppBar(centerTitle: true, title: Text('Resep-resep')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             GridView.builder(
//               // Properti Penting untuk GridView di dalam SingleChildScrollView
//               shrinkWrap: true, // Membuat GridView hanya sebesar isinya
//               physics:
//                   const NeverScrollableScrollPhysics(), // Menonaktifkan scroll GridView, agar scroll ditangani oleh SingleChildScrollView

//               itemCount: recipes.length, // Jumlah item (data resep)
//               // Delegasi untuk mengatur tata letak Grid
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2, // 2 kolom
//                 crossAxisSpacing: 10.0, // Jarak horizontal antar Card
//                 mainAxisSpacing: 10.0, // Jarak vertikal antar Card
//                 childAspectRatio:
//                     0.7, // Rasio lebar/tinggi (untuk memastikan Card cukup tinggi)
//               ),
//               // Fungsi yang membangun setiap item Grid
//               itemBuilder: (context, index) {
//                 final recipe = recipes[index];

//                 // ➡️ PANGGILAN PARTIAL CARD ANDA DI SINI
//                 return RecipeCard(
//                   // Meneruskan data dari list ke constructor RecipeCard
//                   imageUrl: recipe['imageUrl'] ?? 'placeholder_url',
//                   title: recipe['title'],
//                   rating: recipe['rating'].toString(),
//                   steps: recipe['steps'],
//                   kategori: recipe['kategori'],
//                   difficulty: recipe['difficulty'],
//                   author: recipe['author'],
//                   // Opsional: key: ValueKey(recipe['id']),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
