import 'package:equatable/equatable.dart';

class GamePlayer extends Equatable {
  final String uid;
  final String name;
  final String avatarUrl;
  final int score;
  final int ballsFaced;
  final bool isOut;
  final bool isBatting;
  final PlayerType type;
  final PlayerStatus? status;

  const GamePlayer({
    required this.uid,
    required this.name,
    required this.avatarUrl,
    required this.type,
    this.score = 0,
    this.ballsFaced = 0,
    this.isOut = false,
    required this.isBatting,
    this.status,
  });

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    return GamePlayer(
      uid: json['uid'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      score: json['score'],
      ballsFaced: json['ballsFaced'],
      isOut: json['isOut'],
      type: PlayerType.values.firstWhere((type) => type.name == json['type']),
      status: PlayerStatus.values.firstWhere(
        (status) => status.name == json['status'],
      ),
      isBatting: json['isBatting'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'avatarUrl': avatarUrl,
      'score': score,
      'ballsFaced': ballsFaced,
      'isOut': isOut,
      'type': type.name,
      'status': status?.name,
      'isBatting': isBatting,
    };
  }

  GamePlayer copyWith({
    String? uid,
    String? name,
    String? avatarUrl,
    int? score,
    PlayerType? type,
    int? ballsFaced,
    bool? isOut,
    bool? isBatting,
    PlayerStatus? status,
  }) {
    return GamePlayer(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      type: type ?? this.type,
      score: score ?? this.score,
      ballsFaced: ballsFaced ?? this.ballsFaced,
      isOut: isOut ?? this.isOut,
      isBatting: isBatting ?? this.isBatting,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [name, avatarUrl, score];
}

enum PlayerType { player1, player2, computer }

enum PlayerStatus { winner, loser, tie, left }
