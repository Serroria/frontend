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
  // Base URL conditional untuk Web / Windows desktop / Android emulator
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isWindows) return 'http://localhost:8080';
    // Android emulator forwards 10.0.2.2 to host machine
    return 'http://10.0.2.2:8080';
  }
  // final String _baseUrl = "http://10.0.2.2:8080";

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

  // ⿢ LOGIN
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
      Uri.parse("$_baseUrl/recipes/create"),
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

  // 3️⃣ AMBIL DATA RESEP
  Future<List<RecipeModel>> fetchRecipes() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/resep'),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => RecipeModel.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw TokenExpiredException();
    } else {
      throw Exception('Gagal memuat resep, status: ${response.statusCode}');
    }
  }

  // 4️⃣ AMBIL USERNAME/PROFILE
  // Mencoba ambil username dari SharedPreferences terlebih dahulu,
  // jika tidak ada, request ke endpoint user berdasarkan user_id.
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('username');
    if (stored != null && stored.isNotEmpty) return stored;

    final userId = prefs.getInt('user_id');
    if (userId == null) return null;

    final url = Uri.parse('$_baseUrl/users/$userId');
    try {
      final response = await http.get(url, headers: await _getAuthHeaders());
      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        // Coba berbagai kunci umum yang mungkin dikembalikan API
        String? name;
        if (jsonMap is Map<String, dynamic>) {
          name = (jsonMap['nama'] ?? jsonMap['name'] ?? jsonMap['username'])
              ?.toString();
          // Jika API mengemas di bawah 'data' -> 'user'
          if (name == null && jsonMap['data'] is Map) {
            final data = jsonMap['data'] as Map<String, dynamic>;
            name = (data['nama'] ?? data['name'] ?? data['username'])
                ?.toString();
            if (name == null && data['user'] is Map) {
              final user = data['user'] as Map<String, dynamic>;
              name = (user['nama'] ?? user['name'] ?? user['username'])
                  ?.toString();
            }
          }
        }

        if (name != null && name.isNotEmpty) {
          await prefs.setString('username', name);
          return name;
        }

        return null;
      } else if (response.statusCode == 401) {
        throw TokenExpiredException();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Ambil profile lengkap dari backend
  Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return null;

    final url = Uri.parse('$_baseUrl/users/$userId');
    try {
      final response = await http.get(url, headers: await _getAuthHeaders());
      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        if (jsonMap is Map<String, dynamic>) {
          // try to find data.user or data
          if (jsonMap['data'] is Map && jsonMap['data']['user'] is Map) {
            return Map<String, dynamic>.from(jsonMap['data']['user']);
          }
          if (jsonMap['data'] is Map)
            return Map<String, dynamic>.from(jsonMap['data']);
          return Map<String, dynamic>.from(jsonMap);
        }
        return null;
      } else if (response.statusCode == 401) {
        throw TokenExpiredException();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update profile (optional avatar image)
  // Expects keys: nama, username, email, about (or other fields) in data
  Future<Map<String, dynamic>> updateProfile(
    Map<String, String> data,
    File? imageFile,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) throw Exception('User ID tidak ditemukan');

    var uri = Uri.parse('$_baseUrl/users/$userId/update');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _getAuthHeaders());

    data.forEach((k, v) {
      request.fields[k] = v;
    });

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('avatar', imageFile.path),
      );
    }

    try {
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        return jsonDecode(body) as Map<String, dynamic>;
      } else if (streamed.statusCode == 401) {
        throw TokenExpiredException();
      } else {
        throw Exception('Gagal memperbarui profil: ${streamed.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 4️⃣ UPLOAD DATA RESEP + IMAGE
  Future<Map<String, dynamic>> postRecipe(
    Map<String, dynamic> data,
    File? imageFile,
  ) async {
    // ✅ Endponit baru yang sesuai dengan routes.php: /recipes/create
    var uri = Uri.parse('$_baseUrl/recipes/create');
    var request = http.MultipartRequest('POST', uri);

    request.headers.addAll(await _getAuthHeaders());
    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }
    try {
      var response = await request.send().timeout(
        const Duration(seconds: 60),
      ); // 👈 Coba beri batas waktu 30 detik
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
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
}

// Hapus semua kode tambahan setelah ini (misalnya class LoginPage yang tidak relevan dengan ApiService)
// class LoginPage extends StatelessWidget {
//   const LoginPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text("Login"),
//         centerTitle: true,
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             minHeight: MediaQuery.of(context).size.height - 80,
//           ),
//           child: IntrinsicHeight(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 const Spacer(),

//                 // Header
//                 Text(
//                   "Masuk untuk melihat resep favoritmu",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.deepOrange.shade400,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 32),

//                 // Form Card
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.deepOrange.shade50,
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.deepOrange.withOpacity(0.1),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       // Email
//                       TextField(
//                         decoration: InputDecoration(
//                           hintText: "Email",
//                           prefixIcon: const Icon(Icons.email_outlined),
//                           filled: true,
//                           fillColor: Colors.white,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: BorderSide(
//                               color: Colors.deepOrange.shade200,
//                             ),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: BorderSide(
//                               color: Colors.deepOrange.shade200,
//                             ),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: BorderSide(
//                               color: Colors.deepOrange.shade400,
//                               width: 2,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 18),

//                       // Password
//                       TextField(
//                         obscureText: true,
//                         decoration: InputDecoration(
//                           hintText: "Password",
//                           prefixIcon: const Icon(Icons.lock_outline),
//                           filled: true,
//                           fillColor: Colors.white,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: BorderSide(
//                               color: Colors.deepOrange.shade200,
//                             ),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: BorderSide(
//                               color: Colors.deepOrange.shade200,
//                             ),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(14),
//                             borderSide: BorderSide(
//                               color: Colors.deepOrange.shade400,
//                               width: 2,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 26),

//                       // Login Button
//                       SizedBox(
//                         width: double.infinity,
//                         height: 48,
//                         child: ElevatedButton(
//                           onPressed: () =>
//                               Navigator.pushReplacementNamed(context, "/home"),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.deepOrange,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(14),
//                             ),
//                             elevation: 3,
//                           ),
//                           child: const Text(
//                             "Login",
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 14),

//                       // Register Redirect
//                       TextButton(
//                         onPressed: () =>
//                             Navigator.pushNamed(context, "/registrasi"),
//                         child: Text(
//                           "Belum punya akun? Registrasi",
//                           style: TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.deepOrange.shade700,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 40),
//                 const Spacer(),
//                 const Spacer(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
