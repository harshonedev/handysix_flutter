import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hand_cricket/models/user_model.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  AuthService(this._auth, this._googleSignIn, this._firestore);

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
        throw Exception('User is null after Google sign-in');
      }

      // Check if the user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        // If the user does not exist, create a new document
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': user.displayName,
          'avatar':
              user.photoURL, // Change it later if photoURL is null then use random default avatar
          'createdAt': FieldValue.serverTimestamp(),
        });
        final userModel = UserModel(
          uid: user.uid,
          email: user.email,
          name: user.displayName,
          avatar: user.photoURL,
        );
        _logger.d('User created: $userModel');
        return userModel;
      }
      final userData = userDoc.data();
      if (userData == null) {
        _logger.e('User data is null');
        throw Exception('User data is null');
      }

      userData['uid'] = user.uid; // Add uid to the user data
      _logger.d('User data: $userData');
      return UserModel.fromJson(userData);
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
        throw Exception('User is null after anonymous sign-in');
      }
      // Check if the user exists in Firestore
      final userDoc =
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();
      if (!userDoc.exists) {
        // If the user does not exist, create a new document
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': null,
          'name': null,
          'avatar': null,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: null,
          name: null,
          avatar: null,
        );
        _logger.d('User created: $userModel');
        return userModel;
      }
      final userData = userDoc.data();
      if (userData == null) {
        _logger.e('User data is null');
        throw Exception('User data is null');
      }
      userData['uid'] = userCredential.user!.uid; // Add uid to the user data
      _logger.d('User data: $userData');
      return UserModel.fromJson(userData);
    } catch (e) {
      _logger.e('Error signing in anonymously: $e');
      throw Exception('Failed to sign in anonymously');
    }
  }

  // Get current user
  User? getCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      _logger.e('Error getting current user: $e');
      throw Exception('Failed to get current user');
    }
  }
}
