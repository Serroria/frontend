import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/recipe_model.dart';

class TambahResepPage extends StatefulWidget {
  //const TambahResepPage({super.key});
  final RecipeModel? recipeToEdit;

  const TambahResepPage({
    super.key,
    this.recipeToEdit, // ✅ Tambahkan parameter ini
  });

  @override
  State<TambahResepPage> createState() => _TambahResepPageState();
}

class _TambahResepPageState extends State<TambahResepPage> {
  final _apiService = ApiService(); // ✅ TARUH DISINI

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  File? _imageFile;
  String? _selectedKategori;
  String _difficulty = 'Mudah';

  final List<String> _difficultyLevels = ['Mudah', 'Sedang', 'Sulit'];
  final List<String> _kategoriList = [
    'Nusantara',
    'Asia',
    'Western',
    'Vegetarian',
    'Minuman',
  ];

  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submitRecipe() async {
    if (_formKey.currentState!.validate() && _selectedKategori != null) {
      setState(() => _isLoading = true);

      final Map<String, dynamic> newRecipeData = {
        'title': _titleController.text,
        'kategori': _selectedKategori!,
        'description': _descriptionController.text,
        'ingredients': _ingredientsController.text,
        'steps': _stepsController.text,
        'time': _timeController.text,
        'difficulty': _difficulty,
        'rating': 0, // ✅ kalau belum mau pake rating
        'user_id': 1,
      };

      try {
        // ✅ PANGGIL PAKE INSTANCE, JANGAN STATIC LAGI
        final result = await _apiService.postRecipe(newRecipeData, _imageFile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Resep berhasil disimpan!")),
          );
          Navigator.pop(context, result);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Gagal menyimpan resep: $e")));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Tambah Resep Baru",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitRecipe,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    "Simpan",
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ IMAGE PICKER PREVIEW
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Tambahkan Foto Resep",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              _inputField(
                "Judul Resep",
                "Contoh: Ayam Bakar",
                _titleController,
                (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),

              _inputField(
                "Deskripsi",
                "Jelaskan resep ini...",
                _descriptionController,
                (v) => v!.isEmpty ? "Wajib diisi" : null,
                4,
              ),
              const SizedBox(height: 16),

              // ✅ DROPDOWN KATEGORI
              const Text(
                "Kategori",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                hint: const Text("Pilih Kategori"),
                items: _kategoriList
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedKategori = v),
                validator: (v) => v == null ? "Kategori harus dipilih" : null,
                decoration: _dropdownStyle(),
              ),

              const SizedBox(height: 16),

              _inputField(
                "Waktu Memasak",
                "30 menit",
                _timeController,
                (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 16),

              // ✅ DROPDOWN DIFFICULTY
              const Text(
                "Tingkat Kesulitan",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _difficulty,
                items: _difficultyLevels
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _difficulty = v!),
                decoration: _dropdownStyle(),
              ),
              const SizedBox(height: 16),

              _inputField(
                "Bahan–bahan",
                "1 sdt garam, 200g ayam...",
                _ingredientsController,
                (v) => v!.isEmpty ? "Wajib diisi" : null,
                5,
              ),
              const SizedBox(height: 16),

              _inputField(
                "Langkah–langkah",
                "1. Panaskan minyak...\n2. Masukkan bumbu...",
                _stepsController,
                (v) => v!.isEmpty ? "Wajib diisi" : null,
                7,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ WIDGET INPUT REUSABLE
  Widget _inputField(
    String label,
    String hint,
    TextEditingController ctrl,
    String? Function(String?) val, [
    int line = 1,
  ]) {
    return TextFormField(
      controller: ctrl,
      validator: val,
      maxLines: line,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }

  // ✅ STYLE DROPDOWN
  InputDecoration _dropdownStyle() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }

  // ✅ OPTIONAL: special rename supaya gak tabrakan method lain
  Widget _inputFieldWrapper() => const SizedBox.shrink();
}
