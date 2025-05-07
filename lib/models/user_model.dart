import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String? email;
  final String? name;
  final String? avatar;

  const UserModel({
    required this.uid,
    this.email,
    this.name,
    this.avatar,
  });

  UserModel.fromJson(Map<String, dynamic> json)
      : uid = json['uid'],
        email = json['email'],
        name = json['name'],
        avatar = json['avatar'];

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'avatar': avatar,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? avatar,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
    );
  }

  @override 
  List<Object?> get props => [uid, email, name, avatar];
}