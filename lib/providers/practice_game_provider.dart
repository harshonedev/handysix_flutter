import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_cricket/core/contstants/app_constants.dart';
import 'package:hand_cricket/models/player.dart';
import 'package:hand_cricket/services/practice_game_service.dart';
import 'package:hand_cricket/services/timer_service.dart';

class PracticeGameProvider extends StateNotifier<PracticeGameState> {
  final PracticeGameService _practiceGameService;
  final TimerService _timerService;
  PracticeGameProvider({required PracticeGameService practiceGameService, required TimerService timerService})
    : _practiceGameService = practiceGameService,
      _timerService = timerService,
      super(PracticeGameInitial());


  
  void _listenStream() {
    _timerService.timerStream.listen((timeLeft) {
      // Handle timer updates here

      // Update the initalized state with the time left
      if (state is PracticeGameInitialized) {
        final currentState = state as PracticeGameInitialized;
        final updatedState = currentState.copyWith(leftDuration: timeLeft);
        state = updatedState;
      }

     // Update the game started state with the time left
      if (state is PracticeGameStarted) {
        final currentState = state as PracticeGameStarted;
        state = currentState.copyWith(leftDuration: timeLeft);
      } 
      
      print('Time left: $timeLeft seconds');
    });

    _timerService.timerFinishedStream.listen((finished) {
      if (finished) {
        // Handle timer finished event

        if (state is PracticeGameInitialized) {
          _startPracticeGame();
        }

        if (state is PracticeGameStarted) {
          final currentState = state as PracticeGameStarted;
          state = currentState.copyWith(isWaiting: false); // Update waiting state
          // Examine the move 
        }

        print('Timer finished');
      }
    });
  }

  Future<void> initializePracticeGame(String userName, String userAvatarUrl) async {
    try {
      state = PracticeGameLoading();
      
      // Initialize the computer player
      final computerPlayer = Player(
        name: 'Handy AI',
        avatarUrl: AppConstants.computerAvatarUrl,
        type: PlayerType.computer,
      );

      // Initialize the user player
      final userPlayer = Player(
        name: userName,
        avatarUrl: userAvatarUrl,
        type: PlayerType.player1,
      );

      // Simulate a toss to decide who bats first
      final tossResult = _practiceGameService.toss();
      final isBattingFirst = tossResult == 1; // 1 for bat, 2 for bowl

      // Update the state with the initialized game
      state = PracticeGameInitialized(
        computerPlayer: computerPlayer,
        userPlayer: userPlayer,
        isBattingFirst: isBattingFirst,
      );

      // start match timer 
      await _timerService.startMatchStartTimer();

      // Start listening to the timer stream
      _listenStream();

    } catch (e) {
      state = PracticeGameError('Failed to initialize practice game: $e');
    }

  }

  Future<void> _startPracticeGame() async {
    try {
      if (state is! PracticeGameInitialized) {
        state = PracticeGameError('Game not initialized');
      }

      final currentState = state as PracticeGameInitialized;
      final computerPlayer = currentState.computerPlayer;
      final userPlayer = currentState.userPlayer;
      final isBattingFirst = currentState.isBattingFirst;

      // Determine who is batting
      final isBatting = isBattingFirst;

      // Update the state to indicate the game has started
      state = PracticeGameStarted(
        computerPlayer: computerPlayer,
        userPlayer: userPlayer,
        isFirstInnings: true, // Assuming first innings for practice game
        isBatting: isBatting,
        isBattingFirst: isBattingFirst,
        isWaiting: true, 
      );

      // Start the timer for the practice game without delay
      await _timerService.startTimer(matchStartDelay: 0); // without delay



    } catch (e) {
      state = PracticeGameError('Failed to start practice game: $e');
    }
  }

}



// PracticeGameState and its subclasses
abstract class PracticeGameState {}

class PracticeGameInitial extends PracticeGameState {}

class PracticeGameLoading extends PracticeGameState {}

class PracticeGameStarted extends PracticeGameState {
  final Player computerPlayer;
  final Player userPlayer;
  final bool isFirstInnings;
  final bool isBatting;
  final bool isBattingFirst;
  final bool isWaiting;  // to indicate if the game is waiting for next move 
  final int? leftDuration; // time left for the next move

  PracticeGameStarted({
    required this.computerPlayer,
    required this.userPlayer,
    this.isFirstInnings = true,
    required this.isBatting,
    required this.isBattingFirst,
    required this.isWaiting,
    this.leftDuration,
  });

  PracticeGameStarted copyWith({
    Player? computerPlayer,
    Player? userPlayer,
    bool? isFirstInnings,
    bool? isBatting,
    bool? isBattingFirst,
    bool? isWaiting,
    int? leftDuration,
  }) {
    return PracticeGameStarted(
      computerPlayer: computerPlayer ?? this.computerPlayer,
      userPlayer: userPlayer ?? this.userPlayer,
      isFirstInnings: isFirstInnings ?? this.isFirstInnings,
      isBatting: isBatting ?? this.isBatting,
      isBattingFirst: isBattingFirst ?? this.isBattingFirst,
      isWaiting: isWaiting ?? this.isWaiting,
      leftDuration: leftDuration ?? this.leftDuration,
    );
  }
}

class PracticeGameInitialized extends PracticeGameState {
  final Player computerPlayer;
  final Player userPlayer;
  final bool isBattingFirst;
  final int? leftDuration;

  PracticeGameInitialized({
    required this.computerPlayer,
    required this.userPlayer,
    required this.isBattingFirst,
    this.leftDuration
  });

  PracticeGameInitialized copyWith({
    Player? computerPlayer,
    Player? userPlayer,
    bool? isBattingFirst,
    int? leftDuration,
  }) {
    return PracticeGameInitialized(
      computerPlayer: computerPlayer ?? this.computerPlayer,
      userPlayer: userPlayer ?? this.userPlayer,
      isBattingFirst: isBattingFirst ?? this.isBattingFirst,
      leftDuration: leftDuration ?? this.leftDuration,
    );
  }
}

class PracticeGameError extends PracticeGameState {
  final String message;

  PracticeGameError(this.message);
}
