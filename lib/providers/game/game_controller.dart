import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_cricket/core/contstants/app_constants.dart';
import 'package:hand_cricket/models/game_player.dart';
import 'package:hand_cricket/models/game_room.dart';
import 'package:hand_cricket/providers/game/game_state.dart';
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
    gameFirestoreService.dispose();
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
      // computer
      final computer = GamePlayer(
        uid: 'computer',
        name: 'Computer',
        avatarUrl: AppConstants.computerAvatarUrl,
        type: PlayerType.computer,
        isBatting: !toss, // Computer bats opposite to player
      );

      state = GameWaiting(
        player: player,
        opponent: computer,
        mode: mode,
        mainTimer: 3,
        message: 'Game Starts in...',
        toss: toss,
        status: GameWaitingStatus.matched,
      );

      _startGameCountdown();
    } else {
      // ONLINE MODE

      state = GameWaiting(
        player: player,
        message: 'Waiting for opponent...',
        status: GameWaitingStatus.wait,
        toss: toss,
        mode: mode,
      );
      // start waiting timer
      _startWaitingTimer();

      _startMatching();
    }
  }

  void _startWaitingTimer() {
    if (state is! GameWaiting) return;

    int countdown = 60;
    _waitingTimer?.cancel();
    _waitingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state is! GameWaiting) {
        timer.cancel();
        return;
      }
      countdown--;
      if (countdown < 0) {
        // timed out
        timer.cancel();
        final currentState = state as GameWaiting;
        state = currentState.copyWith(
          status: GameWaitingStatus.timedOut,
          message: 'Could not any match yet!',
        );
      }
    });
  }

  void _startMatching() async {
    if (state is! GameWaiting) return;

    final currentState = state as GameWaiting;

    final room = await gameFirestoreService.checkAvailableGameRoom();

    if (room == null) {
      // create a room
      final room = GameRoom(
        id: 'temp',
        phase: GamePhase.waiting,
        player1: currentState.player,
        whoBattingFirst:
            currentState.toss ? PlayerType.player1 : PlayerType.player2,
        status: GameStatus.waiting,
      );
      final newRoom = await gameFirestoreService.createGameRoom(room);

      // update state with new room data
      state = currentState.copyWith(roomId: newRoom.id);

      // start listening opponent matching from firestore
      _listenGameRoom(newRoom.id);

      //
    } else {
      // join a room

      // change player type
      final player = currentState.player.copyWith(
        type: PlayerType.player2,
        isBatting: room.whoBattingFirst == PlayerType.player2,
      );
      final gameRoom = room.copyWith(
        player2: player,
        status: GameStatus.active,
        phase: GamePhase.toss,
      );
      await gameFirestoreService.joinGameRoom(gameRoom);

      // update state with opponent and player with updated player type
      state = currentState.copyWith(
        player: player,
        opponent: gameRoom.player1,
        status: GameWaitingStatus.matched,
        mainTimer: 3,
        roomId: room.id,
        toss: room.whoBattingFirst == PlayerType.player2,
        message: 'You are matched...',
      );

      // after matched cancel waiting timer
      _waitingTimer?.cancel();

      _startGameCountdown();

      // start listening opponent matching from firestore
      _listenGameRoom(room.id);
    }
  }

  void _listenGameRoom(String roomId) {
    gameFirestoreService.listeningGameRoom(roomId);
    gameFirestoreService.roomStream.listen((room) {
      // Only update if roomId matches
      final currentRoomId =
          (state is GameWaiting)
              ? (state as GameWaiting).roomId
              : (state is GameStarted)
              ? (state as GameStarted).roomId
              : null;
      if (currentRoomId == null || room.id != currentRoomId) return;

      // state is game waiting -> update opponent and match starts
      if (state is GameWaiting && room.player2 != null) {
        _updateOpponentMatched(room);
      }

      // state is game started -> synchronize game state
      if (state is GameStarted) {
        _synchronizeGameState(room);
      }
    });
  }

  void _synchronizeGameState(GameRoom room) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;
    if (room.player2 == null) return;

    final isPlayer1 = currentState.player.type == PlayerType.player1;

    // Get updated player data from room
    final myUpdatedPlayer = isPlayer1 ? room.player1 : room.player2!;
    final opponentUpdatedPlayer = isPlayer1 ? room.player2! : room.player1;

    // Get moves from room
    final myMove = isPlayer1 ? room.player1choice : room.player2choice;
    final oppMove = isPlayer1 ? room.player2choice : room.player1choice;

    // Update state with synchronized data
    final updatedState = currentState.copyWith(
      player: myUpdatedPlayer,
      opponent: opponentUpdatedPlayer,
      moveChoice: myMove,
      opponentChoice: oppMove,
      phase: room.phase,
      target: room.target,
      message: room.message,
    );

    state = updatedState;

    // Handle phase transitions
    if (room.phase != currentState.phase) {
      _handlePhaseTransition(room.phase, updatedState);
      return;
    }

    // Handle move processing - only process if both players have made moves and we haven't processed yet
    if (currentState.moveStatus == MoveStatus.wait &&
        myMove != 0 &&
        oppMove != 0 &&
        room.result == GameResultType.valid) {
      _moveTimer?.cancel();
      _processMoves(myMove);
    }

    // Handle game result
    if (room.phase == GamePhase.result && room.status == GameStatus.finished) {
      _handleGameResult(room);
    }
  }

  void _handlePhaseTransition(GamePhase newPhase, GameStarted currentState) {
    switch (newPhase) {
      case GamePhase.startInnigs:
        // Someone triggered innings start countdown
        if (currentState.phase != GamePhase.startInnigs) {
          _startInningsCountdown(
            currentState.phase == GamePhase.toss
                ? GamePhase.innings1
                : GamePhase.innings2,
          );
        }
        break;
      case GamePhase.innings1:
      case GamePhase.innings2:
        // Innings started, sync timer if needed
        if (currentState.moveStatus != MoveStatus.next) {
          _startMoveTimer();
        }
        break;
      case GamePhase.result:
        // Game ended
        break;
      default:
        break;
    }
  }

  void _handleGameResult(GameRoom room) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    state = GameResult(
      player: currentState.player,
      opponent: currentState.opponent,
      message: room.message,
      winner: room.winner,
      roomId: room.id,
    );
  }

  void _updateOpponentMatched(GameRoom room) {
    if (state is! GameWaiting) return;

    final currentState = state as GameWaiting;
    // Fix: return if player2 is null OR roomId doesn't match
    if (room.player2 == null || currentState.roomId != room.id) return;

    state = currentState.copyWith(
      opponent: room.player2,
      status: GameWaitingStatus.matched,
      mainTimer: 3,
      roomId: room.id,
      message: 'You are matched...',
    );

    // after matched cancel waiting timer
    _waitingTimer?.cancel();

    _startGameCountdown();
  }

  void _startGameCountdown() {
    if (state is! GameWaiting) return;

    final currentState = state as GameWaiting;

    _startTimer?.cancel();
    int countdown = 3;
    _startTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state is! GameWaiting) {
        timer.cancel();
        return;
      }
      countdown--;
      if (countdown < 0) {
        timer.cancel();
        _startingGame();
      } else {
        final newState = currentState.copyWith(
          mainTimer: countdown,
          message: 'Game Starts in...',
        );

        state = newState;
      }
    });
  }

  void _startingGame() {
    if (state is! GameWaiting) return;

    final currentState = state as GameWaiting;

    state = currentState.copyWith(status: GameWaitingStatus.started);
  }

  void startGame() async {
    if (state is! GameWaiting) return;

    final currentState = state as GameWaiting;

    state = GameStarted(
      phase: GamePhase.toss,
      player: currentState.player,
      opponent: currentState.opponent!,
      isBattingFirst: currentState.toss,
      message:
          currentState.toss ? 'You\'re batting first' : 'You\'re bowling first',
      moveChoice: 0,
      opponentChoice: 0,
      moveStatus: MoveStatus.start,
      mode: currentState.mode,
      roomId: currentState.roomId,
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

    // Update game room for online mode - ensure both players are synchronized
    if (currentState.mode == GameMode.online && currentState.roomId != null) {
      gameFirestoreService.updateGameRoom(
        id: currentState.roomId!,
        player: updatedPlayer,
        target: target,
        player1choice: 0,
        player2choice: 0,
        phase: phase,
        message: 'Choose a number!',
        result: GameResultType.valid, // Ready for moves
      );
    }

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
        // Handle time up scenario
        if (current.mode == GameMode.online) {
          // In online mode, auto-select random move if player hasn't chosen
          final finalChoice =
              0; // Default to 0 if no choice made
          // Update Firestore with auto-selected choice if needed
          if (current.moveChoice == 0) {
            final isPlayer1 = current.player.type == PlayerType.player1;
            if (isPlayer1) {
              gameFirestoreService.updateGameRoom(
                id: current.roomId!,
                player1choice: finalChoice,
              );
            } else {
              gameFirestoreService.updateGameRoom(
                id: current.roomId!,
                player2choice: finalChoice,
              );
            }
          }

          _processMoves(current.moveChoice);
          // Don't process moves here for online mode - let the room listener handle it
          // when both players have made their moves
        } else {
          // Practice mode - process immediately
          _processMoves(current.moveChoice);
        }
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

      // Update Firestore for online mode
      if (currentState.mode == GameMode.online && currentState.roomId != null) {
        final isPlayer1 = currentState.player.type == PlayerType.player1;
        if (isPlayer1) {
          gameFirestoreService.updateGameRoom(
            id: currentState.roomId!,
            player1choice: moveChoice,
            player: currentState.player,
            result: GameResultType.valid, // Indicate move is ready
          );
        } else {
          gameFirestoreService.updateGameRoom(
            id: currentState.roomId!,
            player2choice: moveChoice,
            player: currentState.player,
            result: GameResultType.valid, // Indicate move is ready
          );
        }
      }

      // For practice mode, process immediately when timer expires
      if (currentState.mode == GameMode.practice &&
          currentState.mainTimer > 0) {
        _moveTimer?.cancel();
        _processMoves(moveChoice);
      }
    }
  }

  void _processMoves(int playerChoice) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    int opponentChoice;
    if (currentState.mode == GameMode.online) {
      opponentChoice = currentState.opponentChoice;
      // Ensure opponent has made a move
      if (opponentChoice == 0) {
        // Wait for opponent move
        return;
      }
    } else {
      opponentChoice = Random().nextInt(6) + 1;
    }

    // Set moves and progress status
    state = currentState.copyWith(
      moveChoice: playerChoice,
      opponentChoice: opponentChoice,
      moveStatus: MoveStatus.progress,
      mainTimer: 0,
    );

    // Update game room with result processing status
    if (currentState.mode == GameMode.online && currentState.roomId != null) {
      gameFirestoreService.updateGameRoom(
        id: currentState.roomId!,
        result: GameResultType.invalid, // Mark as processing
      );
    }

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
          .addMove(currentState.moveChoice)
          .copyWith(isOut: true);
      // Also track opponent's bowling move
      final updatedOpponent = currentState.opponent.addMove(
        currentState.opponentChoice,
      );

      state = currentState.copyWith(
        player: updatedPlayer,
        opponent: updatedOpponent,
        message: 'Oh no! You are out!',
        moveStatus: MoveStatus.progressed,
      );

      // Update player on game room
      if (currentState.mode == GameMode.online && currentState.roomId != null) {
        final isPlayer1 = currentState.player.type == PlayerType.player1;
        gameFirestoreService.updateGameRoom(
          id: currentState.roomId!,
          player: updatedPlayer,
          message: 'Player ${isPlayer1 ? '1' : '2'} is out!',
          result: GameResultType.valid, // Mark result as processed
        );
      }
    } else {
      // Opponent is out - add the move that got them out
      final updatedOpponent = currentState.opponent
          .addMove(currentState.opponentChoice)
          .copyWith(isOut: true);
      // Also track player's bowling move
      final updatedPlayer = currentState.player.addMove(
        currentState.moveChoice,
      );

      state = currentState.copyWith(
        player: updatedPlayer,
        opponent: updatedOpponent,
        message: 'Yay! Bowled them out!',
        moveStatus: MoveStatus.progressed,
      );

      // Update opponent data for online mode - this requires updating the correct player in Firestore
      if (currentState.mode == GameMode.online && currentState.roomId != null) {
        final isPlayer1 = currentState.player.type == PlayerType.player1;
        gameFirestoreService.updateGameRoom(
          id: currentState.roomId!,
          player: updatedOpponent,
          message: 'Player ${isPlayer1 ? '2' : '1'} is out!',
          result: GameResultType.valid, // Mark result as processed
        );
      }
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
      // Also track opponent's bowling move
      final updatedOpponent = currentState.opponent.addMove(opponentMove);

      state = currentState.copyWith(
        player: updatedPlayer,
        opponent: updatedOpponent,
        message: _getScoreMessage(playerMove),
        moveStatus: MoveStatus.progressed,
      );

      // Update player on game room
      if (currentState.mode == GameMode.online && currentState.roomId != null) {
        gameFirestoreService.updateGameRoom(
          id: currentState.roomId!,
          player: updatedPlayer,
          message: _getScoreMessage(playerMove),
          result: GameResultType.valid, // Mark result as processed
        );
      }
    } else {
      // Opponent is batting - add their move and update score
      final updatedOpponent = currentState.opponent
          .addMove(opponentMove)
          .copyWith(score: currentState.opponent.score + opponentMove);
      // Also track player's bowling move
      final updatedPlayer = currentState.player.addMove(playerMove);

      state = currentState.copyWith(
        player: updatedPlayer,
        opponent: updatedOpponent,
        message:
            '${currentState.mode == GameMode.practice ? 'Computer' : 'Opponent'} scored $opponentMove runs!',
        moveStatus: MoveStatus.progressed,
      );

      // Update opponent data for online mode
      if (currentState.mode == GameMode.online && currentState.roomId != null) {
        gameFirestoreService.updateGameRoom(
          id: currentState.roomId!,
          player: updatedOpponent,
          message: 'Opponent scored $opponentMove runs!',
          result: GameResultType.valid, // Mark result as processed
        );
      }
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
        // Start innings 2 countdown timer
        // For online mode, update the game room to coordinate phase transition
        if (currentState.mode == GameMode.online &&
            currentState.roomId != null) {
          gameFirestoreService.updateGameRoom(
            id: currentState.roomId!,
            phase: GamePhase.startInnigs,
            message: 'Innings over! Preparing for second innings...',
          );
        }
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

    // Update state on gameroom to reset moves and prepare for next ball
    if (currentState.mode == GameMode.online && currentState.roomId != null) {
      // Reset both players' choices for next ball
      gameFirestoreService.updateGameRoom(
        id: currentState.roomId!,
        player: currentState.player,
        player1choice: 0,
        player2choice: 0,
        message:
            currentState.player.isBatting
                ? 'Choose your next move!'
                : 'Stop the opponent!',
        result: GameResultType.valid, // Ready for next move
      );
    }

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
    bool isTie = false;
    if (currentState.player.score > currentState.opponent.score) {
      resultMessage =
          'Congratulations! You won by ${currentState.player.score - currentState.opponent.score} runs!';
      winner = currentState.player.type;
    } else if (currentState.opponent.score > currentState.player.score) {
      resultMessage =
          '${currentState.opponent.name} wins by ${currentState.opponent.score - currentState.player.score} runs!';
      winner = currentState.opponent.type;
    } else {
      isTie = true;
      resultMessage = 'It\'s a tie! Great match!';
    }

    // update game result on gameroom
    if (currentState.mode == GameMode.online && currentState.roomId != null) {
      gameFirestoreService.updateGameRoom(
        id: currentState.roomId!,
        player: currentState.player,
        message: resultMessage,
        phase: GamePhase.result,
        result: GameResultType.valid,
        isTie: isTie,
        winner: winner,
        status: GameStatus.finished,
      );
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
