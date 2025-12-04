import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_response.dart';
import '../models/login_response.dart';
import '../models/recipe_model.dart';

// ✅ Exception khusus jika token expired
class TokenExpiredException implements Exception {
  final String message = 'Sesi Anda telah berakhir. Silakan login ulang.';
  @override
  String toString() => message;
}

class ApiService {
  // ✅ Base URL conditional untuk Web/Emulator
  static const String _baseUrl = (kIsWeb)
      ? "http://localhost:8080"
      : "http://10.0.2.2:8080";
  // final String _baseUrl = "http://10.0.2.2:8080";
  String get baseUrl => _baseUrl;

  // ✅ Helper function untuk header
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // 1️⃣ REGISTRASI
  Future<ApiResponse> registrasi(
    String nama,
    String email,
    String password,
  ) async {
    final url = Uri.parse('$_baseUrl/registrasi');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'nama': nama,
              'email': email,
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 30), // 👈 Tambahkan batas waktu 30 detik
          );

      if (response.statusCode == 201) {
        return ApiResponse.fromJson(json.decode(response.body));
      } else {
        var errorBody = json.decode(response.body);
        return ApiResponse(
          status: false,
          data: errorBody['message'] ?? 'Gagal: ${response.statusCode}',
          code: response.statusCode,
        );
      }
    } on TimeoutException {
      // Tangkap jika 30 detik terlampaui
      throw Exception(
        'Waktu Tunggu Koneksi Habis (30 detik). Periksa koneksi internet/server.',
      );
    } on SocketException catch (e) {
      // Tangkap jika URL/IP tidak ditemukan atau Koneksi ditolak
      throw Exception(
        'Kesalahan Koneksi Jaringan: Periksa Base URL ($_baseUrl) atau server Anda. Detail: $e',
      );
    } catch (e) {
      return ApiResponse(
        status: false,
        data: 'Terjadi kesalahan: $e',
        code: 500,
      );
    }
  }

  // 2️⃣ LOGIN
  Future<LoginResponse> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(json.decode(response.body));
      } else {
        var errorData = json.decode(response.body);
        return LoginResponse(
          status: false,
          token: errorData['message'] ?? '',
          userEmail: '',
          userId: 0,
        );
      }
    } catch (e) {
      return LoginResponse(
        status: false,
        token: 'Error: $e',
        userEmail: '',
        userId: 0,
      );
    }
  }

  // CREATE RECIPE
  // =======================
  Future<dynamic> addRecipe(Map<String, String> data, File? image) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$_baseUrl/resep/create"),
    );

    data.forEach((key, value) {
      request.fields[key] = value;
    });

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath("image", image.path));
    }

    var response = await request.send();
    var result = await response.stream.bytesToString();
    return jsonDecode(result);
  }

  // 4️⃣ UPLOAD DATA RESEP + IMAGE
  Future<Map<String, dynamic>> postRecipe(
    Map<String, dynamic> data,
    File? imageFile,
  ) async {
    // ✅ Endponit baru yang sesuai dengan routes.php: /recipes/create
    var uri = Uri.parse('$_baseUrl/resep/create');
    var request = http.MultipartRequest('POST', uri);

    // request.headers.addAll(await _getAuthHeaders());
    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }
    try {
      var response = await request.send().timeout(const Duration(seconds: 60));
      // 👈 Coba beri batas waktu 30 detik
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(responseBody);
      } else if (response.statusCode == 401) {
        throw TokenExpiredException();
      } else {
        throw Exception(
          'Gagal upload resep: (${response.statusCode}) $responseBody',
        );
      }
    } on TimeoutException {
      // Menangkap jika request.send() melebihi batas 30 detik
      throw Exception(
        'Waktu Tunggu (Timeout) Koneksi Habis (60 detik). Coba lagi.',
      );
    } on SocketException catch (e) {
      // Menangkap error jaringan seperti koneksi ditolak
      throw Exception(
        'Kesalahan Koneksi Jaringan: Periksa Base URL atau server Anda. Detail: $e',
      );
    } catch (e) {
      // Menangkap error umum lainnya
      throw Exception('Terjadi Kesalahan Tak Terduga: $e');
    }
  }

  // di ApiService class

  // ambil semua resep — lebih forgiving terhadap format response
  Future<List<RecipeModel>> fetchRecipes() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/resep'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      List<dynamic> listData;

      // jika backend merespon { status: true, data: [...] }
      if (body is Map && body.containsKey('data')) {
        listData = body['data'];
      } else if (body is List) {
        listData = body;
      } else {
        throw Exception('Format response tidak dikenali');
      }

      return listData.map((json) => RecipeModel.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw TokenExpiredException();
    } else {
      throw Exception('Gagal memuat resep, status: ${response.statusCode}');
    }
  }

  // ambil resep milik user berdasarkan id
  Future<List<RecipeModel>> fetchUserRecipes(int userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/resep/user/$userId'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      List<dynamic> listData;
      if (body is Map && body.containsKey('data')) {
        listData = body['data'];
      } else if (body is List) {
        listData = body;
      } else {
        listData = body;
      }
      return listData.map((json) => RecipeModel.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw TokenExpiredException();
    } else {
      throw Exception(
        'Gagal memuat resep user, status: ${response.statusCode}',
      );
    }
  }

  // contoh delete (pastikan route di backend tersedia: DELETE /recipes/{id} atau /resep/{id})
  Future<bool> deleteRecipe(int id) async {
    final uri = Uri.parse('$_baseUrl/resep/$id'); // sesuaikan route backend
    final response = await http.delete(uri, headers: await _getAuthHeaders());
    if (response.statusCode == 200 || response.statusCode == 204) {
      return true;
    } else if (response.statusCode == 401) {
      throw TokenExpiredException();
    } else {
      return false;
    }
  }

  // Fungsi baru untuk mengambil resep terbaru dari CI4
  Future<List<RecipeModel>> fetchNewestRecipes() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/resep/terbaru'), // ✅ Memanggil endpoint baru
          headers: await _getAuthHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      List<dynamic> listData = body['data'] ?? [];

      return listData.map((json) => RecipeModel.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat resep terbaru: ${response.statusCode}');
    }
  }

  // Fungsi baru untuk mengambil resep populer dari CI4
  Future<List<RecipeModel>> fetchPopularRecipesCI4() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/resep/populer'), // ✅ Memanggil endpoint baru
          headers: await _getAuthHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      List<dynamic> listData = body['data'] ?? [];

      return listData.map((json) => RecipeModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Gagal memuat resep populer (CI4): ${response.statusCode}',
      );
    }
  }

  Future<List<RecipeModel>> fetchFilteredLocalRecipes(String kategori) async {
    final url = Uri.parse('$_baseUrl/resep/kategori/$kategori');

    final response = await http
        .get(url, headers: await _getAuthHeaders())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      List<dynamic> listData = body['data'] ?? [];
      return listData.map((json) => RecipeModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Gagal memuat resep berdasarkan kategori: ${response.statusCode}',
      );
    }
  }

  Future<List<RecipeModel>> searchLocalRecipes(String keyword) async {
    final encodedKeyword = Uri.encodeComponent(
      keyword,
    ); // Pastikan keyword di-encode
    final url = Uri.parse('$_baseUrl/resep/search/$encodedKeyword');

    final response = await http
        .get(url, headers: await _getAuthHeaders())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      List<dynamic> listData = body['data'] ?? [];

      return listData.map((json) => RecipeModel.fromJson(json)).toList();
    } else {
      throw Exception(
        'Gagal melakukan pencarian lokal: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> updateRecipe(
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$_baseUrl/resep/$id'); // PUT /resep/{id}

    final response = await http
        .put(
          url,
          headers: await _getAuthHeaders(),
          body: json.encode(data), // Kirim data sebagai JSON
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw TokenExpiredException();
    } else {
      throw Exception('Gagal update resep, status: ${response.statusCode}');
    }
  }
  // 👇 FUNGSI BARU DIMULAI DI SINI (1/3)

  /// Menyimpan resep ke daftar favorit user (POST /resep/simpan)
  Future<void> saveRecipe(int userId, int recipeId) async {
    final url = Uri.parse('$_baseUrl/resep/simpan');

    final response = await http
        .post(
          url,
          headers: await _getAuthHeaders(),
          body: json.encode({'user_id': userId, 'recipe_id': recipeId}),
        )
        .timeout(const Duration(seconds: 10));

    // CI4 diharapkan merespon 201 Created atau 200 OK
    if (response.statusCode == 201 || response.statusCode == 200) {
      return;
    } else if (response.statusCode == 401) {
      throw TokenExpiredException();
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        'Gagal menyimpan resep: ${errorBody['message'] ?? 'Kode: ${response.statusCode}'}',
      );
    }
  }

  /// Menghapus resep dari daftar favorit user (DELETE /resep/simpan/hapus)
  Future<void> removeSavedRecipe(int userId, int recipeId) async {
    // Menggunakan body dalam DELETE request
    final url = Uri.parse('$_baseUrl/resep/simpan/hapus');

    final response = await http
        .delete(
          url,
          headers: await _getAuthHeaders(),
          body: json.encode({'user_id': userId, 'recipe_id': recipeId}),
        )
        .timeout(const Duration(seconds: 10));

    // CI4 diharapkan merespon 200 OK atau 204 No Content
    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    } else if (response.statusCode == 401) {
      throw TokenExpiredException();
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(
        'Gagal menghapus resep tersimpan: ${errorBody['message'] ?? 'Kode: ${response.statusCode}'}',
      );
    }
  }

  /// Mengambil semua ID resep yang disimpan oleh user (GET /resep/simpan/user/{userId})
  Future<Set<int>> fetchSavedRecipeIds(int userId) async {
    final url = Uri.parse('$_baseUrl/resep/simpan/user/$userId');

    final response = await http
        .get(url, headers: await _getAuthHeaders())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      List<dynamic> listData = body['data'] ?? [];

      // Mapping list of objects {recipe_id: 123} menjadi Set<int>
      return listData
          // Ambil nilai dari kunci 'recipe_id'
          .map<int>((json) => (json['recipe_id'] as int?) ?? 0)
          // Pastikan ID tidak nol
          .where((id) => id != 0)
          .toSet();
    } else if (response.statusCode == 401) {
      throw TokenExpiredException();
    } else {
      throw Exception('Gagal memuat daftar simpanan: ${response.statusCode}');
    }
  }

  Future<RecipeModel?> fetchUserRecipeById(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/resep/$id'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return RecipeModel.fromJson(body['data']);
    } else {
      return null;
    }
  }

  // 👆 FUNGSI BARU SELESAI DI SINI

  // Hapus fungsi toggleSaveRecipe yang tidak lengkap
  // Future<bool> toggleSaveRecipe(int userId, int recipeId) async {
  //   // ... (Logika POST /resep/simpan di CI4) ...
  //   return true; // Asumsi sukses
  // }
}

// Hapus semua kode tambahan setelah ini (misalnya class LoginPage yang tidak relevan dengan ApiService)
// ... (Bagian LoginPage yang dihapus untuk menjaga ApiService tetap fokus)
