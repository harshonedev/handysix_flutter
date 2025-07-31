import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String uid;
  final String? email;
  final String? name;
  final String? avatar;

  const UserModel({
    required this.id,
    required this.uid,
    this.email,
    this.name,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      uid: json['uid'],
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      avatar: json['profilePicture']  ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'uid': uid, 'email': email, 'name': name, 'profilePicture': avatar};
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
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
    );
  }

  @override
  List<Object?> get props => [id, uid, email, name, avatar];
}
