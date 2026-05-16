import 'package:flutter/material.dart';

/// IMDb + ČSFD hodnotenia v jednom riadku.
class MovieRatingsRow extends StatelessWidget {
  const MovieRatingsRow({
    super.key,
    this.imdbRating,
    this.csfdRating,
    this.compact = false,
  });

  final double? imdbRating;
  final int? csfdRating;
  final bool compact;

  bool get hasAny => imdbRating != null || csfdRating != null;

  @override
  Widget build(BuildContext context) {
    if (!hasAny) return const SizedBox.shrink();

    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: 6,
      children: [
        if (imdbRating != null)
          _RatingBadge(
            label: 'IMDb',
            value: imdbRating!.toStringAsFixed(1),
            background: const Color(0xFFF5C518),
            foreground: Colors.black,
            compact: compact,
          ),
        if (csfdRating != null)
          _RatingBadge(
            label: 'ČSFD',
            value: '$csfdRating %',
            background: const Color(0xFF3399FF),
            foreground: Colors.white,
            compact: compact,
          ),
      ],
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
    required this.compact,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.85),
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
