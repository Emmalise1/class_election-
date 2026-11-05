import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login_screen.dart';
import '../repositories/candidate_repository.dart';
import '../repositories/photo_repository.dart'; // NEW
import '../state/candidate_state.dart';
import '../main.dart'; // Imports VoteScreen from main.dart

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == null) {
          return const LoginScreen();
        }

        // Signed in: create the brain for this user and hand it to the VoteScreen
        final user = snapshot.data!;
        return ChangeNotifierProvider<CandidateState>(
          // CHANGED: Added the PhotoRepository here
          create: (_) => CandidateState(
            CandidateRepository(user.uid),
            PhotoRepository(),
          ),
          child: const VoteScreen(),
        );
      },
    );
  }
}