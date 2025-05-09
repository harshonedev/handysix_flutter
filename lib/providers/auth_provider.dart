import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_cricket/models/user_model.dart';
import 'package:hand_cricket/services/auth_service.dart';

class AuthProvider extends StateNotifier<AuthState> {
  final AuthService _authService;
  AuthProvider({required AuthService authService})
    : _authService = authService,
      super(AuthInitial());

  Future<void> signInWithGoogle() async {
    state = AuthLoading();
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        state = AuthSuccess(user);
      } else {
        state = AuthError('Failed to sign in with Google');
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signInAsGuest() async {
    state = AuthLoading();
    try {
      final user = await _authService.signInAnonymously();
      if (user != null) {
        state = AuthSuccess(user);
      } else {
        state = AuthError('Failed to sign in as guest');
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  void getCurrentUser() {
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email,
          name: user.displayName,
          avatar: user.photoURL,
        );
        state = Authenticated(userModel);
      } else {
        state = Unauthenticated();
      }
    } catch (e) {
      state = AuthError(e.toString());
    }
  }
}

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final UserModel user;
  AuthSuccess(this.user);
}

class Authenticated extends AuthState {
  final UserModel user;
  Authenticated(this.user);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String error;
  AuthError(this.error);
}
