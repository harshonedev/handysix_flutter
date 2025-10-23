import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String? email;
  final String? name;
  final String? avatar;

  const UserModel({
    required this.id,
    this.email,
    this.name,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['uid'],
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      avatar: json['profilePicture'] ?? '',
    );
  }

  factory UserModel.fromFirebaseUser(dynamic user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      avatar: user.photoURL ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'name': name, 'profilePicture': avatar};
  }

  UserModel copyWith({
    String? id,
    String? uid,
    String? email,
    String? name,
    String? avatar,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
    );
  }

  @override
  List<Object?> get props => [id, email, name, avatar];
}
