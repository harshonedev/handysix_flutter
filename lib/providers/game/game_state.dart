
// GameState
import 'package:equatable/equatable.dart';
import 'package:hand_cricket/models/game_player.dart';
import 'package:hand_cricket/models/game_room.dart';

abstract class GameState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}

class GameStarted extends GameState {
  final GamePhase phase;
  final GamePlayer player;
  final GamePlayer opponent;
  final bool isBattingFirst;
  final String message;
  final int mainTimer;
  final int moveChoice;
  final int opponentChoice;
  final MoveStatus moveStatus;
  final int? target;
  final bool isPaused;
  final GameMode mode;
  final String? roomId;
  final int currentMove;

  GameStarted({
    this.phase = GamePhase.toss,
    required this.player,
    required this.opponent,
    required this.isBattingFirst,
    this.message = '',
    this.mainTimer = 0,
    this.moveChoice = 0,
    this.opponentChoice = 0,
    this.target,
    required this.moveStatus,
    this.isPaused = false,
    required this.mode,
    this.roomId,
    this.currentMove = 0,
  });

  GameStarted copyWith({
    GamePhase? phase,
    GamePlayer? player,
    GamePlayer? opponent,
    bool? isBattingFirst,
    String? message,
    int? mainTimer,
    int? moveChoice,
    int? opponentChoice,
    MoveStatus? moveStatus,
    int? target,
    bool? isPaused,
    GameMode? mode,
    String? roomId,
    int? currentMove,
  }) {
    return GameStarted(
      phase: phase ?? this.phase,
      player: player ?? this.player,
      opponent: opponent ?? this.opponent,
      isBattingFirst: isBattingFirst ?? this.isBattingFirst,
      message: message ?? this.message,
      mainTimer: mainTimer ?? this.mainTimer,
      moveChoice: moveChoice ?? this.moveChoice,
      opponentChoice: opponentChoice ?? this.opponentChoice,
      moveStatus: moveStatus ?? this.moveStatus,
      target: target ?? this.target,
      isPaused: isPaused ?? this.isPaused,
      mode: mode ?? this.mode,
      roomId: roomId ?? this.roomId,
      currentMove: currentMove ?? this.currentMove,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    player,
    opponent,
    isBattingFirst,
    message,
    mainTimer,
    moveChoice,
    opponentChoice,
    moveStatus,
    target,
    isPaused,
    mode,
    roomId,
    currentMove,
  ];
}

class GameWaiting extends GameState {
  final GamePlayer player;
  final GamePlayer? opponent;
  final GameMode mode;
  final int mainTimer;
  final String message;
  final bool toss;
  final GameWaitingStatus status;
  final String? roomId;

  GameWaiting({
    required this.player,
    this.opponent,
    required this.mode,
    this.mainTimer = 0,
    this.message = '',
    required this.status,
    required this.toss,
    this.roomId,
  });

  GameWaiting copyWith({
    GamePlayer? player,
    GamePlayer? opponent,
    GameMode? mode,
    int? mainTimer,
    String? message,
    GameWaitingStatus? status,
    bool? toss,
    String? roomId,
  }) {
    return GameWaiting(
      player: player ?? this.player,
      opponent: opponent ?? this.opponent,
      mode: mode ?? this.mode,
      mainTimer: mainTimer ?? this.mainTimer,
      message: message ?? this.message,
      status: status ?? this.status,
      toss: toss ?? this.toss,
      roomId: roomId ?? this.roomId,
    );
  }

  @override
  List<Object?> get props => [
    player,
    opponent,
    mode,
    mainTimer,
    message,
    status,
    toss,
  ];
}

class GameResult extends GameState {
  final GamePlayer player;
  final GamePlayer opponent;
  final String message;
  final PlayerType? winner;
  final String? roomId;

  GameResult({
    required this.player,
    required this.opponent,
    required this.message,
    required this.winner,
    this.roomId,
  });
}

class GameError extends GameState {
  final String error;

  GameError(this.error);

  @override
  List<Object?> get props => [error];

  @override
  String toString() => 'GameError: $error';
}

enum MoveStatus { next, wait, progress, progressed, start, end, paused }

enum GameMode { online, practice }

enum GameWaitingStatus { wait, matched, timedOut, started }
