class RecipeModel {
  final int id;
  final String title;
  final String kategori;
  final String rating;
  final String ingredients;
  final String steps;
  final String description;
  final String? image;
  final String time;
  final String difficulty;
  final String author;

  RecipeModel({
    required this.id,
    required this.title,
    required this.kategori,
    required this.rating,
    required this.ingredients,
    required this.steps,
    required this.description,
    required this.image,
    required this.time,
    required this.difficulty,
    required this.author,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    // Gunakan fungsi untuk konversi yang aman
    final rawId = json['id'];

    // Konversi rawId ke int:
    // Jika rawId sudah int, gunakan nilainya.
    // Jika rawId adalah String (misalnya "1"), gunakan int.tryParse.
    int parsedId;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId) ?? 0;
    } else {
      parsedId = 0;
    }

    return RecipeModel(
      // id: json['id'] ?? 0, // <-- Kode lama ini akan error jika json['id'] adalah String

      // ✅ Ganti baris ini dengan parsedId
      // id: parsedId,
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,

      title: json['title'] ?? '',
      kategori: json['kategori'] ?? '',
      description: json['description'] ?? '',
      ingredients: json['ingredients'] ?? '',
      steps: json['steps'] ?? '',
      time: json['time'] ?? '',
      difficulty: json['difficulty'] ?? '',

      // Catatan: Rating juga sebaiknya diubah ke int jika Anda ingin melakukan operasi hitungan
      rating: json['rating']?.toString() ?? '0',

      author: json['author'] ?? '-',
      // Simpan nama file/gambar dari backend. UI akan membangun URL lengkap menggunakan ApiService.baseUrl.
      image: json['image'] != null ? json['image'].toString() : null,
    );
  }

  factory RecipeModel.fromMealDbFilterJson(Map<String, dynamic> json) {
    return RecipeModel(
      // Kita hanya punya data minimal dari endpoint filter:
      id: int.tryParse(json['idMeal']?.toString() ?? '0') ?? 0,
      title: json['strMeal'] ?? 'Unknown Recipe',
      image: json['strMealThumb']?.toString(), // Ini URL thumbnail
      // Beri nilai default untuk field yang tidak ada
      kategori: 'External',
      rating: '0',
      ingredients: '',
      steps: '',
      description: '',
      time: '',
      difficulty: 'Medium',
      author: 'TheMealDB',
    );
  }

  // Factory untuk data hasil lookup detail
  factory RecipeModel.fromMealDbDetailJson(Map<String, dynamic> json) {
    // Ambil instruksi (strInstructions)
    String instructions = json['strInstructions'] ?? 'Langkah tidak tersedia.';

    // Ambil bahan-bahan (di TheMealDB ini ada di field strIngredient1, strIngredient2, dst)
    String ingredients = '';
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null &&
          ingredient.isNotEmpty &&
          ingredient.toString().trim().isNotEmpty) {
        ingredients += '- $ingredient (${measure ?? ''})\n';
      }
    }

    return RecipeModel(
      id: int.tryParse(json['idMeal']?.toString() ?? '0') ?? 0,
      title: json['strMeal'] ?? 'Unknown Recipe',
      kategori: json['strCategory'] ?? 'N/A',
      description: json['strArea'] ?? 'N/A', // Gunakan Area sebagai deskripsi
      ingredients: ingredients,
      steps: instructions,
      time:
          json['strMeasure']?.toString() ??
          'N/A', // Ganti dengan waktu jika ada fieldnya
      difficulty: 'N/A',
      rating: 'N/A',
      author: json['strArea'] ?? 'External',
      image: json['strMealThumb']?.toString(), // Ini URL gambar besar
    );
  }
  Map<String, dynamic> toJson() {
    return {
      // Saat menyimpan resep baru dari luar, ID seharusnya tidak dikirim,
      // atau jika dikirim, back-end harus mengabaikannya dan membuat ID baru.
      // Kita kirim data yang diambil dari TheMealDB.
      'title': title,
      'kategori': kategori,
      'rating': rating,
      'ingredients': ingredients,
      'steps': steps,
      'description': description,
      // Karena image TheMealDB adalah URL penuh, kita kirimkan URL-nya.
      // Back-end CI4 HARUS menangani penyimpanan gambar ini dan mengembalikan
      // nama file lokalnya sebagai 'image' di RecipeModel yang baru.
      'image': image,
      'time': time,
      'difficulty': difficulty,
      'author': author, // Ini harusnya 'TheMealDB'
    };
  }

  // return RecipeModel(
  //   id: json['id'] ?? 0,
  //   title: json['title'] ?? '',
  //   kategori: json['kategori'] ?? '',
  //   description: json['description'] ?? '',
  //   ingredients: json['ingredients'] ?? '',
  //   steps: json['steps'] ?? '',
  //   time: json['time'] ?? '',
  //   difficulty: json['difficulty'] ?? '',
  //   rating: json['rating']?.toString() ?? '0',
  //   author: json['author'] ?? '-',
  //   image: json['image'] != null
  //       ? "http://10.0.2.2:8080/uploads/recipes/${json['image']}"
  //       : "", // backend ngirim nama file, bukan URL penuh
  // );
  // }

  // ⬇️ TARUH FUNCTION INI DI SINI
  // factory RecipeModel.fromJson(Map<String, dynamic> json) {
  //   return RecipeModel(
  //     id: json['id'] ?? 0,
  //     title: json['title'] ?? '',
  //     kategori: json['kategori'] ?? '',
  //     rating: json['rating']?.toString() ?? '0',
  //     ingredients: json['ingredients'] ?? '',
  //     steps: json['steps'] ?? '',
  //     description: json['description'] ?? '',
  //     image: json['image'] ?? '', // karena API mengirim 'image'
  //     time: json['time'] ?? '',
  //     difficulty: json['difficulty'] ?? '',
  //     author: json['author'] ?? '-', // fallback
  //   );
  // }
}
