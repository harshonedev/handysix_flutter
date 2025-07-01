import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String name;
  final String avatarUrl;
  final int score;
  final int ballsFaced;
  final bool isOut;
  final bool isBatting;
  final PlayerType type;
  
  const Player({
    required this.name,
    required this.avatarUrl,
    required this.type,
    this.score = 0,
    this.ballsFaced = 0,
    this.isOut = false,
    required this.isBatting,

  });

  @override
  List<Object?> get props => [name, avatarUrl, score];

  Player copyWith({
    String? name,
    String? avatarUrl,
    int? score,
    PlayerType? type,
    int? ballsFaced,
    bool? isOut,
    bool? isBatting,
  }) {

    return Player(
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      type: type ?? this.type,
      score: score ?? this.score,
      ballsFaced: ballsFaced ?? this.ballsFaced,
      isOut: isOut ?? this.isOut,
      isBatting: isBatting ?? this.isBatting,
    );
  }
}

enum PlayerType {
  player1,
  player2,
  computer,
}