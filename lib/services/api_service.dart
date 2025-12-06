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

    if (token == null) {
      print('DEBUG: SharedPreferences - TOKEN TIDAK DITEMUKAN!');
    } else {
      print(
        'DEBUG: SharedPreferences - Token ditemukan, panjang: ${token.length}',
      );
    }
    final headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
    print('DEBUG: Auth Headers: $headers'); // <-- TAMBAHKAN INI

    return headers;
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
          userName: '',
        );
      }
    } catch (e) {
      return LoginResponse(
        status: false,
        token: 'Error: $e',
        userEmail: '',
        userId: 0,
        userName: '',
      );
    }
  }

  // CREATE RECIPE
  // =======================
  Future<dynamic> addRecipe(Map<String, String> data, File? image) async {
    var request = http.MultipartRequest(
      "POST",
      // Uri.parse("$_baseUrl/resep/create"),
      Uri.parse("$_baseUrl/api/resep"),
    );

    data.remove('user_id');

    data.forEach((key, value) {
      request.fields[key] = value;
    });

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath("image", image.path));
    }

    // Tambahkan header Authorization
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    var response = await request.send();
    var result = await response.stream.bytesToString();
    return jsonDecode(result);
  }

  // 4️⃣ UPLOAD DATA RESEP + IMAGE
  Future<Map<String, dynamic>> postRecipe(
    Map<String, dynamic> data,
    File? imageFile,
  ) async {
    // Endpoint untuk membuat resep baru (multipart POST dengan optional image)
    final uri = Uri.parse('$_baseUrl/api/resep');
    // final uri = Uri.parse('$_baseUrl/resep/create');

    try {
      final request = http.MultipartRequest('POST', uri);

      // Tambahkan header Authorization jika ada token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      data.remove('user_id');
      // Tambahkan fields
      data.forEach((k, v) => request.fields[k] = v.toString());

      // Tambahkan file jika ada
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final responseBody = await streamedResponse.stream.bytesToString();

      print('DEBUG: postRecipe status: ${streamedResponse.statusCode}');
      print('DEBUG: postRecipe body: $responseBody');

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else if (streamedResponse.statusCode == 401) {
        throw TokenExpiredException();
      } else {
        try {
          final errorBody = jsonDecode(responseBody);
          throw Exception(
            'Gagal membuat resep (${streamedResponse.statusCode}): ${errorBody['message'] ?? responseBody}',
          );
        } catch (e) {
          throw Exception(
            'Gagal membuat resep (${streamedResponse.statusCode}): $responseBody',
          );
        }
      }
    } on TimeoutException {
      throw Exception('Waktu tunggu pembuatan resep habis (30 detik)');
    } catch (e) {
      rethrow;
    }
  }

  // Ambil semua resep (generic GET /resep)
  Future<List<RecipeModel>> fetchRecipes() async {
    // final url = Uri.parse('$_baseUrl/resep');
    final url = Uri.parse('$_baseUrl/api/resep');

    final response = await http
        .get(url, headers: await _getAuthHeaders())
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      List<dynamic> listData;
      if (body is Map && body.containsKey('data')) {
        listData = body['data'];
      } else if (body is List) {
        listData = body;
      } else {
        // Unexpected format, try to wrap single object
        listData = [];
      }

      return listData.map((json) => RecipeModel.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw TokenExpiredException();
    } else {
      throw Exception('Gagal memuat resep, status: ${response.statusCode}');
    }
  }

  // ambil resep milik user berdasarkan id
  Future<List<RecipeModel>> fetchMyRecipes() async {
    final url = Uri.parse('$_baseUrl/api/myrecipes');

    try {
      print('Debug: Fetching My Recipes from $url');
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print('DEBUG: My Recipes Error Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> listData = body['data'] ?? [];
        return listData.map((json) => RecipeModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw TokenExpiredException();
      } else {
        throw Exception(
          'Gagal memuat resep Kamu, status: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      throw Exception('Waktu tunggu koneksi hasis saat memuat resep anda');
    } catch (e) {
      rethrow;
    }
  }
  // Future<List<RecipeModel>> fetchUserRecipes(int userId) async {
  //   // Beberapa backend mungkin mengekspos route berbeda untuk resep user.
  //   // Coba urutkan beberapa kandidat endpoint dan ambil respons pertama yang berhasil.
  //   final candidates = [
  //     Uri.parse('$_baseUrl/resep/user/$userId'),
  //     Uri.parse('$_baseUrl/resep/user_id/$userId'),
  //     Uri.parse('$_baseUrl/resep/userId/$userId'),
  //     Uri.parse('$_baseUrl/resep?user_id=$userId'),
  //     Uri.parse('$_baseUrl/resep?userId=$userId'),
  //   ];

  //   Exception? lastException;

  //   for (final uri in candidates) {
  //     try {
  //       print('DEBUG: Trying fetchUserRecipes -> $uri');
  //       final response = await http
  //           .get(uri, headers: await _getAuthHeaders())
  //           .timeout(const Duration(seconds: 15));

  //       if (response.statusCode == 200) {
  //         final body = jsonDecode(response.body);
  //         List<dynamic> listData;
  //         if (body is Map && body.containsKey('data')) {
  //           listData = body['data'];
  //         } else if (body is List) {
  //           listData = body;
  //         } else {
  //           listData = body;
  //         }
  //         return listData.map((json) => RecipeModel.fromJson(json)).toList();
  //       } else if (response.statusCode == 401) {
  //         throw TokenExpiredException();
  //       } else if (response.statusCode == 404) {
  //         // coba endpoint berikutnya
  //         lastException = Exception('404 Not Found for $uri');
  //         continue;
  //       } else {
  //         // hentikan dan laporkan error spesifik
  //         throw Exception(
  //           'Gagal memuat resep user, status: ${response.statusCode}',
  //         );
  //       }
  //     } on TimeoutException catch (e) {
  //       lastException = Exception('Timeout fetching $uri: $e');
  //       continue;
  //     } on SocketException catch (e) {
  //       lastException = Exception('Network error fetching $uri: $e');
  //       continue;
  //     } catch (e) {
  //       lastException = Exception('Error fetching $uri: $e');
  //       continue;
  //     }
  //   }

  //   // Jika semua kandidat gagal, lempar exception terakhir atau generic
  //   if (lastException != null) throw lastException;
  //   throw Exception('Gagal memuat resep user: tidak ada endpoint yang sesuai');
  // }

  // Delete recipe berdasarkan ID
  Future<bool> deleteRecipe(int id) async {
    // final uri = Uri.parse('$_baseUrl/resep/$id'); // DELETE /resep/{id}
    final uri = Uri.parse('$_baseUrl/api/resep/$id');
    try {
      print('DEBUG: Delete Recipe - ID: $id, URL: $uri');

      final response = await http
          .delete(uri, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 15));

      print('DEBUG: Delete Response Status: ${response.statusCode}');
      print('DEBUG: Delete Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401) {
        throw TokenExpiredException();
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(
            'Gagal menghapus resep (${response.statusCode}): ${errorBody['message'] ?? 'Unknown error'}',
          );
        } catch (e) {
          throw Exception('Gagal menghapus resep (${response.statusCode}): $e');
        }
      }
    } on TimeoutException {
      throw Exception('Waktu tunggu delete resep habis (15 detik)');
    } catch (e) {
      print('DEBUG: Delete Recipe Error: $e');
      rethrow;
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
    Map<String, dynamic> data, {
    File? imageFile,
  }) async {
    final url = Uri.parse('$_baseUrl/api/resep/$id');
    // final url = Uri.parse('$_baseUrl/resep/$id'); // endpoint utama

    try {
      print(
        'DEBUG: Update Recipe - ID: $id, Data: $data, Image: ${imageFile?.path}',
      );

      // Jika ada file gambar -> gunakan multipart POST dengan override (server mungkin butuh form-data)
      if (imageFile != null) {
        var request = http.MultipartRequest('POST', url);

        // Tambahkan header Authorization saja (jangan paksa Content-Type)
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) request.headers['Authorization'] = 'Bearer $token';

        // method override agar backend mengenali ini sebagai PUT
        request.fields['_method'] = 'PUT';

        // Convert semua data ke string dan tambahkan ke fields
        data.forEach((key, value) => request.fields[key] = value.toString());

        print('DEBUG: updateRecipe multipart fields: ${request.fields}');

        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );

        var streamed = await request.send().timeout(
          const Duration(seconds: 30),
        );
        final responseBody = await streamed.stream.bytesToString();
        print('DEBUG: Update (multipart) Status: ${streamed.statusCode}');
        print('DEBUG: Update (multipart) Body: $responseBody');

        if (streamed.statusCode == 200 || streamed.statusCode == 201) {
          return jsonDecode(responseBody);
        } else if (streamed.statusCode == 401) {
          throw TokenExpiredException();
        } else {
          try {
            final errorBody = jsonDecode(responseBody);
            throw Exception(
              'Gagal update resep (${streamed.statusCode}): ${errorBody['message'] ?? responseBody}',
            );
          } catch (e) {
            throw Exception(
              'Gagal update resep (${streamed.statusCode}): $responseBody',
            );
          }
        }
      }

      // Jika tidak ada file -> kirim PUT dengan JSON body (lebih kompatibel untuk update tanpa file)
      print('DEBUG: updateRecipe JSON payload: $data');
      final headers = await _getAuthHeaders();
      headers['Content-Type'] = 'application/json';
      final response = await http
          .put(url, headers: headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 30));

      print('DEBUG: Update (JSON) Response Status: ${response.statusCode}');
      print('DEBUG: Update (JSON) Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw TokenExpiredException();
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(
            'Gagal update resep (${response.statusCode}): ${errorBody['message'] ?? response.body}',
          );
        } catch (e) {
          throw Exception(
            'Gagal update resep (${response.statusCode}): ${response.body}',
          );
        }
      }
    } on TimeoutException {
      throw Exception('Waktu tunggu update resep habis (30 detik)');
    } catch (e) {
      print('DEBUG: Update Recipe Error: $e');
      rethrow;
    }
  }
  // 👇 FUNGSI BARU DIMULAI DI SINI (1/3)

  /// Menyimpan resep ke daftar favorit user (POST /resep/simpan)
  Future<void> saveRecipe(int recipeId) async {
    // Coba beberapa kandidat endpoint karena backend bisa bervariasi
    final uri = Uri.parse('$_baseUrl/api/resep/bookmark');
    final bodyData = json.encode({'recipe_id': recipeId});
    // final candidates = [
    //   Uri.parse('$_baseUrl/resep/simpan'),
    //   Uri.parse('$_baseUrl/resep/save'),
    //   Uri.parse('$_baseUrl/resep/$recipeId/simpan'),
    //   Uri.parse('$_baseUrl/resep/saved'),
    // ];

    // final uri = Uri.parse('$_baseUrl/api/resep/bookmark');

    //Exception? lastException;

    try {
      print('DEBUG: Trying saveRecipe -> $uri');
      final response = await http
          .post(
            uri,
            headers: await _getAuthHeaders(),
            // body: json.encode({'user_id': userId, 'recipe_id': recipeId}),
            body: bodyData,
          )
          .timeout(const Duration(seconds: 10));

      print('DEBUG: saveRecipe $uri -> ${response.statusCode}');
      print('DEBUG: saveRecipe body: ${response.body}');

      if (response.statusCode == 201 ||
          response.statusCode == 200 ||
          response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw TokenExpiredException();
        // } else if (response.statusCode == 404) {
        //   // coba endpoint berikutnya
        //   lastException = Exception('404 Not Found for $uri');
        //   continue;
      } else {
        throw Exception('Gagal menyimpan resep: ${response.body}');
        // Log error, tapi jangan langsung throw agar UI masih bisa menyimpan lokal sebagai fallback
        // try {
        //   final errorBody = jsonDecode(response.body);
        //   print(
        //     'DEBUG: saveRecipe error: ${errorBody['message'] ?? response.body}',
        //   );
        // } catch (_) {
        //   print('DEBUG: saveRecipe unexpected response: ${response.body}');
        // }
        // // Return tanpa throw sehingga caller dapat melakukan fallback lokal
        //return;
      }
      // } on TimeoutException catch (e) {
      //   lastException = Exception('Timeout saving to $uri: $e');
      //   continue;
      // } on SocketException catch (e) {
      //   lastException = Exception('Network error saving to $uri: $e');
      //   continue;
    } catch (e) {
      rethrow;
      // lastException = Exception('Error saving to $uri: $e');
      // continue;
    }

    // Jika semua candidate gagal, log dan kembalikan tanpa exception agar client bisa fallback lokal
    //   print(
    //     'DEBUG: saveRecipe - semua endpoint gagal, lastException: $lastException',
    //   );
    //   return;
  }

  /// Menghapus resep dari daftar favorit user (DELETE /resep/simpan/hapus)
  Future<void> removeSavedRecipe(int recipeId) async {
    // Coba beberapa kandidat endpoint untuk menghapus saved
    // final deleteCandidates = [
    //   Uri.parse('$_baseUrl/resep/simpan/hapus'),
    //   Uri.parse('$_baseUrl/resep/simpan/remove'),
    //   Uri.parse('$_baseUrl/resep/$recipeId/simpan/hapus'),
    //   Uri.parse('$_baseUrl/resep/saved/remove'),
    // ];
    final uri = Uri.parse('$_baseUrl/api/resep/bookmark');

    // Exception? lastException;

    try {
      print('DEBUG: Trying removeSavedRecipe -> $uri');
      final headers = await _getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      // Beberapa server tidak mendukung body pada DELETE; jika gagal gunakan POST fallback
      final response = await http
          .delete(
            uri,
            headers: await _getAuthHeaders(),
            body: json.encode({'recipe_id': recipeId, '_method': 'DELETE'}),
          )
          .timeout(const Duration(seconds: 10));

      print('DEBUG: removeSavedRecipe $uri -> ${response.statusCode}');
      print('DEBUG: removeSavedRecipe body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw TokenExpiredException();
        // } else if (response.statusCode == 404) {
        //   lastException = Exception('404 Not Found for $uri');
        //   continue;
      } else {
        throw Exception('Gagal menghapus simpanan: ${response.body}');
        // Jika ada error lain, coba fallback POST remove
        // try {
        //   final postResp = await http
        //       .post(
        //         uri,
        //         headers: await _getAuthHeaders(),
        //         body: json.encode({'user_id': userId, 'recipe_id': recipeId}),
        //       )
        //       .timeout(const Duration(seconds: 10));

        //   print(
        //     'DEBUG: removeSavedRecipe POST fallback $uri -> ${postResp.statusCode}',
        //   );
        //   print('DEBUG: removeSavedRecipe POST body: ${postResp.body}');

        //   if (postResp.statusCode == 200 ||
        //       postResp.statusCode == 204 ||
        //       postResp.statusCode == 201) {
        //     return;
      }
    } catch (e) {
      print('DEBUG: removeSavedRecipe POST fallback failed: $e');
      rethrow;
    }
  }
  //         // Jangan lempar exception agar caller dapat melakukan fallback lokal
  //         return;
  //       }
  //     } on TimeoutException catch (e) {
  //       lastException = Exception('Timeout removing saved at $uri: $e');
  //       continue;
  //     } on SocketException catch (e) {
  //       lastException = Exception('Network error removing saved at $uri: $e');
  //       continue;
  //     } catch (e) {
  //       lastException = Exception('Error removing saved at $uri: $e');
  //       continue;
  //     }
  //   }

  //   print(
  //     'DEBUG: removeSavedRecipe - semua endpoint gagal, lastException: $lastException',
  //   );
  //   return;
  // }

  /// Mengambil semua ID resep yang disimpan oleh user (GET /resep/simpan/user/{userId})
  /// Coba multiple endpoint candidates jika endpoint utama 404
  // Future<Set<int>> fetchSavedRecipeIds(int userId) async {
  //   final candidates = [
  //     Uri.parse('$_baseUrl/resep/simpan/user/$userId'),
  //     Uri.parse('$_baseUrl/resep/simpan/$userId'),
  //     Uri.parse('$_baseUrl/resep/user/$userId/simpan'),
  //     Uri.parse('$_baseUrl/saved-recipes/$userId'),
  //     Uri.parse('$_baseUrl/resep?user_id=$userId&saved=true'),
  //   ];

  //   Exception? lastException;

  //   for (final uri in candidates) {
  //     try {
  //       print('DEBUG: Trying fetchSavedRecipeIds -> $uri');
  //       final response = await http
  //           .get(uri, headers: await _getAuthHeaders())
  //           .timeout(const Duration(seconds: 15));

  //       if (response.statusCode == 200) {
  //         final body = jsonDecode(response.body);
  //         List<dynamic> listData;

  //         // Handle berbagai format respons
  //         if (body is Map && body.containsKey('data')) {
  //           listData = body['data'] as List<dynamic>;
  //         } else if (body is List) {
  //           listData = body;
  //         } else {
  //           listData = [];
  //         }

  //         // Mapping list elements into ints. Support formats:
  //         // - list of ints [1,2,3]
  //         // - list of objects [{"recipe_id":123}, {"id":123}]
  //         return listData
  //             .map<int>((item) {
  //               if (item is int) return item;
  //               if (item is Map) {
  //                 if (item.containsKey('recipe_id'))
  //                   return (item['recipe_id'] as int?) ?? 0;
  //                 if (item.containsKey('id')) return (item['id'] as int?) ?? 0;
  //               }
  //               return 0;
  //             })
  //             .where((id) => id != 0)
  //             .toSet();
  //       } else if (response.statusCode == 401) {
  //         throw TokenExpiredException();
  //       } else if (response.statusCode == 404) {
  //         // Coba endpoint berikutnya
  //         lastException = Exception('404 Not Found for $uri');
  //         continue;
  //       } else {
  //         // Hentikan jika ada error selain 404
  //         throw Exception(
  //           'Gagal memuat daftar simpanan (${response.statusCode}): ${response.body}',
  //         );
  //       }
  //     } on TimeoutException catch (e) {
  //       lastException = Exception('Timeout fetching $uri: $e');
  //       continue;
  //     } on SocketException catch (e) {
  //       lastException = Exception('Network error fetching $uri: $e');
  //       continue;
  //     } catch (e) {
  //       lastException = Exception('Error fetching $uri: $e');
  //       continue;
  //     }
  //   }

  //   // Jika semua candidate gagal, kembalikan set kosong (bukan error)
  //   // sehingga tab "Resep Disimpan" bisa tetap ditampilkan (empty state)
  //   print(
  //     'DEBUG: fetchSavedRecipeIds - semua endpoint gagal, kembalikan set kosong',
  //   );
  //   if (lastException != null) {
  //     print('DEBUG: Last exception: $lastException');
  //   }
  //   return <int>{};
  // }
  // Fungsi sebelumnya fetchSavedRecipeIds(int userId) sudah diubah menjadi ini:
  Future<List<RecipeModel>> fetchSavedRecipes() async {
    final url = Uri.parse(
      '$_baseUrl/api/resep/saved',
    ); // ✅ PANGGIL ENDPOINT AMAN BARU

    try {
      final response = await http
          .get(url, headers: await _getAuthHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> listData = body['data'] ?? [];

        // CI4 sudah mengembalikan detail resep, tidak perlu loop fetch detail lagi
        return listData.map((json) => RecipeModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw TokenExpiredException();
      } else {
        throw Exception('Gagal memuat daftar simpanan: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<RecipeModel?> fetchUserRecipeById(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/resep/$id'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      dynamic jsonData;

      // Tolerate different response shapes
      if (body is Map && body.containsKey('data')) {
        jsonData = body['data'];
      } else if (body is Map &&
          (body.containsKey('id') ||
              body.containsKey('title') ||
              body.containsKey('image'))) {
        // Already the recipe object
        jsonData = body;
      } else if (body is List && body.isNotEmpty) {
        jsonData = body[0];
      } else {
        print(
          'DEBUG: fetchUserRecipeById - unexpected response shape for id=$id: $body',
        );
        return null;
      }

      try {
        return RecipeModel.fromJson(jsonData);
      } catch (e) {
        print('DEBUG: fetchUserRecipeById - parse error for id=$id: $e');
        return null;
      }
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
