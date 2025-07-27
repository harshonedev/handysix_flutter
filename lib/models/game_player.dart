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
  final List<int> movesPerBall; // List of moves made by this player per ball

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
    this.movesPerBall = const [],
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
      status:
          json['status'] != null
              ? PlayerStatus.values.firstWhere(
                (status) => status.name == json['status'],
              )
              : null,
      isBatting: json['isBatting'],
      movesPerBall:
          json['movesPerBall'] != null
              ? List<int>.from(json['movesPerBall'])
              : [],
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
      'movesPerBall': movesPerBall,
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
    List<int>? movesPerBall,
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
      movesPerBall: movesPerBall ?? this.movesPerBall,
    );
  }

  // Helper method to add a move to the movesPerBall list
  GamePlayer addMove(int move) {
    final updatedMoves = List<int>.from(movesPerBall)..add(move);
    return copyWith(movesPerBall: updatedMoves, ballsFaced: ballsFaced + 1);
  }

  // Helper method to get the last move made by this player
  int? get lastMove => movesPerBall.isNotEmpty ? movesPerBall.last : null;

  // Helper method to get move for a specific ball number (1-indexed)
  int? getMoveForBall(int ballNumber) {
    if (ballNumber <= 0 || ballNumber > movesPerBall.length) return null;
    return movesPerBall[ballNumber - 1];
  }

  @override
  List<Object?> get props => [
    uid,
    name,
    avatarUrl,
    score,
    ballsFaced,
    isOut,
    isBatting,
    type,
    status,
    movesPerBall,
  ];
}

enum PlayerType { player1, player2, computer }

enum PlayerStatus { winner, loser, tie, left }
