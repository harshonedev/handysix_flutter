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
    state = AuthLoading(authType: AuthType.google);
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
    state = AuthLoading(authType: AuthType.anonymous);
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

  Future<void> getCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        state = Authenticated(user);
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

class AuthLoading extends AuthState {
  final AuthType authType;
  AuthLoading({ required this.authType});
}

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

enum AuthType {
  google,
  anonymous,
}
