import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_cricket/models/game_player.dart';
import 'package:hand_cricket/models/game_room.dart';
import 'package:hand_cricket/providers/game/game_state.dart';
import 'package:hand_cricket/services/auth_service.dart';
import 'package:hand_cricket/services/game_socket_service.dart';
import 'package:logger/logger.dart';

class OnlineGameProvider extends StateNotifier<GameState> {
  final AuthService authService;
  final GameSocketService? gameSocketService;
  final Logger _logger = Logger();

  Timer? _countdownTimer;
  Timer? _moveTimer;

  // Stream subscriptions
  StreamSubscription? _matchmakingStatusSub;
  StreamSubscription? _gameMatchedSub;
  StreamSubscription? _gameStartCountdownSub;
  StreamSubscription? _playerMovedSub;
  StreamSubscription? _moveResultSub;
  StreamSubscription? _inningsEndSub;
  StreamSubscription? _inningsStartSub;
  StreamSubscription? _continueInningsSub;
  StreamSubscription? _gameOverSub;
  StreamSubscription? _playerDisconnectedSub;
  StreamSubscription? _errorSub;

  OnlineGameProvider({
    required this.authService,
    required this.gameSocketService,
  }) : super(GameInitial()) {
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _moveTimer?.cancel();
    _cancelAllSubscriptions();
    super.dispose();
  }

  void _cancelAllSubscriptions() {
    _matchmakingStatusSub?.cancel();
    _gameMatchedSub?.cancel();
    _gameStartCountdownSub?.cancel();
    _playerMovedSub?.cancel();
    _moveResultSub?.cancel();
    _inningsEndSub?.cancel();
    _inningsStartSub?.cancel();
    _continueInningsSub?.cancel();
    _gameOverSub?.cancel();
    _playerDisconnectedSub?.cancel();
    _errorSub?.cancel();
  }

  /// Setup all socket event listeners
  void _setupSocketListeners() {
    if (gameSocketService == null) return;

    _matchmakingStatusSub = gameSocketService!.matchmakingStatusStream.listen(
      _handleMatchmakingStatus,
    );

    _gameMatchedSub = gameSocketService!.gameMatchedStream.listen(
      _handleGameMatched,
    );

    _gameStartCountdownSub = gameSocketService!.gameStartCountdownStream.listen(
      _handleGameStartCountdown,
    );

    _playerMovedSub = gameSocketService!.playerMovedStream.listen(
      _handlePlayerMoved,
    );

    _moveResultSub = gameSocketService!.moveResultStream.listen(
      _handleMoveResult,
    );

    _inningsEndSub = gameSocketService!.inningsEndStream.listen(
      _handleInningsEnd,
    );

    _inningsStartSub = gameSocketService!.inningsStartStream.listen(
      _handleInningsStart,
    );

    _continueInningsSub = gameSocketService!.continueInningsStream.listen(
      _handleContinueInnings,
    );

    _gameOverSub = gameSocketService!.gameOverStream.listen(_handleGameOver);

    _playerDisconnectedSub = gameSocketService!.playerDisconnectedStream.listen(
      _handlePlayerDisconnected,
    );

    _errorSub = gameSocketService!.errorStream.listen(_handleError);
  }

  /// Initialize and connect to game
  Future<void> initializeGame() async {
    final user = authService.getCurrentAuthUser();
    if (user == null) {
      state = GameError('User not authenticated');
      return;
    }

    if (gameSocketService == null) {
      state = GameError('Socket service not available');
      return;
    }

    try {
      // Connect to socket server
      await gameSocketService!.connect();

      // Create initial player
      final player = GamePlayer(
        uid: user.uid,
        name: user.displayName ?? 'Guest',
        avatarUrl: user.photoURL ?? '',
        type: PlayerType.player1,
        isBatting: false, // Will be determined by server
      );

      state = GameWaiting(
        player: player,
        message: 'Connecting...',
        status: GameWaitingStatus.wait,
        toss: false, // Will be determined by server
        mode: GameMode.online,
      );

      // Start matchmaking
      gameSocketService!.findGame();
    } catch (e) {
      _logger.e('Failed to initialize game: $e');
      state = GameError('Failed to connect to server');
    }
  }

  /// Handle matchmaking status updates
  void _handleMatchmakingStatus(Map<String, dynamic> data) {
    if (state is! GameWaiting) return;

    final currentState = state as GameWaiting;
    state = currentState.copyWith(
      message: data['message'] ?? 'Searching for opponent...',
      status: GameWaitingStatus.wait,
    );
  }

  /// Handle game matched event
  void _handleGameMatched(Map<String, dynamic> data) {
    if (state is! GameWaiting) return;

    final currentState = state as GameWaiting;

    // Parse players
    final player1 = GamePlayer.fromJson(data['player1']);
    final player2 = GamePlayer.fromJson(data['player2']);

    // Determine which player is current user
    final isPlayer1 = player1.uid == currentState.player.uid;
    final player = isPlayer1 ? player1 : player2;
    final opponent = isPlayer1 ? player2 : player1;

    // Update player type
    final updatedPlayer = player.copyWith(
      type: isPlayer1 ? PlayerType.player1 : PlayerType.player2,
    );

    state = currentState.copyWith(
      player: updatedPlayer,
      opponent: opponent,
      roomId: data['gameId'],
      message: data['message'] ?? 'Opponent found!',
      status: GameWaitingStatus.matched,
    );

    _logger.i('Game matched: ${data['gameId']}');
  }

  /// Handle game start countdown
  void _handleGameStartCountdown(Map<String, dynamic> data) {
    if (state is! GameWaiting) return;

    final currentState = state as GameWaiting;
    int countdown = data['countdown'] ?? 3;

    state = currentState.copyWith(
      message: data['message'] ?? 'Game starting in $countdown...',
      mainTimer: countdown,
      status: GameWaitingStatus.started,
    );

    // Start countdown timer
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state is! GameWaiting) {
        timer.cancel();
        return;
      }

      countdown--;
      if (countdown < 0) {
        timer.cancel();
        _transitionToGameStarted();
      } else {
        final current = state as GameWaiting;
        state = current.copyWith(
          mainTimer: countdown,
          message: 'Game starting in $countdown...',
        );
      }
    });
  }

  /// Transition from waiting to game started
  void _transitionToGameStarted() {
    if (state is! GameWaiting) return;

    final currentState = state as GameWaiting;

    if (currentState.opponent == null) {
      state = GameError('Opponent not found');
      return;
    }

    state = GameStarted(
      phase: GamePhase.startInnigs,
      player: currentState.player,
      opponent: currentState.opponent!,
      isBattingFirst: currentState.player.isBatting,
      message: 'Get ready!',
      moveChoice: 0,
      opponentChoice: 0,
      moveStatus: MoveStatus.start,
      mode: GameMode.online,
      isPaused: false,
      roomId: currentState.roomId,
      mainTimer: 3,
    );
  }

  /// Handle innings start
  void _handleInningsStart(Map<String, dynamic> data) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    state = currentState.copyWith(
      phase: data['innings'] == 1 ? GamePhase.innings1 : GamePhase.innings2,
      message: data['message'] ?? 'Choose your move!',
      target: data['target'],
      moveStatus: MoveStatus.next,
      moveChoice: 0,
      opponentChoice: 0,
    );

    // Start move timer
    _startMoveTimer();
  }

  /// Start move timer (5 seconds to make a move)
  void _startMoveTimer() {
    if (state is! GameStarted) return;

    int countdown = 5;
    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state is! GameStarted) {
        timer.cancel();
        return;
      }

      final current = state as GameStarted;
      countdown--;

      if (countdown < 0) {
        timer.cancel();
        // Auto-submit random move if no move made
        if (current.moveChoice == 0) {
          final randomMove = DateTime.now().millisecond % 6 + 1;
          chooseMove(randomMove);
        }
      } else {
        state = current.copyWith(mainTimer: countdown);
      }
    });
  }

  /// Handle player choosing a move
  void chooseMove(int moveChoice) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    // Don't allow move if paused or already submitted
    if (currentState.isPaused || currentState.moveChoice != 0) return;

    // Only allow during innings
    if (currentState.phase != GamePhase.innings1 &&
        currentState.phase != GamePhase.innings2) {
      return;
    }

    // Update state with chosen move
    state = currentState.copyWith(
      moveChoice: moveChoice,
      moveStatus: MoveStatus.wait,
      message: 'Waiting for opponent...',
    );

    // Submit move to server
    gameSocketService!.submitMove(currentState.roomId!, moveChoice);

    _logger.i('Move submitted: $moveChoice');
  }

  /// Handle when opponent makes a move
  void _handlePlayerMoved(Map<String, dynamic> data) {
    if (state is! GameStarted) return;

    // Just log, actual move result comes in move_result event
    _logger.d('Opponent moved');
  }

  /// Handle move result from server
  void _handleMoveResult(Map<String, dynamic> data) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    // Parse updated players
    final player1 = GamePlayer.fromJson(data['player1']);
    final player2 = GamePlayer.fromJson(data['player2']);

    // Determine which is current player
    final isPlayer1 = player1.uid == currentState.player.uid;
    final updatedPlayer = isPlayer1 ? player1 : player2;
    final updatedOpponent = isPlayer1 ? player2 : player1;

    final message = data['message'] ?? '';
    final isOut = data['isOut'] ?? false;

    state = currentState.copyWith(
      player: updatedPlayer,
      opponent: updatedOpponent,
      moveChoice: data['player1Move'],
      opponentChoice: data['player2Move'],
      moveStatus: MoveStatus.progress,
      message: message,
    );

    _logger.i('Move result: $message (Out: $isOut)');

    // Stop move timer
    _moveTimer?.cancel();
  }

  /// Handle innings end
  void _handleInningsEnd(Map<String, dynamic> data) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    // Parse updated players with swapped batting
    final player1 = GamePlayer.fromJson(data['player1']);
    final player2 = GamePlayer.fromJson(data['player2']);

    final isPlayer1 = player1.uid == currentState.player.uid;
    final updatedPlayer = isPlayer1 ? player1 : player2;
    final updatedOpponent = isPlayer1 ? player2 : player1;

    state = currentState.copyWith(
      player: updatedPlayer,
      opponent: updatedOpponent,
      message: data['message'] ?? 'Innings ended',
      phase: GamePhase.startInnigs,
      moveStatus: MoveStatus.end,
    );

    _logger.i('Innings ${data['innings']} ended: ${data['reason']}');
  }

  /// Handle continue innings (next ball)
  void _handleContinueInnings(Map<String, dynamic> data) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    state = currentState.copyWith(
      message: data['message'] ?? 'Choose your move!',
      moveChoice: 0,
      opponentChoice: 0,
      moveStatus: MoveStatus.next,
    );

    // Restart move timer
    _startMoveTimer();
  }

  /// Handle game over
  void _handleGameOver(Map<String, dynamic> data) {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    // Parse final player states
    final player1 = GamePlayer.fromJson(data['player1']);
    final player2 = GamePlayer.fromJson(data['player2']);

    final isPlayer1 = player1.uid == currentState.player.uid;
    final finalPlayer = isPlayer1 ? player1 : player2;
    final finalOpponent = isPlayer1 ? player2 : player1;

    final winnerType =
        data['winner'] != null
            ? PlayerType.values.firstWhere((e) => e.name == data['winner'])
            : null;

    state = GameResult(
      player: finalPlayer,
      opponent: finalOpponent,
      message: data['message'] ?? 'Game Over',
      winner: winnerType,
      roomId: currentState.roomId,
    );

    _logger.i('Game over: ${data['message']}');

    // Cancel all timers
    _countdownTimer?.cancel();
    _moveTimer?.cancel();
  }

  /// Handle player disconnection
  void _handlePlayerDisconnected(Map<String, dynamic> data) {
    _logger.w('Player disconnected: ${data['disconnectedPlayer']}');

    // Game over event will be sent separately
  }

  /// Handle errors
  void _handleError(Map<String, dynamic> data) {
    _logger.e('Game error: ${data['type']} - ${data['message']}');

    if (state is GameWaiting) {
      final currentState = state as GameWaiting;
      state = currentState.copyWith(
        message: data['message'] ?? 'An error occurred',
      );
    } else if (state is GameStarted) {
      final currentState = state as GameStarted;
      state = currentState.copyWith(
        message: data['message'] ?? 'An error occurred',
      );
    }
  }

  /// Pause game
  void pauseGame() {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    if (currentState.isPaused || currentState.roomId == null) return;

    gameSocketService!.pauseGame(currentState.roomId!);
  }

  /// Resume game
  void resumeGame() {
    if (state is! GameStarted) return;

    final currentState = state as GameStarted;

    if (!currentState.isPaused || currentState.roomId == null) return;

    gameSocketService!.resumeGame(currentState.roomId!);
  }

  /// Cancel matchmaking
  void cancelMatchmaking() {
    if (state is! GameWaiting) return;

    gameSocketService!.cancelMatchmaking();
    state = GameInitial();
  }

  /// Exit game
  void exitGame() {
    _countdownTimer?.cancel();
    _moveTimer?.cancel();
    state = GameInitial();
  }

  /// Reset game
  void resetGame() {
    _countdownTimer?.cancel();
    _moveTimer?.cancel();
    state = GameInitial();
  }
}
