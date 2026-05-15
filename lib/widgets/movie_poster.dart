import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MoviePoster extends StatelessWidget {
  const MoviePoster({
    super.key,
    this.posterUrl,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fallbackIconSize = 48,
  });

  final String? posterUrl;
  final double? height;
  final BorderRadius borderRadius;
  final double fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    final hasUrl = posterUrl != null && posterUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: borderRadius,
      child: hasUrl
          ? CachedNetworkImage(
              imageUrl: posterUrl!,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(showSpinner: true),
              errorWidget: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder({bool showSpinner = false}) {
    return Container(
      height: height ?? 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
          ],
        ),
      ),
      child: Center(
        child: showSpinner
            ? const CircularProgressIndicator(
                color: Color(0xFFE50914),
                strokeWidth: 2,
              )
            : Icon(
                Icons.movie_outlined,
                size: fallbackIconSize,
                color: Colors.white24,
              ),
      ),
    );
  }
}
