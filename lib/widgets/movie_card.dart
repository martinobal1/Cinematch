import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/movie_recommendation.dart';
import 'mood_palette_bar.dart';
import 'movie_detail_sheet.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});

  final MovieRecommendation movie;

  @override
  Widget build(BuildContext context) {
    final gradientColors = movie.moodColors.isEmpty
        ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
        : movie.moodColors
            .map((c) => Color(0xFF000000 | c))
            .take(2)
            .toList();

    return GestureDetector(
      onTap: () => showMovieDetailSheet(context, movie),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      movie.title,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 28,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${movie.year}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MoodPaletteBar(colors: movie.moodColors),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: movie.moodTags
                    .take(4)
                    .map(
                      (tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                movie.reason,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.touch_app, size: 16, color: Colors.white54),
                  SizedBox(width: 6),
                  Text(
                    'Klikni pre detail a trailer',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
