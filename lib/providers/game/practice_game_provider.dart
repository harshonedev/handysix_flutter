import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_cricket/core/contstants/app_constants.dart';
import 'package:hand_cricket/models/game_player.dart';
import 'package:hand_cricket/models/game_room.dart';
import 'package:hand_cricket/providers/game/game_state.dart';
import 'package:hand_cricket/services/auth_service.dart';

class PracticeGameProvider extends StateNotifier<GameState> {
  final AuthService authService;
  Timer? _gameTimer;
  Timer? _moveTimer;
  Timer? _startTimer;
  Timer? _waitingTimer;

  // Pause/Resume state variables
  int _pausedMainTimer = 0;
  GamePhase? _pausedPhase;
  MoveStatus? _pausedMoveStatus;

  PracticeGameProvider({required this.authService}) : super(GameInitial());

  @override
  void dispose() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    _startTimer?.cancel();
    _waitingTimer?.cancel();
    super.dispose();
  }

  void initializeGame() async {
    // Get current user from auth service
    final user = authService.getCurrentAuthUser();
    if (user == null) {
      state = GameError('User not authenticated');
      return;
    }

    // Do toss
    final toss =
        Random().nextBool(); // true for batting first, false for bowling first

    final player = GamePlayer(
      uid: user.uid,
      name: user.displayName ?? 'Guest',
      avatarUrl: user.photoURL ?? AppConstants.avatarUrl,
      type: PlayerType.player1,
      isBatting: toss,
    );

    // computer
    final computer = GamePlayer(
      uid: 'computer',
      name: 'Computer',
      avatarUrl: AppConstants.computerAvatarUrl,
      type: PlayerType.computer,
      isBatting: !toss, // Computer bats opposite to player
    );

    state = GameStarted(
      phase: GamePhase.toss,
      player: player,
      opponent: computer,
      isBattingFirst: toss,
      message: toss ? 'You\'re batting first' : 'You\'re bowling first',
      moveChoice: 0,
      opponentChoice: 0,
      moveStatus: MoveStatus.start,
      mode: GameMode.practice,
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
        return currentState.player.isBatting
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
            ? (currentState.player.ballsFaced == 6 || currentState.player.isOut
                ? GamePhase.innings2
                : GamePhase.innings1)
            : (currentState.opponent.ballsFaced == 6 ||
                    currentState.opponent.isOut
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
              ? currentState.player.score + 1
              : currentState.opponent.score + 1;

      message =
          currentState.isBattingFirst
              ? 'Now it\'s your turn to bowl!\nDefend $target'
              : 'Now it\'s your turn to bat!\nTarget $target';
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

  void _startInnings(GamePhase phase) async {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    int? target;
    GamePlayer updatedPlayer = currentState.player;
    GamePlayer updatedOpponent = currentState.opponent;

    if (phase == GamePhase.innings2) {
      // Switch batting/bowling for innings 2
      updatedPlayer = currentState.player.copyWith(
        isBatting: !currentState.player.isBatting,
      );
      updatedOpponent = currentState.opponent.copyWith(
        isBatting: !currentState.opponent.isBatting,
      );

      target =
          currentState.isBattingFirst
              ? currentState.player.score + 1
              : currentState.opponent.score + 1;
    }

    state = currentState.copyWith(
      phase: phase,
      player: updatedPlayer,
      opponent: updatedOpponent,
      message: 'Choose a number!',
      moveChoice: 0,
      opponentChoice: 0,
      target: target,
      moveStatus: MoveStatus.next,
    );

    _startMoveTimer();
  }

  void _startMoveTimer() {
    if (state is! GameStarted) return;
    int countdown = 5;

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
        // process moves with current move choice
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
      // Update local state first
      state = currentState.copyWith(
        moveChoice: moveChoice,
        message:
            currentState.mode == GameMode.online
                ? 'Waiting for opponent...'
                : currentState.message,
      );

      // For practice mode, process immediately when timer expires
      _moveTimer?.cancel();
      _processMoves(moveChoice);
    }
  }

  void _processMoves(int playerChoice) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    final int opponentChoice = Random().nextInt(6) + 1;

    // Set moves and progress status
    state = currentState.copyWith(
      moveChoice: playerChoice,
      opponentChoice: opponentChoice,
      moveStatus: MoveStatus.progress,
      mainTimer: 0,
    );

    // Process result
    _processResult(playerChoice, opponentChoice);
  }

  void _processResult(int playerMove, int opponentMove) {
    if (state is! GameStarted) return;

    if (playerMove == opponentMove) {
      // OUT!
      _handleOut();
    } else {
      // Runs scored
      _handleRuns(playerMove, opponentMove);
    }
  }

  void _handleOut() {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    if (currentState.player.isBatting) {
      // Player is out - add the move that got them out
      final updatedPlayer = currentState.player
          .addMove(-1) //  -1 indicates out
          .copyWith(isOut: true);

      state = currentState.copyWith(
        player: updatedPlayer,
        opponent: currentState.opponent,
        message: 'Oh no! You are out!',
        moveStatus: MoveStatus.progressed,
      );
    } else {
      // Opponent is out - add the move that got them out
      final updatedOpponent = currentState.opponent
          .addMove(-1) // -1 indicates out
          .copyWith(isOut: true);

      state = currentState.copyWith(
        player: currentState.player,
        opponent: updatedOpponent,
        message: 'Yay! Bowled them out!',
        moveStatus: MoveStatus.progressed,
      );
    }

    // Continue game after delay
    Timer(Duration(seconds: 2), () {
      _checkInningsEnd();
    });
  }

  void _handleRuns(int playerMove, int opponentMove) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    if (currentState.player.isBatting) {
      // Player is batting - add their move and update score
      final updatedPlayer = currentState.player
          .addMove(playerMove)
          .copyWith(score: currentState.player.score + playerMove);

      state = currentState.copyWith(
        player: updatedPlayer,
        opponent: currentState.opponent,
        message: _getScoreMessage(playerMove),
        moveStatus: MoveStatus.progressed,
      );
    } else {
      // Opponent is batting - add their move and update score
      final updatedOpponent = currentState.opponent
          .addMove(opponentMove)
          .copyWith(score: currentState.opponent.score + opponentMove);

      state = currentState.copyWith(
        player: currentState.player,
        opponent: updatedOpponent,
        message:
            '${currentState.mode == GameMode.practice ? 'Computer' : 'Opponent'} scored $opponentMove runs!',
        moveStatus: MoveStatus.progressed,
      );
    }

    // Check for chase completion in innings 2
    if (currentState.phase == GamePhase.innings2) {
      final firstInningsScore =
          currentState.player.isBatting
              ? currentState.opponent.score
              : currentState.player.score;

      final currentScore =
          currentState.player.isBatting
              ? currentState.player.score + playerMove
              : currentState.opponent.score + opponentMove;

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

    if (currentState.player.isBatting) {
      inningsEnded =
          currentState.player.isOut || currentState.player.ballsFaced >= 6;
    } else {
      inningsEnded =
          currentState.opponent.isOut || currentState.opponent.ballsFaced >= 6;
    }

    if (inningsEnded) {
      if (currentState.phase == GamePhase.innings1) {
        // Start innings 2
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
          currentState.player.isBatting
              ? 'Choose your next move!'
              : 'Stop the opponent!',
      moveChoice: 0,
      opponentChoice: 0,
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
    if (currentState.player.score > currentState.opponent.score) {
      resultMessage =
          'Congratulations! You won by ${currentState.player.score - currentState.opponent.score} runs!';
      winner = currentState.player.type;
    } else if (currentState.opponent.score > currentState.player.score) {
      resultMessage =
          '${currentState.opponent.name} wins by ${currentState.opponent.score - currentState.player.score} runs!';
      winner = currentState.opponent.type;
    } else {
      resultMessage = 'It\'s a tie! Great match!';
    }

    state = GameResult(
      player: currentState.player,
      opponent: currentState.opponent,
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
