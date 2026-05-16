import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/intro_copy.dart';
import '../services/auth_service.dart';
import '../models/movie_recommendation.dart';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import '../services/poster_service.dart';
import '../services/rating_service.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/top100_screen.dart';
import '../services/user_profile_service.dart';
import '../widgets/user_avatar.dart';
import '../widgets/movie_card.dart';
import '../widgets/responsive_page_column.dart';
import '../widgets/submit_on_enter_field.dart';

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
  final _ratings = RatingService();
  AuthService? _auth;
  AuthService get auth => _auth ??= AuthService();
  final _profileService = UserProfileService();

  String _introTagline = '';
  String _hintExample = '';

  bool _isLoading = false;
  bool _loadingPosters = false;

  @override
  void initState() {
    super.initState();
    _introTagline = IntroCopy.randomTagline();
    _hintExample = IntroCopy.randomHint();
  }

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
      result = await _ratings.enrichWithRatings(result);

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
        title: LayoutBuilder(
          builder: (context, constraints) {
            final w = MediaQuery.sizeOf(context).width;
            final isWide = w >= 900;
            final titleWidth = isWide ? w * 0.7 : w;
            return Center(
              child: SizedBox(
                width: titleWidth,
                child: Text(
                  'CINEMATCH AI',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 36,
                    letterSpacing: 2,
                    color: const Color(0xFFE50914),
                  ),
                ),
              ),
            );
          },
        ),
        centerTitle: false,
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Top100Screen(),
                ),
              );
            },
            child: Text(
              'TOP 100',
              style: GoogleFonts.bebasNeue(
                fontSize: 20,
                color: const Color(0xFFE50914),
                letterSpacing: 1,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Moje hodnotenia',
            icon: const Icon(Icons.star_rounded, color: Color(0xFFF5C518)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MyRatingsScreen(),
                ),
              );
            },
          ),
          StreamBuilder<UserProfile>(
            stream: _profileService.watchProfile(),
            builder: (context, profileSnap) {
              final avatarId = profileSnap.data?.avatarId ?? 'user';
              return PopupMenuButton<String>(
                icon: UserAvatar(avatarId: avatarId, radius: 18),
                color: const Color(0xFF1a1a1a),
                onSelected: (value) async {
                  if (value == 'profile') {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  } else if (value == 'logout') {
                    await auth.signOut();
                  }
                },
                itemBuilder: (context) {
                  final email = FirebaseAuth.instance.currentUser?.email;
                  return [
                    if (email != null)
                      PopupMenuItem(
                        enabled: false,
                        child: Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 20, color: Colors.white70),
                          SizedBox(width: 10),
                          Text('Profil a heslo'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: Colors.white70),
                          SizedBox(width: 10),
                          Text('Odhlásiť sa'),
                        ],
                      ),
                    ),
                  ];
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ResponsivePageColumn(
          child: Column(
            children: [
            Padding(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Text(
                    _introTagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SubmitOnEnterField(
                    controller: _promptController,
                    maxLines: 3,
                    enabled: !_isLoading,
                    onSubmit: _search,
                    decoration: InputDecoration(
                      hintText: '$_hintExample\n',
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
                  'Načítavam plagáty a hodnotenia…',
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
      ),
    );
  }
}
