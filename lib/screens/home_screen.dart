import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/movie_recommendation.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../services/poster_service.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _promptController = TextEditingController();
  final _gemini = GeminiService();
  final _firestore = FirestoreService();
  final _posters = PosterService();

  bool _isLoading = false;
  bool _loadingPosters = false;
  String? _error;
  RecommendationResult? _result;
  String? _firebaseNote;

  Future<void> _search() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
      _firebaseNote = null;
      _loadingPosters = false;
    });

    try {
      var result = await _gemini.recommendMovies(text);

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
          _loadingPosters = true;
        });
      }

      result = await _posters.enrichWithPosters(result);

      try {
        await _firestore.saveRecommendation(
          userPrompt: text,
          result: result,
        );
        _firebaseNote = 'Uložené do Firebase Firestore ✓';
      } catch (e) {
        _firebaseNote =
            'AI funguje, ale Firebase zápis zlyhal: $e\n'
            'Skontroluj Firestore v konzole a pravidlá (firestore.rules).';
      }

      if (mounted) {
        setState(() {
          _result = result;
          _loadingPosters = false;
        });
      }
    } on GeminiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Chyba: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingPosters = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'CINEMATCH AI',
          style: GoogleFonts.bebasNeue(
            fontSize: 36,
            letterSpacing: 2,
            color: const Color(0xFFE50914),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Text(
                    'Opíš svoju náladu prirodzene — AI nájde 3–5 filmov '
                    's náladovou paletou a dôvodmi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _promptController,
                    maxLines: 3,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText:
                          'napr. Som unavený po škole, chcem mysteriózne '
                          'nie horor, jesenná atmosféra...',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFE50914),
                        ),
                        onPressed: _isLoading ? null : _search,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _search,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE50914),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Nájsť filmy'),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_firebaseNote != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _firebaseNote!,
                  style: TextStyle(
                    color: _firebaseNote!.contains('✓')
                        ? Colors.greenAccent
                        : Colors.amber,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_loadingPosters)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Načítavam plagáty filmov…',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            if (_result != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _result!.summary,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _result!.movies.length,
                  itemBuilder: (_, i) => MovieCard(movie: _result!.movies[i]),
                ),
              ),
            ] else if (!_isLoading && _error == null)
              const Expanded(
                child: Center(
                  child: Icon(
                    Icons.movie_filter_outlined,
                    size: 80,
                    color: Colors.white12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
