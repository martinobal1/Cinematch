import 'package:flutter/material.dart';

/// Jeden bar: ľavá polovica IMDb (žltá), pravá ČSFD (modrá).
class ExternalRatingsBar extends StatelessWidget {
  const ExternalRatingsBar({
    super.key,
    this.imdbRating,
    this.csfdRating,
    this.height = 12,
    this.showLabels = false,
  });

  final double? imdbRating;
  final int? csfdRating;
  final double height;
  final bool showLabels;

  static const _imdbColor = Color(0xFFF5C518);
  static const _csfdColor = Color(0xFF3399FF);
  static const _trackColor = Color(0xFF2a2a2a);

  @override
  Widget build(BuildContext context) {
    final hasImdb = imdbRating != null;
    final hasCsfd = csfdRating != null;
    if (!hasImdb && !hasCsfd) return const SizedBox.shrink();

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            if (hasImdb)
              Expanded(
                child: _RatingHalf(
                  fill: (imdbRating! / 10).clamp(0.0, 1.0),
                  color: _imdbColor,
                ),
              ),
            if (hasImdb && hasCsfd) const SizedBox(width: 3),
            if (hasCsfd)
              Expanded(
                child: _RatingHalf(
                  fill: (csfdRating! / 100).clamp(0.0, 1.0),
                  color: _csfdColor,
                ),
              ),
          ],
        ),
      ),
    );

    if (!showLabels) return bar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (hasImdb)
              Expanded(
                child: Text(
                  'IMDb ${imdbRating!.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: _imdbColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (hasCsfd)
              Expanded(
                child: Text(
                  'ČSFD $csfdRating %',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: _csfdColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        bar,
      ],
    );
  }
}

class _RatingHalf extends StatelessWidget {
  const _RatingHalf({required this.fill, required this.color});

  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fillW = constraints.maxWidth * fill;
        return Stack(
          children: [
            Container(color: ExternalRatingsBar._trackColor),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: fillW,
              child: Container(color: color),
            ),
          ],
        );
      },
    );
  }
}
