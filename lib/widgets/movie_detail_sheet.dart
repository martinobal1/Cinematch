import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/movie_recommendation.dart';
import 'mood_palette_bar.dart';

void showMovieDetailSheet(BuildContext context, MovieRecommendation movie) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              movie.title,
              style: GoogleFonts.bebasNeue(
                fontSize: 36,
                color: const Color(0xFFE50914),
              ),
            ),
            Text(
              'Rok ${movie.year}',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Náladová paleta',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            MoodPaletteBar(colors: movie.moodColors),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: movie.moodTags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Prečo práve tento film',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.reason,
              style: const TextStyle(color: Colors.white70, height: 1.6),
            ),
            if (movie.personalReview != null &&
                movie.personalReview!.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'AI recenzia pre teba',
                style: TextStyle(
                  color: Color(0xFFE50914),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                movie.personalReview!,
                style: const TextStyle(color: Colors.white70, height: 1.6),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openTrailer(movie),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Pozrieť trailer na YouTube'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _openTrailer(MovieRecommendation movie) async {
  final query = Uri.encodeComponent(
    movie.trailerQuery ?? '${movie.title} ${movie.year} official trailer',
  );
  final uri = Uri.parse('https://www.youtube.com/results?search_query=$query');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
