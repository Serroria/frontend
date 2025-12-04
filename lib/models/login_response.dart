class LoginResponse {
  final bool status;
  final String token;
  final String userEmail;
  final int userId;
  final String? userName;

  LoginResponse({
    required this.status,
    required this.token,
    required this.userEmail,
    required this.userId,
    this.userName,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Cek status code
    int statusCode = 0;
    if (json['status'] != null && json['status'] is int) {
      statusCode = json['status'];
    }

    // Pastikan data user ada
    var data = json['data'] ?? {};
    Map<String, dynamic>? userMap;
    if (data is Map && data['user'] is Map) {
      userMap = Map<String, dynamic>.from(data['user']);
    } else if (json['user'] is Map) {
      userMap = Map<String, dynamic>.from(json['user']);
    }

    // Ambil nama dari beberapa kemungkinan kunci
    String? name;
    if (userMap != null) {
      name = (userMap['nama'] ?? userMap['name'] ?? userMap['username'])
          ?.toString();
    }
    // Juga cek di data langsung
    name ??= (data['nama'] ?? data['name'] ?? data['username'])?.toString();

    return LoginResponse(
      status: (statusCode == 200),
      token: (data['token'] ?? '').toString(),
      userEmail: (userMap != null ? (userMap['email'] ?? '') : '').toString(),
      userId:
          int.tryParse(
            (userMap != null
                    ? (userMap['id'] ?? data['id'] ?? 0)
                    : (data['id'] ?? 0))
                .toString(),
          ) ??
          0,
      userName: name,
    );
  }
}
