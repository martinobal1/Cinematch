import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/avatar_presets.dart';
import '../services/user_profile_service.dart';
import '../widgets/responsive_page_column.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profile = UserProfileService();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _savingAvatar = false;
  bool _savingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _message;
  bool _messageIsError = false;
  String _selectedAvatar = 'user';

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _saveAvatar(String avatarId) async {
    setState(() {
      _savingAvatar = true;
      _selectedAvatar = avatarId;
      _message = null;
    });

    try {
      await _profile.setAvatarId(avatarId);
      if (mounted) {
        setState(() {
          _message = 'Avatar uložený ✓';
          _messageIsError = false;
        });
      }
    } on ProfileException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.message;
          _messageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _savingAvatar = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPassword.text != _confirmPassword.text) {
      setState(() {
        _message = 'Nové heslá sa nezhodujú.';
        _messageIsError = true;
      });
      return;
    }

    setState(() {
      _savingPassword = true;
      _message = null;
    });

    try {
      await _profile.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      if (mounted) {
        setState(() {
          _message = 'Heslo bolo zmenené ✓';
          _messageIsError = false;
        });
      }
    } on ProfileException catch (e) {
      if (mounted) {
        setState(() {
          _message = e.message;
          _messageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Profil',
          style: GoogleFonts.bebasNeue(
            fontSize: 28,
            color: const Color(0xFFE50914),
            letterSpacing: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsivePageColumn(
          child: StreamBuilder<UserProfile>(
            stream: _profile.watchProfile(),
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final avatarId = profile?.avatarId ?? _selectedAvatar;

              return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      UserAvatar(avatarId: avatarId, radius: 44),
                      const SizedBox(height: 12),
                      if (email != null)
                        Text(
                          email,
                          style: const TextStyle(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Vyber si avatar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: avatarPresets.length,
                  itemBuilder: (context, i) {
                    final preset = avatarPresets[i];
                    final selected = preset.id == avatarId;
                    return InkWell(
                      onTap: _savingAvatar
                          ? null
                          : () => _saveAvatar(preset.id),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: preset.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? preset.color
                                : Colors.white12,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(preset.icon, color: preset.color, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              preset.label,
                              style: TextStyle(
                                color: preset.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Text(
                  'Zmena hesla',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _currentPassword,
                  obscureText: _obscureCurrent,
                  decoration: _inputDecoration('Súčasné heslo').copyWith(
                    suffixIcon: _visibilityToggle(
                      _obscureCurrent,
                      () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _newPassword,
                  obscureText: _obscureNew,
                  decoration: _inputDecoration('Nové heslo (min. 6)').copyWith(
                    suffixIcon: _visibilityToggle(
                      _obscureNew,
                      () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmPassword,
                  obscureText: _obscureConfirm,
                  onSubmitted: (_) => _changePassword(),
                  decoration: _inputDecoration('Potvrď nové heslo').copyWith(
                    suffixIcon: _visibilityToggle(
                      _obscureConfirm,
                      () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _savingPassword ? null : _changePassword,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _savingPassword
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Zmeniť heslo'),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _messageIsError
                          ? Colors.redAccent
                          : Colors.greenAccent,
                    ),
                  ),
                ],
              ],
              );
            },
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _visibilityToggle(bool obscure, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Colors.white54,
      ),
      onPressed: onPressed,
    );
  }
}
