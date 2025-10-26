import 'dart:convert';

import 'package:hand_cricket/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLocalService {
  static const String userKey = 'user_data';

  const UserLocalService();

  Future<void> saveUser(UserModel usee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(usee.toJson()));
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(userKey);
    if (userData == null) {
      return null;
    }
    final Map<String, dynamic> userMap = jsonDecode(userData);
    return UserModel.fromJson(userMap);
  }
}
