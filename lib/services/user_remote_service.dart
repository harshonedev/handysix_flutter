import 'package:dio/dio.dart';
import 'package:hand_cricket/core/constants/app_constants.dart';
import 'package:hand_cricket/core/failures/failures.dart';
import 'package:hand_cricket/models/user_model.dart';

class UserRemoteService {
  final Dio _dio;
  UserRemoteService({required Dio dio}) : _dio = dio;

  Future<UserModel> login(AuthLoginRequestData data) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/user/login';
      final response = await _dio.post(url, data: data.toJson());

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerFailure('Failed to login: ${response.statusCode}');
      }

      if (response.data['success'] != true) {
        throw ServerFailure('Login failed: ${response.data['message']}');
      }

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      // Handle Dio-specific errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw ConnectionFailure('Connection timed out. Please try again.');
      } else if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['message'] ?? 'Unknown error occurred';
        throw ServerFailure('Error $statusCode: $message');
      } else {
        throw NetworkFailure('Network error occurred. Please try again.');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getUserById(String id) async {
    try {
      final url = '${AppConstants.apiBaseUrl}/user/$id';
      final response = await _dio.get(url);

      if (response.statusCode != 200) {
        throw ServerFailure('Failed to to get user: ${response.statusCode}');
      }

      if (response.data['success'] != 'true') {
        throw ServerFailure('Request failed: ${response.data['message']}');
      }

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      // Handle Dio-specific errors
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw ConnectionFailure('Connection timed out. Please try again.');
      } else if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['message'] ?? 'Unknown error occurred';
        throw ServerFailure('Error $statusCode: $message');
      } else {
        throw NetworkFailure('Network error occurred. Please try again.');
      }
    } catch (e) {
      rethrow;
    }
  }
}

class AuthLoginRequestData {
  final String uid;
  final String name;
  final String? email;
  final String? photoUrl;

  AuthLoginRequestData({
    required this.uid,
    this.name = 'Guest',
    this.email,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'uid': uid, 'name': name, 'photoUrl': photoUrl};
  }
}
