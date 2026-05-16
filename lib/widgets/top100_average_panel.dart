import 'package:flutter/material.dart';

import '../models/ranked_movie.dart';
import 'external_ratings_bar.dart';

/// Priemery IMDb + ČSFD — len pre sekciu TOP 100.
class Top100AveragePanel extends StatelessWidget {
  const Top100AveragePanel({
    super.key,
    required this.movie,
  });

  final RankedMovie movie;

  @override
  Widget build(BuildContext context) {
    final imdbPct = movie.imdbPercent;
    final csfd = movie.csfdRating;
    final combined = RankedMovie.computeCombinedAverage(
          imdbRating: movie.imdbRating,
          csfdRating: movie.csfdRating,
        ) ??
        movie.combinedAverage;

    if (!movie.hasExternalRatings) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          movie.tmdbVote != null
              ? 'IMDb/ČSFD sa nenačítali · TMDB ${movie.tmdbVote!.toStringAsFixed(1)}/10'
              : 'Hodnotenia IMDb a ČSFD zatiaľ nie sú dostupné',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Priemerné hodnotenie',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5C518), Color(0xFF3399FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${combined.round()} %',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (imdbPct != null)
            _AverageRow(
              label: 'Priemer IMDb',
              value: '${movie.imdbRating!.toStringAsFixed(1)} / 10',
              subValue: '${imdbPct.round()} %',
              color: const Color(0xFFF5C518),
            ),
          if (imdbPct != null && csfd != null) const SizedBox(height: 6),
          if (csfd != null)
            _AverageRow(
              label: 'Priemer ČSFD',
              value: '$csfd %',
              subValue: null,
              color: const Color(0xFF3399FF),
            ),
          const SizedBox(height: 10),
          ExternalRatingsBar(
            imdbRating: movie.imdbRating,
            csfdRating: movie.csfdRating,
            height: 12,
          ),
        ],
      ),
    );
  }
}

class _AverageRow extends StatelessWidget {
  const _AverageRow({
    required this.label,
    required this.value,
    required this.color,
    this.subValue,
  });

  final String label;
  final String value;
  final String? subValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subValue != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '→ $subValue',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
