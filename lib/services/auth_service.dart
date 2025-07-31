import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hand_cricket/core/contstants/secure_constants.dart';
import 'package:hand_cricket/core/failures/failures.dart';
import 'package:hand_cricket/models/user_model.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  final Dio _dio;
  final Logger _logger = Logger();

  AuthService({
    required FirebaseAuth auth,
    required GoogleSignIn googleSignIn,
    required FirebaseFirestore firestore,
    required Dio dio,
  }) : _auth = auth,
       _googleSignIn = googleSignIn,
       _firestore = firestore,
       _dio = dio;

  // Sign in whith google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _logger.e('Google sign-in aborted');
        throw Exception('Google sign-in aborted');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // This token can be used to authenticate with your backend
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;
      if (user == null) {
        _logger.e('User is null after Google sign-in');
        throw AuthFailure('User is null after Google sign-in');
      }

      final data = await _loginRequest(
        uid: user.uid,
        email: user.email,
        name: user.displayName,
        profilePictureUrl: user.photoURL,
      );

      if (data.isEmpty) {
        _logger.e('User data is empty after login request');
        throw AuthFailure('User data is empty after login request');
      }

      final userModel = UserModel.fromJson(data);
      _logger.d('User signed in with Google: $userModel');
      return userModel;
    } catch (e) {
      _logger.e('Error signing in with Google: $e');
      throw Exception('Failed to sign in with Google');
    }
  }

  // Sign in anonymously
  Future<UserModel?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();

      if (userCredential.user == null) {
        _logger.e('User is null after anonymous sign-in');
        throw AuthFailure('User is null after anonymous sign-in');
      }

      final user = userCredential.user!;
      final data = await _loginRequest(
        uid: user.uid,
        email: user.email,
        name: user.displayName,
        profilePictureUrl: user.photoURL,
      );
      if (data.isEmpty) {
        _logger.e('User data is empty after anonymous login request');
        throw AuthFailure('User data is empty after anonymous login request');
      }
      final userModel = UserModel.fromJson(data);
      _logger.d('User signed in anonymously: $userModel');
      return userModel;
    } catch (e) {
      _logger.e('Error signing in anonymously: $e');
      throw Exception('Failed to sign in anonymously');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final user = getCurrentAuthUser();
      if (user == null) {
        return null;
      }

      final docSnap = await _firestore.collection('users').doc(user.uid).get();
      final data = docSnap.data();
      if (data == null || data.isEmpty) {
        return null;
      }
      data['uid'] = docSnap.id;
      return UserModel.fromJson(data);
    } catch (e) {
      _logger.e('Error while getCurrentUser - $e');
      throw Exception('Failed to get user from server');
    }
  }

  // Get current user
  User? getCurrentAuthUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      _logger.e('Error getting current user: $e');
      throw Exception('Failed to get current user from firebase');
    }
  }

  Future<Map<String, dynamic>> _loginRequest({
    required String uid,
    String? email,
    String? name,
    String? profilePictureUrl,
  }) async {
    try {
      final baseUrl = SecureConstants.baseUrl;

      final response = await _dio.post(
        '$baseUrl/users/login',
        data: {
          'uid': uid,
          'email': email,
          'name': name,
          'profilePictureUrl': profilePictureUrl,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.d('Login request successful: ${response.data}');
        if (response.data is! Map<String, dynamic> &&
            response.data['success'] != true) {
          _logger.e(
            'Response data is not in expected format: ${response.data} ',
          );
          throw ServerFailure('Invalid response format');
        }
        // check if 'user' key exists in response data
        if (!response.data.containsKey('user')) {
          _logger.e(
            'Response data does not contain "user" key: ${response.data}',
          );
          throw ServerFailure('User data not found in response');
        }
        return response.data['user'] as Map<String, dynamic>;
      } else {
        _logger.e('Login request failed with status: ${response.statusCode}');
        throw ServerFailure('Failed to log in user');
      }
    } on DioException catch (e) {
      _logger.e('DioException during login request: $e');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkFailure('Network error occurred during login');
      } else {
        throw ServerFailure('Failed to log in user');
      }
    } catch (e) {
      _logger.e('Error logging in user: $e');
      throw ServerFailure('Failed to log in user');
    }
  }
}
