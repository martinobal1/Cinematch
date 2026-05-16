import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_movie_rating.dart';
import '../services/user_rating_service.dart';
import '../widgets/external_ratings_bar.dart';
import '../widgets/movie_poster.dart';
import '../widgets/star_rating_input.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = UserRatingService();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Moje hodnotenia',
          style: GoogleFonts.bebasNeue(
            fontSize: 28,
            color: const Color(0xFFE50914),
            letterSpacing: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<UserMovieRating>>(
            stream: service.watchMyRatings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE50914)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nepodarilo sa načítať hodnotenia:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final ratings = snapshot.data ?? [];
              if (ratings.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_border_rounded,
                          size: 72,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Zatiaľ nemáš žiadne hodnotenia',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pri filme daj hviezdičky 1–5 a objaví sa tu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: ratings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _RatingListTile(
                  rating: ratings[i],
                  onDelete: () => service.deleteRating(ratings[i].id),
                ),
              );
            },
          ),
      ),
    );
  }
}

class _RatingListTile extends StatelessWidget {
  const _RatingListTile({
    required this.rating,
    required this.onDelete,
  });

  final UserMovieRating rating;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date =
        '${rating.ratedAt.day}.${rating.ratedAt.month}.${rating.ratedAt.year}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 68,
              child: MoviePoster(
                posterUrl: rating.posterUrl,
                height: 100,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rating.title,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 24,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    '${rating.year} · $date',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  StarRatingDisplay(stars: rating.stars, size: 22),
                  if (rating.imdbRating != null || rating.csfdRating != null) ...[
                    const SizedBox(height: 10),
                    ExternalRatingsBar(
                      imdbRating: rating.imdbRating,
                      csfdRating: rating.csfdRating,
                      showLabels: true,
                      height: 10,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white38),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1a1a1a),
                    title: const Text('Zmazať hodnotenie?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Zrušiť'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE50914),
                        ),
                        child: const Text('Zmazať'),
                      ),
                    ],
                  ),
                );
                if (ok == true) onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
