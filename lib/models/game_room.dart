import 'package:equatable/equatable.dart';
import 'package:hand_cricket/models/game_player.dart';

class GameRoom extends Equatable {
  final String id;
  final GamePhase phase;
  final GamePlayer player1;
  final GamePlayer? player2;
  final PlayerType whoBattingFirst;
  final String message;
  final int player1choice;
  final int player2choice;
  final int currentMove;
  final int? target;
  final PlayerType? winner;
  final bool? isTie;
  final GameStatus status;
  final GameResultType? result;

  const GameRoom({
    required this.id,
    required this.phase,
    required this.player1,
    this.player2,
    required this.whoBattingFirst,
    this.message = 'Game',
    this.player1choice = 0,
    this.player2choice = 0,
    required this.status,
    this.currentMove = 0,
    this.target,
    this.winner,
    this.isTie,
    this.result,
  });

  GameRoom copyWith({
    String? id,
    GamePhase? phase,
    GamePlayer? player1,
    GamePlayer? player2,
    PlayerType? whoBattingFirst,
    String? message,
    int? player1choice,
    int? player2choice,
    int? target,
    PlayerType? winner,
    bool? isTie,
    int? currentMove,
    GameStatus? status,
    GameResultType? result,
  }) {
    return GameRoom(
      id: id ?? this.id,
      phase: phase ?? this.phase,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      whoBattingFirst: whoBattingFirst ?? this.whoBattingFirst,
      message: message ?? this.message,
      player1choice: player1choice ?? this.player1choice,
      player2choice: player2choice ?? this.player2choice,
      target: target ?? this.target,
      winner: winner ?? this.winner,
      isTie: isTie ?? this.isTie,
      status: status ?? this.status,
      currentMove: currentMove ?? this.currentMove,
      result: result ?? this.result,
    );
  }

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      id: json['id'],
      phase: GamePhase.values.firstWhere((e) => e.name == json['phase']),
      player1: GamePlayer.fromJson(json['player1']),
      player2:
          json['player2'] != null ? GamePlayer.fromJson(json['player2']) : null,
      whoBattingFirst: PlayerType.values.firstWhere(
        (e) => e.name == json['whoBattingFirst'],
      ),
      message: json['message'],
      player1choice: json['player1choice'],
      player2choice: json['player2choice'],
      target: json['target'],
      winner:
          json['winner'] != null
              ? PlayerType.values.firstWhere((e) => e.name == json['winner'])
              : null,
      isTie: json['isTie'],
      status: GameStatus.values.firstWhere((e) => e.name == json['status']),
      result:
          json['result'] != null
              ? GameResultType.values.firstWhere(
                (e) => e.name == json['result'],
              )
              : null,
      currentMove: json['currentMove'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phase': phase.name,
      'player1': player1.toJson(),
      'player2': player2?.toJson(),
      'whoBattingFirst': whoBattingFirst.name,
      'message': message,
      'player1choice': player1choice,
      'player2choice': player2choice,
      'target': target,
      'winner': winner?.name,
      'isTie': isTie,
      'status': status.name,
      'result': result?.name,
      'currentMove': currentMove,
    };
  }

  @override
  List<Object?> get props => [
    phase,
    player1,
    player2,
    whoBattingFirst,
    message,
    player1choice,
    player2choice,
    target,
    status,
    winner,
    isTie,
    result,
    currentMove,
    id, 
  ];
}

enum GameStatus { active, waiting, inactive, finished, paused }

enum GameResultType { valid, invalid }

enum GamePhase { toss, innings1, innings2, result, startInnigs, waiting }
