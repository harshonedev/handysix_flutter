import 'package:equatable/equatable.dart';
import 'package:hand_cricket/controllers/practice_game_controller.dart';
import 'package:hand_cricket/models/game_player.dart';

class GameRoom extends Equatable {
  final String id;
  final GamePhase phase;
  final GamePlayer player1;
  final GamePlayer? player2;
  final bool isBattingFirst;
  final String message;
  final int player1choice;
  final int player2choice;
  final int? target;
  final PlayerType? winner;
  final bool? isTie;
  final GameStatus status;
  final GameResult? result;

  const GameRoom({
    required this.id,
    required this.phase,
    required this.player1,
    this.player2,
    required this.isBattingFirst,
    this.message = 'Game',
    this.player1choice = 0,
    this.player2choice = 0,
    required this.status,
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
    bool? isBattingFirst,
    String? message,
    int? player1choice,
    int? player2choice,
    int? target,
    PlayerType? winner,
    bool? isTie,
    GameStatus? status,
    GameResult? result,
  }) {
    return GameRoom(
      id: id ?? this.id,
      phase: phase ?? this.phase,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      isBattingFirst: isBattingFirst ?? this.isBattingFirst,
      message: message ?? this.message,
      player1choice: player1choice ?? this.player1choice,
      player2choice: player2choice ?? this.player2choice,
      target: target ?? this.target,
      winner: winner ?? this.winner,
      isTie: isTie ?? this.isTie,
      status: status ?? this.status,
      result: result ?? this.result,
    );
  }

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      id: json['id'],
      phase: GamePhase.values.firstWhere((e) => e.name == json['phase']),
      player1: GamePlayer.fromJson(json['player1']),
      player2: json['player2'] ? GamePlayer.fromJson(json['player2']) : null,
      isBattingFirst: json['isBattingFirst'],
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
          json['result']
              ? GameResult.values.firstWhere((e) => e.name == json['result'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phase': phase.name,
      'player1': player1.toJson(),
      'player2': player2?.toJson(),
      'isBattingFirst': isBattingFirst,
      'message': message,
      'player1choice': player1choice,
      'player2choice': player2choice,
      'target': target,
      'winner': winner?.name,
      'isTie': isTie,
      'status': status.name,
      'result': result?.name,
    };
  }

  @override
  List<Object?> get props => [
    phase,
    player1,
    player2,
    isBattingFirst,
    message,
    player1choice,
    player2choice,
    target,
    status,
    winner,
    isTie,
  ];
}

enum GameStatus { active, waiting, inactive, finished, paused }

enum GameResult { valid, invalid }
