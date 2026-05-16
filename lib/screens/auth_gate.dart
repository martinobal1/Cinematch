import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Po prihlásení → domov; inak prihlásenie / registrácia.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return Navigator(
          initialRoute: '/login',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/register':
                return MaterialPageRoute<void>(
                  builder: (_) => const RegisterScreen(),
                  settings: settings,
                );
              case '/login':
              default:
                return MaterialPageRoute<void>(
                  builder: (_) => const LoginScreen(),
                  settings: settings,
                );
            }
          },
        );
      },
    );
  }
}
