import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hand_cricket/providers/auth_provider.dart' as auth_provider;
import 'package:hand_cricket/services/auth_service.dart';

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
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final googleSignIn = ref.watch(googleSignInProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthService(firebaseAuth, googleSignIn, firestore);
});

final authProvider = StateNotifierProvider<auth_provider.AuthProvider, auth_provider.AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return auth_provider.AuthProvider(authService: authService);
});




