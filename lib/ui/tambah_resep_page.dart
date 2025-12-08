import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late TextEditingController _titleController = TextEditingController();
  late TextEditingController _descriptionController = TextEditingController();
  late TextEditingController _ingredientsController = TextEditingController();
  late TextEditingController _stepsController = TextEditingController();
  late TextEditingController _timeController = TextEditingController();
  bool _isPickingImage = false;

  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    // 1. Tentukan Mode: Edit atau Tambah
    _isEditing = widget.recipeToEdit != null;

    if (_isEditing) {
      // --- MODE EDIT ---
      final resep = widget.recipeToEdit!;

      // A. Inisialisasi Controllers dengan data lama
      _titleController = TextEditingController(text: resep.title);
      _descriptionController = TextEditingController(text: resep.description);
      _ingredientsController = TextEditingController(text: resep.ingredients);
      _stepsController = TextEditingController(text: resep.steps);
      _timeController = TextEditingController(text: resep.time);

      // B. Inisialisasi Dropdown States
      _selectedKategori = _kategoriList.contains(resep.kategori)
          ? resep.kategori
          : _kategoriList[0]; // Pastikan nilai default/lama ada di daftar _kategoriList

      _selectedKategori = resep.kategori;
      _difficulty = resep.difficulty;

      // C. Atur _imageFile (Jika gambar lama tersedia, kita abaikan dulu file/URL-nya,
      // tapi logikanya akan ada di sini jika Anda mau menampilkannya)
      // Kita hanya bisa mengisi _imageFile jika itu adalah objek File lokal,
      // bukan URL jaringan. Untuk edit, kita tampilkan gambar lama via URL jika tidak ada file baru.
    } else {
      // --- MODE TAMBAH BARU ---
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _ingredientsController = TextEditingController();
      _stepsController = TextEditingController();
      _timeController = TextEditingController();

      // Nilai default untuk dropdown
      _selectedKategori = _kategoriList[0]; // Nusantara sebagai default
      _difficulty = 'Mudah';
    }
  }

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  late String? _selectedKategori;
  late String _difficulty = 'Mudah';

  final List<String> _difficultyLevels = ['Mudah', 'Sedang', 'Sulit'];
  final List<String> _kategoriList = [
    'Nusantara',
    'Asia',
    'Internasional',
    'Vegan',
    'Dessert',
  ];

  bool _isLoading = false;

  Future<void> _pickImage() async {
    // 1. Cek status: Jika sedang memilih gambar, keluar dari fungsi.
    if (_isPickingImage) {
      return;
    }

    // 2. Set status menjadi aktif dan perbarui UI (jika diperlukan)
    setState(() {
      _isPickingImage = true;
    });

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Hanya perbarui state jika file ditemukan
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      // Menangkap error Image Picker (termasuk 'already_active')
      print('Terjadi error saat memilih gambar: $e');
    } finally {
      // 3. SELALU set status kembali menjadi non-aktif setelah proses selesai (di try atau catch)
      setState(() {
        _isPickingImage = false;
      });
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

  void _submitRecipe() async {
    if (_formKey.currentState!.validate() && _selectedKategori != null) {
      setState(() => _isLoading = true);

      final Map<String, dynamic> dataToSubmit = {
        'title': _titleController.text.trim(),
        'kategori': _selectedKategori!,
        'description': _descriptionController.text.trim(),
        'ingredients': _ingredientsController.text.trim(),
        'steps': _stepsController.text.trim(),
        'time': _timeController.text.trim(),
        'difficulty': _difficulty,
      };

      try {
        if (_isEditing && widget.recipeToEdit != null) {
          // --- MODE EDIT ---
          print('DEBUG: Submitting EDIT - ID: ${widget.recipeToEdit!.id}');
          print('DEBUG: Data: $dataToSubmit');

          // Pastikan sertakan user_id saat update, agar backend dapat memvalidasi
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getInt('userId');
          if (userId != null) dataToSubmit['user_id'] = userId;

          await _apiService.updateRecipe(
            widget.recipeToEdit!.id,
            dataToSubmit,
            imageFile: _imageFile,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Resep berhasil diperbarui!")),
            );
          }
        } else {
          // --- MODE TAMBAH BARU ---
          print('DEBUG: Submitting CREATE - Data: $dataToSubmit');

          // Ambil user_id dari SharedPreferences untuk POST baru
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getInt('userId') ?? 1;
          dataToSubmit['user_id'] = userId;

          await _apiService.postRecipe(dataToSubmit, _imageFile);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Resep berhasil ditambahkan!")),
            );
          }
        }

        if (mounted) {
          // Kirim sinyal refresh ke halaman sebelumnya
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          print('DEBUG: Submit Error: $e');
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Resep' : "Tambah Resep Baru",
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
}
