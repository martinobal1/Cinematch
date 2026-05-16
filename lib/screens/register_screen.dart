import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_screen_layout.dart';
import '../widgets/submit_on_enter_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  AuthService? _auth;
  AuthService get auth => _auth ??= AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await auth.register(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Chyba: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      title: 'Registrácia',
      subtitle: 'Vytvor si účet a začni objavovať filmy podľa nálady.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SubmitOnEnterFormField(
              controller: _emailController,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmit: _submit,
              onNext: () => _passwordFocus.requestFocus(),
              decoration: authInputDecoration(
                label: 'E-mail',
                icon: Icons.email_outlined,
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Zadaj e-mail';
                if (!value.contains('@')) return 'Neplatný e-mail';
                return null;
              },
            ),
            const SizedBox(height: 14),
            Focus(
              focusNode: _passwordFocus,
              child: SubmitOnEnterFormField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                onSubmit: _submit,
                onNext: () => _confirmFocus.requestFocus(),
                decoration: authInputDecoration(
                  label: 'Heslo (min. 6 znakov)',
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white54,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if ((v ?? '').length < 6) {
                    return 'Heslo musí mať aspoň 6 znakov';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            Focus(
              focusNode: _confirmFocus,
              child: SubmitOnEnterFormField(
                controller: _confirmController,
                enabled: !_isLoading,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onSubmit: _submit,
                decoration: authInputDecoration(
                  label: 'Potvrď heslo',
                  icon: Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white54,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v != _passwordController.text) {
                    return 'Heslá sa nezhodujú';
                  }
                  return null;
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
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
                  : const Text('Vytvoriť účet'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Už máš účet?', style: TextStyle(color: Colors.white54)),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Prihlásenie'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
