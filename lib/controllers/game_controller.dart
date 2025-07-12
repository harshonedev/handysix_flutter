import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_cricket/core/contstants/app_constants.dart';
import 'package:hand_cricket/models/game_player.dart';
import 'package:hand_cricket/models/game_room.dart';
import 'package:hand_cricket/services/auth_service.dart';
import 'package:hand_cricket/services/game_firestore_service.dart';

class GameController extends StateNotifier<GameState> {
  final AuthService authService;
  final GameFirestoreService gameFirestoreService;
  Timer? _gameTimer;
  Timer? _moveTimer;
  Timer? _startTimer;
  Timer? _waitingTimer;

  // Pause/Resume state variables
  int _pausedMainTimer = 0;
  GamePhase? _pausedPhase;
  MoveStatus? _pausedMoveStatus;

  GameController({
    required this.authService,
    required this.gameFirestoreService,
  }) : super(GameInitial());

  @override
  void dispose() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    _startTimer?.cancel();
    _waitingTimer?.cancel();
    super.dispose();
  }

  void initializeGame(GameMode mode) async {
    // Get current user from auth service
    final user = await authService.getCurrentUser();
    if (user == null) {
      state = GameError('User not authenticated');
      return;
    }
    
    // Do toss
    final toss =
        Random().nextBool(); // true for batting first, false for bowling first

    final player = GamePlayer(
      uid: user.uid,
      name: user.name ?? 'Guest',
      avatarUrl: user.avatar ?? AppConstants.avatarUrl,
      type: PlayerType.player1,
      isBatting: toss,
    );

    if (mode == GameMode.practice) {
      final computer = GamePlayer(
        uid: 'computer',
        name: 'Computer',
        avatarUrl: AppConstants.computerAvatarUrl,
        type: PlayerType.computer,
        isBatting: !toss, // Computer bats opposite to player
      );

      state = GameWaiting(
        player1: player,
        player2: computer,
        mode: mode,
        mainTimer: 3,
        message: 'Game Starts in...',
        toss: toss,
        status: GameWaitingStatus.matched,
      );

      startGameCountdown();
    } else {
      state = GameWaiting(
        player1: player,
        message: 'Waiting for opponent...',
        status: GameWaitingStatus.wait,
        toss: toss,
        mode: mode,
      );
    }
  }

  void startGameCountdown() {
    if (state is! GameWaiting) return;

    final currentState = state as GameWaiting;

    _startTimer?.cancel();
    int countdown = 3;
    _startTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state is! GameWaiting) {
        timer.cancel();
      }
      countdown--;
      if (countdown < 0) {
        timer.cancel();
        startGame();
      } else {
        state = currentState.copyWith(
          mainTimer: countdown,
          message: 'Game Starts in...',
        );
      }
    });
  }

  void startGame() async {
    if (state is! GameWaiting) return;
    final currentState = state as GameWaiting;
    state = GameStarted(
      phase: GamePhase.toss,
      player1: currentState.player1,
      player2: currentState.player2!,
      isBattingFirst: currentState.toss,
      message:
          currentState.toss ? 'You\'re batting first' : 'You\'re bowling first',
      moveChoice: 0,
      computerChoice: 0,
      moveStatus: MoveStatus.start,
      isPaused: false,
    );

    // Start innigs countdown
    _startInningsCountdown(GamePhase.innings1);
  }

  void pauseGame() {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    // Don't pause if game is already paused, ended, or in result phase
    if (currentState.isPaused ||
        currentState.phase == GamePhase.result ||
        currentState.moveStatus == MoveStatus.end) {
      return;
    }

    _pausedMainTimer = currentState.mainTimer;
    _pausedPhase = currentState.phase;
    _pausedMoveStatus = currentState.moveStatus;

    // Cancel any running timers
    _gameTimer?.cancel();
    _moveTimer?.cancel();

    state = currentState.copyWith(
      isPaused: true,
      message: 'Game Paused',
      moveStatus: MoveStatus.paused,
    );
  }

  void resumeGame() {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    // Only resume if game is paused
    if (!currentState.isPaused) return;

    // Restore the game state
    state = currentState.copyWith(
      isPaused: false,
      mainTimer: _pausedMainTimer,
      phase: _pausedPhase ?? currentState.phase,
      moveStatus: _pausedMoveStatus ?? currentState.moveStatus,
      message: _getResumeMessage(),
    );

    // Resume appropriate timer based on the paused phase and status
    if (_pausedPhase == GamePhase.startInnigs) {
      _resumeInningsCountdown();
    } else if ((_pausedPhase == GamePhase.innings1 ||
            _pausedPhase == GamePhase.innings2) &&
        (_pausedMoveStatus == MoveStatus.next ||
            _pausedMoveStatus == MoveStatus.wait)) {
      _resumeMoveTimer();
    }

    // Clear pause state
    _pausedMainTimer = 0;
    _pausedPhase = null;
    _pausedMoveStatus = null;
  }

  String _getResumeMessage() {
    if (_pausedPhase == GamePhase.startInnigs) {
      return 'Game resumed! Get ready...';
    } else if (_pausedPhase == GamePhase.innings1 ||
        _pausedPhase == GamePhase.innings2) {
      if (state is GameStarted) {
        final currentState = state as GameStarted;
        return currentState.player1.isBatting
            ? 'Game resumed! Choose your move!'
            : 'Game resumed! Stop the computer!';
      }
    }
    return 'Game resumed!';
  }

  void _resumeInningsCountdown() {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;
    int countdown = _pausedMainTimer;

    GamePhase targetPhase =
        currentState.isBattingFirst
            ? (currentState.player1.ballsFaced == 6 ||
                    currentState.player1.isOut
                ? GamePhase.innings2
                : GamePhase.innings1)
            : (currentState.player2.ballsFaced == 6 ||
                    currentState.player2.isOut
                ? GamePhase.innings2
                : GamePhase.innings1);

    _gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state is! GameStarted) {
        timer.cancel();
        return;
      }

      final current = state as GameStarted;
      if (current.isPaused) {
        timer.cancel();
        return;
      }

      countdown--;

      if (countdown < 0) {
        timer.cancel();
        _startInnings(targetPhase);
      } else {
        state = current.copyWith(mainTimer: countdown);
      }
    });
  }

  void exitGame() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    _startTimer?.cancel();
    _waitingTimer?.cancel();
    _pausedMainTimer = 0;
    _pausedPhase = null;
    _pausedMoveStatus = null;
    state = GameInitial();
  }

  void _resumeMoveTimer() {
    if (state is! GameStarted) return;

    int countdown = _pausedMainTimer;

    _moveTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state is! GameStarted) {
        timer.cancel();
        return;
      }

      final current = state as GameStarted;
      if (current.isPaused) {
        timer.cancel();
        return;
      }

      countdown--;

      if (countdown < 0) {
        timer.cancel();
        _processMoves(current.moveChoice);
      } else {
        state = current.copyWith(
          mainTimer: countdown,
          moveStatus: MoveStatus.wait,
        );
      }
    });
  }

  void _startInningsCountdown(GamePhase phase) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;
    int countdown = 3;
    int? target;
    String message;

    if (phase == GamePhase.innings2) {
      target =
          currentState.isBattingFirst
              ? currentState.player1.score + 1
              : currentState.player2.score + 1;

      message =
          currentState.isBattingFirst
              ? 'Now it\'s your turn to bowl! Defend $target'
              : 'Now it\'s your turn to bat! Target $target';
    } else {
      message =
          currentState.isBattingFirst
              ? 'You\'re batting first'
              : 'You\'re bowling first';
    }

    state = currentState.copyWith(
      message: message,
      target: target,
      mainTimer: countdown,
      phase: GamePhase.startInnigs,
    );

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state is! GameStarted) {
        timer.cancel();
        return;
      }

      final current = state as GameStarted;
      if (current.isPaused) {
        timer.cancel();
        return;
      }

      countdown--;

      if (countdown < 0) {
        timer.cancel();
        // Move to innings
        _startInnings(phase);
      } else {
        state = current.copyWith(
          mainTimer: countdown,
          phase: GamePhase.startInnigs,
          message: message,
          target: target,
        );
      }
    });
  }

  void _startInnings(GamePhase phase) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    int? target;
    GamePlayer updatedPlayer = currentState.player1;
    GamePlayer updatedComputer = currentState.player2;

    if (phase == GamePhase.innings1) {
    } else {
      // Switch batting/bowling for innings 2 and reset stats
      updatedPlayer = currentState.player1.copyWith(
        isBatting: !currentState.player1.isBatting,
      );
      updatedComputer = currentState.player2.copyWith(
        isBatting: !currentState.player2.isBatting,
      );

      target =
          currentState.isBattingFirst
              ? currentState.player1.score + 1
              : currentState.player2.score + 1;
    }

    state = currentState.copyWith(
      phase: phase,
      player1: updatedPlayer,
      player2: updatedComputer,
      message: 'Choose a number!',
      moveChoice: 0,
      computerChoice: 0,
      target: target,
      moveStatus: MoveStatus.next,
    );

    _startMoveTimer();
  }

  void _startMoveTimer() {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;
    int countdown = 5;
    state = currentState.copyWith(mainTimer: countdown);

    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state is! GameStarted) {
        timer.cancel();
        return;
      }

      final current = state as GameStarted;
      if (current.isPaused) {
        timer.cancel();
        return;
      }

      countdown--;

      if (countdown < 0) {
        timer.cancel();
        // Auto-select 0 move if player didn't choose
        _processMoves(current.moveChoice);
      } else {
        state = current.copyWith(
          mainTimer: countdown,
          moveStatus: MoveStatus.wait,
        );
      }
    });
  }

  void chooseMove(int moveChoice) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    // Don't allow move selection if game is paused
    if (currentState.isPaused) return;

    // Only allow move selection during innings and when not in progress
    if ((currentState.phase == GamePhase.innings1 ||
            currentState.phase == GamePhase.innings2) &&
        currentState.moveStatus != MoveStatus.progress) {
      state = currentState.copyWith(moveChoice: moveChoice);

      // If timer is running and move is selected, process immediately
      if (currentState.mainTimer > 0) {
        _moveTimer?.cancel();
        _processMoves(moveChoice);
      }
    }
  }

  void _processMoves(int playerMove) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;
    final computerMove = Random().nextInt(6) + 1;

    // Set moves and progress status
    state = currentState.copyWith(
      moveChoice: playerMove,
      computerChoice: computerMove,
      moveStatus: MoveStatus.progress,
      mainTimer: 0,
    );

    //process result
    _processResult(playerMove, computerMove);
  }

  void _processResult(int playerMove, int computerMove) {
    if (state is! GameStarted) return;

    if (playerMove == computerMove) {
      // OUT!
      _handleOut();
    } else {
      // Runs scored
      _handleRuns(playerMove, computerMove);
    }
  }

  void _handleOut() {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    if (currentState.player1.isBatting) {
      // Player is out
      final updatedPlayer = currentState.player1.copyWith(
        isOut: true,
        ballsFaced: currentState.player1.ballsFaced + 1,
      );

      state = currentState.copyWith(
        player1: updatedPlayer,
        message: 'Oh no! You are out!',
        moveStatus: MoveStatus.progressed,
      );
    } else {
      // Computer is out
      final updatedComputer = currentState.player2.copyWith(
        isOut: true,
        ballsFaced: currentState.player2.ballsFaced + 1,
      );

      state = currentState.copyWith(
        player2: updatedComputer,
        message: 'Yay! Bowled them out!',
        moveStatus: MoveStatus.progressed,
      );
    }

    // Continue game after delay
    Timer(Duration(seconds: 2), () {
      _checkInningsEnd();
    });
  }

  void _handleRuns(int playerMove, int computerMove) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    if (currentState.player1.isBatting) {
      // Player is batting
      final updatedPlayer = currentState.player1.copyWith(
        score: currentState.player1.score + playerMove,
        ballsFaced: currentState.player1.ballsFaced + 1,
      );

      state = currentState.copyWith(
        player1: updatedPlayer,
        message: _getScoreMessage(playerMove),
        moveStatus: MoveStatus.progressed,
      );
    } else {
      // Computer is batting
      final updatedComputer = currentState.player2.copyWith(
        score: currentState.player2.score + computerMove,
        ballsFaced: currentState.player2.ballsFaced + 1,
      );

      state = currentState.copyWith(
        player2: updatedComputer,
        message: 'Computer scored $computerMove runs!',
        moveStatus: MoveStatus.progressed,
      );
    }

    // Check for chase completion in innings 2
    if (currentState.phase == GamePhase.innings2) {
      final firstInningsScore =
          currentState.player1.isBatting
              ? currentState.player2.score
              : currentState.player1.score;

      final currentScore =
          currentState.player1.isBatting
              ? currentState.player1.score + playerMove
              : currentState.player2.score + computerMove;

      if (currentScore > firstInningsScore) {
        // Chase completed
        // Continue game after delay
        Timer(Duration(seconds: 2), () {
          _endGame();
        });
        return;
      }
    }

    // Continue game after delay
    Timer(Duration(seconds: 2), () {
      _checkInningsEnd();
    });
  }

  void _checkInningsEnd() {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    // Check if current batsman is out or has faced 6 balls
    bool inningsEnded = false;

    if (currentState.player1.isBatting) {
      inningsEnded =
          currentState.player1.isOut || currentState.player1.ballsFaced >= 6;
    } else {
      inningsEnded =
          currentState.player2.isOut || currentState.player2.ballsFaced >= 6;
    }

    if (inningsEnded) {
      if (currentState.phase == GamePhase.innings1) {
        // start innings 2 countdown timer
        _startInningsCountdown(GamePhase.innings2);
      } else {
        // Game over
        _endGame();
      }
    } else {
      // Continue current innings
      _continueInnings();
    }
  }

  void _continueInnings() {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    state = currentState.copyWith(
      message:
          currentState.player1.isBatting
              ? 'Choose your next move!'
              : 'Stop the computer!',
      moveChoice: 0,
      computerChoice: 0,
      moveStatus: MoveStatus.next,
    );

    _startMoveTimer();
  }

  void _endGame() {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    // Determine winner
    String resultMessage;
    PlayerType? winner;
    if (currentState.player1.score > currentState.player2.score) {
      resultMessage =
          'Congratulations! You won by ${currentState.player1.score - currentState.player2.score} runs!';
      winner = PlayerType.player1;
    } else if (currentState.player2.score > currentState.player1.score) {
      resultMessage =
          'Computer wins by ${currentState.player2.score - currentState.player1.score} runs!';
      winner = PlayerType.computer;
    } else {
      resultMessage = 'It\'s a tie! Great match!';
    }

    // state = currentState.copyWith(
    //   phase: GamePhase.result,
    //   message: resultMessage,
    //   moveStatus: MoveStatus.end,
    //   mainTimer: 0,
    // );

    state = GameResult(
      player1: currentState.player1,
      player2: currentState.player2,
      message: resultMessage,
      winner: winner,
    );
  }

  String _getScoreMessage(int score) {
    switch (score) {
      case 1:
        return 'Nice play! $score run';
      case 2:
      case 3:
        return 'Nice play! $score runs';
      case 4:
        return 'What a shot! $score runs';
      case 5:
        return 'Great shot! $score runs';
      case 6:
        return 'It\'s a six! Amazing!';
      default:
        return 'No runs scored';
    }
  }

  void resetGame() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    _pausedMainTimer = 0;
    _pausedPhase = null;
    _pausedMoveStatus = null;
    state = GameInitial();
  }
}

// GameState
abstract class GameState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}

class GameStarted extends GameState {
  final GamePhase phase;
  final GamePlayer player1;
  final GamePlayer player2;
  final bool isBattingFirst;
  final String message;
  final int mainTimer;
  final int moveChoice;
  final int computerChoice;
  final MoveStatus moveStatus;
  final int? target;
  final bool isPaused;

  GameStarted({
    this.phase = GamePhase.toss,
    required this.player1,
    required this.player2,
    required this.isBattingFirst,
    this.message = '',
    this.mainTimer = 0,
    this.moveChoice = 0,
    this.computerChoice = 0,
    this.target,
    required this.moveStatus,
    this.isPaused = false,
  });

  GameStarted copyWith({
    GamePhase? phase,
    GamePlayer? player1,
    GamePlayer? player2,
    bool? isBattingFirst,
    String? message,
    int? mainTimer,
    int? moveChoice,
    int? computerChoice,
    MoveStatus? moveStatus,
    int? target,
    bool? isPaused,
  }) {
    return GameStarted(
      phase: phase ?? this.phase,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      isBattingFirst: isBattingFirst ?? this.isBattingFirst,
      message: message ?? this.message,
      mainTimer: mainTimer ?? this.mainTimer,
      moveChoice: moveChoice ?? this.moveChoice,
      computerChoice: computerChoice ?? this.computerChoice,
      moveStatus: moveStatus ?? this.moveStatus,
      target: target ?? this.target,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    player1,
    player2,
    isBattingFirst,
    message,
    mainTimer,
    moveChoice,
    computerChoice,
    moveStatus,
    target,
    isPaused,
  ];
}

class GameWaiting extends GameState {
  final GamePlayer player1;
  final GamePlayer? player2;
  final GameMode mode;
  final int mainTimer;
  final String message;
  final bool toss;
  final GameWaitingStatus status;

  GameWaiting({
    required this.player1,
    this.player2,
    required this.mode,
    this.mainTimer = 0,
    this.message = '',
    required this.status,
    required this.toss,
  });

  GameWaiting copyWith({
    GamePlayer? player1,
    GamePlayer? player2,
    GameMode? mode,
    int? mainTimer,
    String? message,
    GameWaitingStatus? status,
    bool? toss,
  }) {
    return GameWaiting(
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      mode: mode ?? this.mode,
      mainTimer: mainTimer ?? this.mainTimer,
      message: message ?? this.message,
      status: status ?? this.status,
      toss: toss ?? this.toss,
    );
  }

  @override
  List<Object?> get props => [
    player1,
    player2,
    mode,
    mainTimer,
    message,
    status,
    toss,
  ];
}

class GameResult extends GameState {
  final GamePlayer player1;
  final GamePlayer player2;
  final String message;
  final PlayerType? winner;

  GameResult({
    required this.player1,
    required this.player2,
    required this.message,
    required this.winner,
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

enum GameWaitingStatus { wait, matched, timedOut }
