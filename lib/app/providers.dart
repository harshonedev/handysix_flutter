import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hand_cricket/providers/game/online_game_provider_socket.dart';
import 'package:hand_cricket/providers/game/practice_game_provider.dart';
import 'package:hand_cricket/providers/auth/auth_provider.dart'
    as auth_provider;
import 'package:hand_cricket/providers/game/game_state.dart';
import 'package:hand_cricket/services/auth_service.dart';
import 'package:hand_cricket/services/game_firestore_service.dart';
import 'package:hand_cricket/services/game_socket_service.dart';

// Socket.IO server URL - update this with your server URL
const String socketServerUrl = 'http://localhost:5000'; // Change for production

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.read(firebaseAuthProvider);
  final googleSignIn = ref.read(googleSignInProvider);
  final firestore = ref.read(firestoreProvider);
  final dio = ref.read(dioProvider);
  return AuthService(
    auth: firebaseAuth,
    googleSignIn: googleSignIn,
    firestore: firestore,
    dio: dio,
  );
});

final authProvider =
    StateNotifierProvider<auth_provider.AuthProvider, auth_provider.AuthState>((
      ref,
    ) {
      final authService = ref.read(authServiceProvider);
      return auth_provider.AuthProvider(authService: authService);
    });

// Socket service provider - initialized when needed
final gameSocketServiceProvider = Provider<GameSocketService?>((ref) {
  final user = ref.watch(authServiceProvider).getCurrentAuthUser();

  if (user == null) {
    return null;
  }

  final socketService = GameSocketService(
    serverUrl: socketServerUrl,
    userId: user.uid,
    userName: user.displayName ?? 'Guest',
    userEmail: user.email,
  );

  // Cleanup on dispose
  ref.onDispose(() {
    socketService.dispose();
  });

  return socketService;
});

final gameFirestoreServiceProvider = Provider<GameFirestoreService>(
  (ref) => GameFirestoreService(firestore: ref.read(firestoreProvider)),
);

final practiceGameProvider =
    StateNotifierProvider<PracticeGameProvider, GameState>(
      (ref) => PracticeGameProvider(authService: ref.read(authServiceProvider)),
    );

// Online game provider using Socket.IO
final onlineGameProvider =
    StateNotifierProvider<OnlineGameProvider, GameState>(
      (ref) => OnlineGameProvider(
        authService: ref.read(authServiceProvider),
        gameSocketService: ref.read(gameSocketServiceProvider),
      ),
    );
