import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ranked_movie.dart';
import '../services/top100_service.dart';
import '../widgets/movie_detail_sheet.dart';
import '../widgets/movie_poster.dart';
import '../widgets/top100_average_panel.dart';

class Top100Screen extends StatefulWidget {
  const Top100Screen({super.key});

  @override
  State<Top100Screen> createState() => _Top100ScreenState();
}

class _Top100ScreenState extends State<Top100Screen> {
  final _service = Top100Service();

  List<RankedMovie> _movies = [];
  bool _loading = true;
  String? _error;
  String _progress = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) _service.clearCache();

    setState(() {
      _loading = true;
      _error = null;
      _movies = [];
      _progress = 'Načítavam zoznam z TMDB…';
    });

    try {
      final movies = await _service.loadTop100(
        onProgress: (done, total, current) {
          if (mounted) {
            setState(() {
              _progress = 'IMDb + ČSFD: $done / $total filmov';
              _movies = current;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _movies = movies;
          _loading = false;
          _progress = '';
        });
      }
    } on Top100Exception catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Chyba: $e';
          _loading = false;
        });
      }
    }
  }

  void _openDetail(RankedMovie movie) {
    showMovieDetailSheet(context, movie.toRecommendation());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'TOP 100',
          style: GoogleFonts.bebasNeue(
            fontSize: 32,
            color: const Color(0xFFE50914),
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : () => _load(refresh: true),
            tooltip: 'Obnoviť',
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading && _movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFE50914)),
            const SizedBox(height: 20),
            Text(
              _progress,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Globálny rebríček podľa IMDb a ČSFD\n(prvé načítanie môže trvať 1–2 min)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    if (_movies.isEmpty) {
      return const Center(
        child: Text(
          'Nepodarilo sa načítať zoznam filmov.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_movies.length} filmov · IMDb + ČSFD · nie tvoje hodnotenia',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              if (_loading && _progress.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _progress,
                    style: const TextStyle(
                      color: Color(0xFFE50914),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: _movies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) => _Top100Tile(
              rank: i + 1,
              movie: _movies[i],
              onTap: () => _openDetail(_movies[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _Top100Tile extends StatelessWidget {
  const _Top100Tile({
    required this.rank,
    required this.movie,
    required this.onTap,
  });

  final int rank;
  final RankedMovie movie;
  final VoidCallback onTap;

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.white38;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1a1a1a),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: rank <= 3
                  ? _rankColor.withValues(alpha: 0.5)
                  : Colors.white10,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '#$rank',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 28,
                    color: _rankColor,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(
                width: 72,
                child: MoviePoster(
                  posterUrl: movie.posterUrl,
                  height: 108,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      movie.title,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 22,
                        color: Colors.white,
                        height: 1.05,
                      ),
                    ),
                    Text(
                      '${movie.year}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    if (movie.userStars != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tvoje hodnotenie: ${movie.userStars}/5 ★',
                        style: const TextStyle(
                          color: Color(0xFFF5C518),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Top100AveragePanel(movie: movie),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.touch_app, size: 14, color: Colors.white38),
                        SizedBox(width: 4),
                        Text(
                          'Klikni pre detail',
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
