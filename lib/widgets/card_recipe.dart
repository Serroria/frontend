import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  // final String rating;
  final String cookingTime;
  // final int steps; // Dibiarkan sebagai comment/dihapus jika tidak digunakan
  final String kategori;
  final String difficulty;
  final String author;
  final int? recipeId;

  final VoidCallback? onSaveTapped;
  final bool isSaved;

  const RecipeCard({
    super.key,
    required this.imageUrl,
    required this.title,
    // required this.rating,
    required this.cookingTime,
    // required this.steps,
    required this.kategori,
    required this.difficulty,
    required this.author,
    this.recipeId,
    this.onSaveTapped,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    // Tetapkan ukuran cardWidth berdasarkan 45% dari lebar layar
    final cardWidth = MediaQuery.of(context).size.width * 0.45;

    // Nilai radius sudut agar konsisten
    const cardBorderRadius = 10.0;

    return Container(
      width: cardWidth,
      // Gunakan Card widget untuk tampilan shadow dan radius yang lebih mudah
      child: Card(
        // Menghilangkan elevation Card bawaan dan menggantinya dengan BoxShadow kustom
        // atau biarkan elevation jika lebih suka shadow bawaan Card
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
        margin: EdgeInsets.zero, // Hapus margin default Card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            ClipRRect(
              // Terapkan hanya pada sudut atas gambar
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(cardBorderRadius),
              ),
              child: Image.network(
                imageUrl.isNotEmpty
                    ? imageUrl
                    : 'https://via.placeholder.com/200x200?text=No+Image',
                height: cardWidth * 0.9,
                width: cardWidth,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: cardWidth * 0.9,
                    width: cardWidth,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.fastfood,
                        color: Colors.grey[500],
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Konten Teks
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                    height: 8,
                  ), // Sedikit ruang antar judul dan detail
                  // Baris Rating dan Timer/Save

                  // Detail (Kategori, Kesulitan) - Dikonsolidasi
                  Text(
                    'Kategori: $kategori',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  Text(
                    'Kesulitan: $difficulty',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.start, // Agar save button di kanan
                    children: [
                      // Row(
                      //   children: [
                      //     // const Icon(Icons.star, color: Colors.amber, size: 14),
                      //     // const SizedBox(width: 4),
                      //     // Text(
                      //     //   // rating,
                      //     //   // style: TextStyle(
                      //     //   //   fontSize: 12,
                      //     //   //   color: Colors.grey[600],
                      //     //   // ),
                      //     // ),
                      //     const SizedBox(
                      //       width: 8,
                      //     ), // Jarak antara rating dan timer
                      //     // const Icon(Icons.timer, color: Colors.grey, size: 14),
                      //     // const SizedBox(width: 4),
                      //     // const Text(
                      //     //   '0m', // Ganti dengan data steps atau waktu jika ada
                      //     //   style: TextStyle(fontSize: 12, color: Colors.grey),
                      //     // ),
                      //   ],
                      // ),
                      const Spacer(),
                      // Ikon Simpan
                      GestureDetector(
                        onTap: onSaveTapped,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            right: 0.0,
                          ), // Padding dihilangkan, cukup pakai padding Row
                          child: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved ? Colors.deepOrange : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Penulis
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end, // Dorong ke kanan
                    children: [
                      Text(
                        author,
                        // 'Author: $author',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
