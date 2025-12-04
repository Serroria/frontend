class LoginResponse {
  final bool status;
  final String token;
  final String userEmail;
  final int userId;
  final String userName;

  LoginResponse({
    required this.status,
    required this.token,
    required this.userEmail,
    required this.userId,
    required this.userName,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Cek status code
    int statusCode = 0;
    if (json['status'] != null && json['status'] is int) {
      statusCode = json['status'];
    }

    // Pastikan data user ada
    var data = json['data'] ?? {};
    var user = data['user'] ?? {};

    return LoginResponse(
      // FIX UTAMA: 200 berarti TRUE
      status: (statusCode == 200),

      token: (data['token'] ?? '').toString(),
      userEmail: (user['email'] ?? '').toString(),
      // Gunakan tryParse untuk mencegah crash jika ID bukan angka
      userId: int.tryParse(user['id'].toString()) ?? 0,
      // Ambil username dari field 'username' atau 'nama' di user object
      userName: (user['username'] ?? user['nama'] ?? user['name'] ?? '')
          .toString(),
    );
  }
}
