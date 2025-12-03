import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String rating;
  final int steps;
  final String kategori;
  final String difficulty;
  final String author;

  const RecipeCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.rating,
    required this.steps,
    required this.kategori,
    required this.difficulty,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final cardWidth = MediaQuery.of(context).size.width * 0.45;
    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //gambar
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            child: Image.network(
              imageUrl,
              height: cardWidth,
              width: cardWidth,
              fit: BoxFit.cover,
            ),
          ),

          //isi aka padding
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //judl
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),

                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Text(
                      rating,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Icon(Icons.timer, color: Colors.grey, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '$steps langkah',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Spacer(),

                    Spacer(), // Mendorong widget berikutnya ke kanan
                    Icon(Icons.bookmark_border, color: Colors.grey, size: 20),
                  ],
                ),
                SizedBox(height: 8),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'kategori: $kategori',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),

                    Text(
                      'kesulitan: $difficulty',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Spacer(),

                    Text(
                      'author: $author',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
