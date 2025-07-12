import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hand_cricket/controllers/game_controller.dart';
import 'package:hand_cricket/providers/auth_provider.dart' as auth_provider;
import 'package:hand_cricket/services/auth_service.dart';
import 'package:hand_cricket/services/game_firestore_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.read(firebaseAuthProvider);
  final googleSignIn = ref.read(googleSignInProvider);
  final firestore = ref.read(firestoreProvider);
  return AuthService(firebaseAuth, googleSignIn, firestore);
});

final authProvider =
    StateNotifierProvider<auth_provider.AuthProvider, auth_provider.AuthState>((
      ref,
    ) {
      final authService = ref.read(authServiceProvider);
      return auth_provider.AuthProvider(authService: authService);
    });

final gameFirestoreServiceProvider = Provider<GameFirestoreService>(
  (ref) => GameFirestoreService(firestore: ref.read(firestoreProvider)),
);
final gameController = StateNotifierProvider<GameController, GameState>(
  (ref) => GameController(
    authService: ref.read(authServiceProvider),
    gameFirestoreService: ref.read(gameFirestoreServiceProvider),
  ),
);
