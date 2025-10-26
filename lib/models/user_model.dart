import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String uid;
  final String? email;
  final String? name;
  final String? avatar;
  final StatsModel? stats;

  const UserModel({
    required this.uid,
    required this.id,
    this.email,
    this.name,
    this.avatar,
    this.stats,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      uid: json['uid'],
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      avatar: json['profilePicture'] ?? '',
      stats: json['Stats'] != null ? StatsModel.fromJson(json['Stats']) : null,
    );
  }

  factory UserModel.fromFirebaseUser(dynamic user) {
    return UserModel(
      uid: user.uid,
      id: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      avatar: user.photoURL ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'profilePicture': avatar,
      'uid': uid,
      'id': id,
      'stats': stats?.toJson(),
    };
  }

  UserModel copyWith({
    String? id,
    String? uid,
    String? email,
    String? name,
    String? avatar,
    StatsModel? stats,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      uid: uid ?? this.uid,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [id, email, name, avatar, uid, stats];
}

class StatsModel extends Equatable {
  final int id;
  final int runs;
  final int wins;
  final int losses;
  final int matches;

  const StatsModel({
    required this.id,
    required this.wins,
    required this.losses,
    required this.runs,
    required this.matches,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      id: json['id'],
      wins: json['wins'],
      losses: json['losses'],
      runs: json['runs'],
      matches: json['matches'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wins': wins,
      'losses': losses,
      'runs': runs,
      'matches': matches,
    };
  }

  @override
  List<Object?> get props => [id, wins, losses, matches, runs];
}
