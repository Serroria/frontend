import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text("Mencoba Masuk..."),
          ],
        ),
      ),
    );
  }

  Future<void> _doLogin() async {
    _showLoadingDialog();

    try {
      final response = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;
      Navigator.pop(context);

      // ... di dalam _doLogin()
      if (response.status) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response.token);
        await prefs.setInt('user_id', response.userId);
        // Simpan username jika tersedia di respon login untuk menghindari
        // request tambahan saat membuka homepage
        if (response.userName != null && response.userName!.isNotEmpty) {
          await prefs.setString('username', response.userName!);
        }

        if (!mounted) return;

        // ✅ GANTI DENGAN INI UNTUK LANGSUNG KE HOMEPAGE WIDGET
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     // Pastikan Anda telah mengimpor dan nama classnya adalah HomePage
        //     builder: (context) => const HomePage(),
        //   ),
        // );
        Navigator.pushReplacementNamed(context, "/");
      } else {
        // Tambahkan SnackBar jika login gagal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login gagal: ${response.token}'),
            backgroundColor: Colors.red,
          ), // token berisi pesan error jika status: false
        );
      }
      // ...
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error jaringan: $e')));
    }
  }

  Widget _inputRow(
    TextEditingController controller,
    String label, {
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: Colors.black12),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    controller == _passwordController &&
                            _passwordController.text.isNotEmpty
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.deepOrange,
                  ),
                  onPressed: () {
                    setState(() {
                      isPassword = !isPassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.receipt_long,
                size: 70,
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 18),
              const Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Login untuk menyimpan resep favoritmu",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 30),

              _inputRow(_emailController, "Email"),
              _inputRow(_passwordController, "Password", isPassword: true),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _doLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    "Masuk",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/registrasi'),
                child: const Text(
                  "Belum punya akun? Daftar",
                  style: TextStyle(fontSize: 14, color: Colors.deepOrange),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
