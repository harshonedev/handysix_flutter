import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String name;
  final String avatarUrl;
  final int score;
  final PlayerType type;
  
  const Player({
    required this.name,
    required this.avatarUrl,
    required this.type,
    this.score = 0,

  });

  @override
  List<Object?> get props => [name, avatarUrl, score];

  Player copyWith({
    String? name,
    String? avatarUrl,
    int? score,
    PlayerType? type,
  }) {

    return Player(
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      type: type ?? this.type,
      score: score ?? this.score,
    );
  }
}

enum PlayerType {
  player1,
  player2,
  computer,
}