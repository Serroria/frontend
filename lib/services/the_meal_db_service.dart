// lib/services/the_meal_db_service.dart (atau di ApiService.dart)

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart'; // Tetap gunakan model yang sama

class TheMealDbService {
  final String _dbBaseUrl = "https://www.themealdb.com/api/json/v1/1";

  // Endpoint untuk mendapatkan 8 resep dari kategori tertentu (contoh: Seafood)
  // Ini bisa digunakan untuk 'Resep Populer'
  Future<List<RecipeModel>> fetchFilteredRecipes(
    String filterType,
    String value,
  ) async {
    // filterType bisa 'c' (category) atau 'a' (area)
    final url = Uri.parse('$_dbBaseUrl/filter.php?$filterType=$value');

    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      // Data dari TheMealDB ada di meals: [{idMeal: 52968, strMeal: ...}]
      List<dynamic> listData = body['meals'] ?? [];

      // Karena API filter hanya mengembalikan ID, Nama, dan Gambar,
      // kita harus membuat Model yang bisa memproses data ini.
      // Kita hanya ambil 8 data pertama sebagai rekomendasi.
      return listData
          .take(8)
          .map(
            (json) => RecipeModel.fromMealDbFilterJson(json),
          ) // <-- Fungsi parsing baru
          .toList();
    } else {
      throw Exception(
        'Gagal memuat resep dari TheMealDB: ${response.statusCode}',
      );
    }
  }

  // Endpoint untuk mencari detail resep berdasarkan ID
  Future<RecipeModel?> lookupMealDetail(String idMeal) async {
    final url = Uri.parse('$_dbBaseUrl/lookup.php?i=$idMeal');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final mealList = body['meals'];

      if (mealList != null && mealList.isNotEmpty) {
        return RecipeModel.fromMealDbDetailJson(
          mealList[0],
        ); // <-- Fungsi parsing detail
      }
    }
    return null;
  }

  Future<List<RecipeModel>> searchMealsByName(String query) async {
    final url = Uri.parse('$_dbBaseUrl/search.php?s=$query');
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      List<dynamic> listData = body['meals'] ?? [];
      if (listData.isEmpty || listData == null) {
        return [];
      }

      return listData
          .map((json) => RecipeModel.fromMealDbDetailJson(json))
          .toList();
    } else {
      throw Exception(
        'Gagal memuat hasil pencarian dari TheMealDB: ${response.statusCode}',
      );
    }
  }

  // Future searchMeals(String query) async {}
}
