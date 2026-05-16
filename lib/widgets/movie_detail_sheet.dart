import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/movie_recommendation.dart';
import '../services/user_rating_service.dart';
import 'external_ratings_bar.dart';
import 'movie_poster.dart';
import 'movie_ratings_row.dart';
import 'star_rating_input.dart';

void showMovieDetailSheet(BuildContext context, MovieRecommendation movie) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF141414),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _MovieDetailSheet(movie: movie),
  );
}

class _MovieDetailSheet extends StatefulWidget {
  const _MovieDetailSheet({required this.movie});

  final MovieRecommendation movie;

  @override
  State<_MovieDetailSheet> createState() => _MovieDetailSheetState();
}

class _MovieDetailSheetState extends State<_MovieDetailSheet> {
  final _ratingService = UserRatingService();
  int _myStars = 0;
  bool _loadingStars = true;
  bool _saving = false;

  MovieRecommendation get movie => widget.movie;

  @override
  void initState() {
    super.initState();
    _loadMyStars();
  }

  Future<void> _loadMyStars() async {
    final stars = await _ratingService.getMyStarsFor(movie.title, movie.year);
    if (mounted) {
      setState(() {
        _myStars = stars ?? 0;
        _loadingStars = false;
      });
    }
  }

  Future<void> _saveStars(int stars) async {
    if (stars < 1) return;
    setState(() => _saving = true);
    try {
      await _ratingService.saveRating(movie: movie, stars: stars);
      if (mounted) {
        setState(() => _myStars = stars);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hodnotenie $stars/5 uložené do zoznamu'),
            backgroundColor: const Color(0xFF1a1a1a),
          ),
        );
      }
    } on UserRatingException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MoviePoster(
              posterUrl: movie.posterUrl,
              height: 280,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  if (movie.imdbRating != null || movie.csfdRating != null) ...[
                    const SizedBox(height: 12),
                    MovieRatingsRow(
                      imdbRating: movie.imdbRating,
                      csfdRating: movie.csfdRating,
                    ),
                    const SizedBox(height: 10),
                    ExternalRatingsBar(
                      imdbRating: movie.imdbRating,
                      csfdRating: movie.csfdRating,
                      showLabels: true,
                      height: 14,
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Moje hodnotenie',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1–5 hviezdičiek · uloží sa do Moje hodnotenia',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingStars)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    StarRatingInput(
                      value: _myStars,
                      size: 40,
                      enabled: !_saving,
                      onChanged: (stars) {
                        setState(() => _myStars = stars);
                        if (stars >= 1) _saveStars(stars);
                      },
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: movie.moodTags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.1),
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
                      style:
                          const TextStyle(color: Colors.white70, height: 1.6),
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
          ],
        ),
      ),
    );
  }
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
