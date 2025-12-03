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

  // ⬇️ TARUH FUNCTION INI DI SINI
  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      kategori: json['kategori'] ?? '',
      rating: json['rating']?.toString() ?? '0',
      ingredients: json['ingredients'] ?? '',
      steps: json['steps'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '', // karena API mengirim 'image'
      time: json['time'] ?? '',
      difficulty: json['difficulty'] ?? '',
      author: json['author'] ?? '-', // fallback
    );
  }
}
