import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_cricket/core/contstants/app_constants.dart';
import 'package:hand_cricket/models/player.dart';
import 'package:hand_cricket/services/auth_service.dart';

class PracticeGameController extends StateNotifier<PracticeGameState> {
  final AuthService authService;
  Timer? _gameTimer;
  Timer? _moveTimer;

  // Pause/Resume state variables
  int _pausedMainTimer = 0;
  GamePhase? _pausedPhase;
  MoveStatus? _pausedMoveStatus;

  PracticeGameController({required this.authService})
    : super(PracticeGameInitial());

  @override
  void dispose() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    super.dispose();
  }

  void startGame() async {
    // Get current user from auth service
    final user = authService.getCurrentUser();
    if (user == null) {
      state = PracticeGameError('User not authenticated');
      return;
    }

    // Do toss
    final toss =
        Random().nextBool(); // true for batting first, false for bowling first

    final player = Player(
      name: user.displayName ?? 'Guest',
      avatarUrl: user.photoURL ?? AppConstants.avatarUrl,
      type: PlayerType.player1,
      isBatting: toss,
    );
    final computer = Player(
      name: 'Computer',
      avatarUrl: AppConstants.computerAvatarUrl,
      type: PlayerType.computer,
      isBatting: !toss, // Computer bats opposite to player
    );

    state = PracticeGameStarted(
      phase: GamePhase.toss,
      player: player,
      computer: computer,
      isBattingFirst: toss,
      message: toss ? 'You\'re batting first' : 'You\'re bowling first',
      moveChoice: 0,
      computerChoice: 0,
      moveStatus: MoveStatus.start,
      isPaused: false,
    );

    // Start innigs countdown
    _startInningsCountdown(GamePhase.innings1);
  }

  void pauseGame() {
    if (state is! PracticeGameStarted) return;

    final currentState = state as PracticeGameStarted;

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
    if (state is! PracticeGameStarted) return;

    final currentState = state as PracticeGameStarted;

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
      if (state is PracticeGameStarted) {
        final currentState = state as PracticeGameStarted;
        return currentState.player.isBatting
            ? 'Game resumed! Choose your move!'
            : 'Game resumed! Stop the computer!';
      }
    }
    return 'Game resumed!';
  }

  void _resumeInningsCountdown() {
    if (state is! PracticeGameStarted) return;

    final currentState = state as PracticeGameStarted;
    int countdown = _pausedMainTimer;

    GamePhase targetPhase =
        currentState.isBattingFirst
            ? (currentState.player.ballsFaced == 6 || currentState.player.isOut
                ? GamePhase.innings2
                : GamePhase.innings1)
            : (currentState.computer.ballsFaced == 6 ||
                    currentState.computer.isOut
                ? GamePhase.innings2
                : GamePhase.innings1);

    _gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state is! PracticeGameStarted) {
        timer.cancel();
        return;
      }

      final current = state as PracticeGameStarted;
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
    _pausedMainTimer = 0;
    _pausedPhase = null;
    _pausedMoveStatus = null;
    state = PracticeGameInitial();
  }

  void _resumeMoveTimer() {
    if (state is! PracticeGameStarted) return;

    int countdown = _pausedMainTimer;

    _moveTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state is! PracticeGameStarted) {
        timer.cancel();
        return;
      }

      final current = state as PracticeGameStarted;
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
    if (state is! PracticeGameStarted) return;

    final currentState = state as PracticeGameStarted;
    int countdown = 3;
    int? target;
    String message;

    if (phase == GamePhase.innings2) {
      target =
          currentState.isBattingFirst
              ? currentState.player.score + 1
              : currentState.computer.score + 1;

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
      if (state is! PracticeGameStarted) {
        timer.cancel();
        return;
      }

      final current = state as PracticeGameStarted;
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
    if (state is! PracticeGameStarted) return;

    final currentState = state as PracticeGameStarted;

    int? target;
    Player updatedPlayer = currentState.player;
    Player updatedComputer = currentState.computer;

    if (phase == GamePhase.innings1) {
    } else {
      // Switch batting/bowling for innings 2 and reset stats
      updatedPlayer = currentState.player.copyWith(
        isBatting: !currentState.player.isBatting,
      );
      updatedComputer = currentState.computer.copyWith(
        isBatting: !currentState.computer.isBatting,
      );

      target =
          currentState.isBattingFirst
              ? currentState.player.score + 1
              : currentState.computer.score + 1;
    }

    state = currentState.copyWith(
      phase: phase,
      player: updatedPlayer,
      computer: updatedComputer,
      message: 'Choose a number!',
      moveChoice: 0,
      computerChoice: 0,
      target: target,
      moveStatus: MoveStatus.next,
    );

    _startMoveTimer();
  }

  void _startMoveTimer() {
    if (state is! PracticeGameStarted) return;

    final currentState = state as PracticeGameStarted;
    int countdown = 5;
    state = currentState.copyWith(mainTimer: countdown);

    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state is! PracticeGameStarted) {
        timer.cancel();
        return;
      }

      final current = state as PracticeGameStarted;
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
    if (state is! PracticeGameStarted) return;

    final currentState = state as PracticeGameStarted;

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
    if (state is! PracticeGameStarted) return;

    final currentState = state as PracticeGameStarted;
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
    if (state is! PracticeGameStarted) return;

    if (playerMove == computerMove) {
      // OUT!
      _handleOut();
    } else {
      // Runs scored
      _handleRuns(playerMove, computerMove);
    }
  }

  void _handleOut() {
    if (state is! PracticeGameStarted) return;

    final currentState = state as PracticeGameStarted;

    if (currentState.player.isBatting) {
      // Player is out
      final updatedPlayer = currentState.player.copyWith(
        isOut: true,
        ballsFaced: currentState.player.ballsFaced + 1,
      );

      state = currentState.copyWith(
        player: updatedPlayer,
        message: 'Oh no! You are out!',
        moveStatus: MoveStatus.progressed,
      );
    } else {
      // Computer is out
      final updatedComputer = currentState.computer.copyWith(
        isOut: true,
        ballsFaced: currentState.computer.ballsFaced + 1,
      );

      state = currentState.copyWith(
        computer: updatedComputer,
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
    if (state is! PracticeGameStarted) return;

    final currentState = state as PracticeGameStarted;

    if (currentState.player.isBatting) {
      // Player is batting
      final updatedPlayer = currentState.player.copyWith(
        score: currentState.player.score + playerMove,
        ballsFaced: currentState.player.ballsFaced + 1,
      );

      state = currentState.copyWith(
        player: updatedPlayer,
        message: _getScoreMessage(playerMove),
        moveStatus: MoveStatus.progressed,
      );
    } else {
      // Computer is batting
      final updatedComputer = currentState.computer.copyWith(
        score: currentState.computer.score + computerMove,
        ballsFaced: currentState.computer.ballsFaced + 1,
      );

      state = currentState.copyWith(
        computer: updatedComputer,
        message: 'Computer scored $computerMove runs!',
        moveStatus: MoveStatus.progressed,
      );
    }

    // Check for chase completion in innings 2
    if (currentState.phase == GamePhase.innings2) {
      final firstInningsScore =
          currentState.player.isBatting
              ? currentState.computer.score
              : currentState.player.score;

      final currentScore =
          currentState.player.isBatting
              ? currentState.player.score + playerMove
              : currentState.computer.score + computerMove;

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
    if (state is! PracticeGameStarted) return;

    final currentState = state as PracticeGameStarted;

    // Check if current batsman is out or has faced 6 balls
    bool inningsEnded = false;

    if (currentState.player.isBatting) {
      inningsEnded =
          currentState.player.isOut || currentState.player.ballsFaced >= 6;
    } else {
      inningsEnded =
          currentState.computer.isOut || currentState.computer.ballsFaced >= 6;
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
    if (state is! PracticeGameStarted) return;

    final currentState = state as PracticeGameStarted;

    state = currentState.copyWith(
      message:
          currentState.player.isBatting
              ? 'Choose your next move!'
              : 'Stop the computer!',
      moveChoice: 0,
      computerChoice: 0,
      moveStatus: MoveStatus.next,
    );

    _startMoveTimer();
  }

  void _endGame() {
    if (state is! PracticeGameStarted) return;

    final currentState = state as PracticeGameStarted;

    // Determine winner
    String resultMessage;
    if (currentState.player.score > currentState.computer.score) {
      resultMessage =
          'Congratulations! You won by ${currentState.player.score - currentState.computer.score} runs!';
    } else if (currentState.computer.score > currentState.player.score) {
      resultMessage =
          'Computer wins by ${currentState.computer.score - currentState.player.score} runs!';
    } else {
      resultMessage = 'It\'s a tie! Great match!';
    }

    state = currentState.copyWith(
      phase: GamePhase.result,
      message: resultMessage,
      moveStatus: MoveStatus.end,
      mainTimer: 0,
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
    state = PracticeGameInitial();
  }
}

// PracticeGameState
abstract class PracticeGameState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PracticeGameInitial extends PracticeGameState {}

class PracticeGameStarted extends PracticeGameState {
  final GamePhase phase;
  final Player player;
  final Player computer;
  final bool isBattingFirst;
  final String message;
  final int mainTimer;
  final int moveChoice;
  final int computerChoice;
  final MoveStatus moveStatus;
  final int? target;
  final bool isPaused;

  PracticeGameStarted({
    this.phase = GamePhase.toss,
    required this.player,
    required this.computer,
    required this.isBattingFirst,
    this.message = '',
    this.mainTimer = 0,
    this.moveChoice = 0,
    this.computerChoice = 0,
    this.target,
    required this.moveStatus,
    this.isPaused = false,
  });

  PracticeGameStarted copyWith({
    GamePhase? phase,
    Player? player,
    Player? computer,
    bool? isBattingFirst,
    String? message,
    int? mainTimer,
    int? moveChoice,
    int? computerChoice,
    MoveStatus? moveStatus,
    int? target,
    bool? isPaused,
  }) {
    return PracticeGameStarted(
      phase: phase ?? this.phase,
      player: player ?? this.player,
      computer: computer ?? this.computer,
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
    player,
    computer,
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

class PracticeGameError extends PracticeGameState {
  final String error;

  PracticeGameError(this.error);

  @override
  List<Object?> get props => [error];

  @override
  String toString() => 'PracticeGameError: $error';
}

enum GamePhase { toss, innings1, innings2, result, startInnigs }

enum MoveStatus { next, wait, progress, progressed, start, end, paused }
