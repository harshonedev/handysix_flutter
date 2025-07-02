import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_cricket/core/contstants/app_constants.dart';
import 'package:hand_cricket/models/player.dart';
import 'package:hand_cricket/services/auth_service.dart';

class PracticeGameController extends StateNotifier<PracticeGameState> {
  final AuthService authService;
  PracticeGameController({required this.authService})
    : super(PracticeGameInitial());

  // Add methods to handle game logic, state updates, etc.
  void startGame() async {
    // get current user from auth service
    final user = authService.getCurrentUser();
    if (user == null) {
      state = PracticeGameErorr('User not authenticated');
      return;
    }

    // do toss
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
      isBatting: toss,
    );
    state = PracticeGameStarted(
      phase: GamePhase.toss,
      player: player,
      computer: computer,
      isBattingFirst: toss,
      message: toss ? 'You will bat first' : 'You will bowl first.',
      mainTimer: 3,
      moveChoice: 0,
    );

    // Simulate the innings
    while (state is PracticeGameStarted) {
      final currentState = state as PracticeGameStarted;

      // check the balls faced by player and computer
      if (currentState.player.isBatting && currentState.player.ballsFaced <= 6) {
        // player is batting he face 6 balls
        if (currentState.phase == GamePhase.innings1) {
          state = currentState.copyWith(
            phase: GamePhase.innings2,
            player: currentState.player.copyWith(isBatting: false),
            computer: currentState.computer.copyWith(isBatting: true),
            message: 'Now, it\'s your turn to bowl.',
          );
          await Future.delayed(Duration(seconds: 1));

          // break this itteration
          continue;
        } else {
          // innings 2 -> game over
          state = currentState.copyWith(
            phase: GamePhase.result,
            message: 'Game Over!',
          );
          await Future.delayed(Duration(seconds: 1));
          break; // Exit the loop
        }
      }

      if (currentState.computer.isBatting &&
          currentState.computer.ballsFaced <= 6) {
        // computer is batting he face 6 balls
        if (currentState.phase == GamePhase.innings1) {
          state = currentState.copyWith(
            phase: GamePhase.result,
            computer: currentState.computer.copyWith(isBatting: false),
            player: currentState.player.copyWith(isBatting: true),
            message: 'Now, it\'s your turn to bat.',
          );
          await Future.delayed(Duration(seconds: 1));

          // break this itteration
          continue;
        } else {
          // innings 1 -> game over
          state = currentState.copyWith(
            phase: GamePhase.result,
            message: 'Game Over!',
          );
          await Future.delayed(Duration(seconds: 1));
          break; // Exit the loop
        }
      }

      // timer
      for (int i = 0; i <= 3; i++) {
        if (state is PracticeGameStarted) {
          state = currentState.copyWith(
            mainTimer: 3 - i,
            message:
                currentState.phase == GamePhase.innings1 ||
                        currentState.phase == GamePhase.innings2
                    ? 'Choose a number.'
                    : currentState.message,
          );
          await Future.delayed(Duration(seconds: 1));
        }
      }
      // After toss, start the first innings
      if (currentState.phase == GamePhase.toss) {
        state = currentState.copyWith(
          phase: GamePhase.innings1,
          message:
              currentState.isBattingFirst
                  ? 'You are batting first.'
                  : 'You are bowling first.',
          mainTimer: 3, // Reset timer for innings
        );
      }

      // if the game is in innings1 or innings2, validate the move choice
      if (currentState.phase == GamePhase.innings1 ||
          currentState.phase == GamePhase.innings2) {
        final moveChoice = currentState.moveChoice;
        final computerMoveChoice =
            Random().nextInt(6) + 1; // Simulate computer's random move choice
        if (moveChoice == computerMoveChoice) {
          // If both player and computer choose the same number, it's an out

          if (currentState.player.isBatting) {
            // Player is out
            final updatedPlayer = currentState.player.copyWith(
              isOut: true,
              isBatting: false,
              ballsFaced: currentState.player.ballsFaced + 1,
            );
            final updatedComputer = currentState.computer.copyWith(
              isBatting:
                  currentState.phase == GamePhase.innings1
                      ? true
                      : false, // Computer bats in innings1, bowls in innings2
            );
            state = currentState.copyWith(
              player: updatedPlayer,
              computer: updatedComputer,
              message: 'Oh no! You are out.',
            );
            await Future.delayed(Duration(seconds: 1));
          } else {
            // Computer is out
            final updatedComputer = currentState.computer.copyWith(
              isOut: true,
              isBatting: false,
              ballsFaced: currentState.computer.ballsFaced + 1,
            );
            final updatedPlayer = currentState.player.copyWith(
              isBatting:
                  currentState.phase == GamePhase.innings1 ? true : false,
            );
            state = currentState.copyWith(
              computer: updatedComputer,
              player: updatedPlayer,
              message: 'Yay! Bowled\'em out.',
            );
            await Future.delayed(Duration(seconds: 1));
          }

          // check if innings1 -> innings2 else inings2 -> result
          if (currentState.phase == GamePhase.innings1) {
            state = currentState.copyWith(
              phase: GamePhase.innings2,
              message:
                  currentState.player.isBatting
                      ? 'Now, it\'s turn to bowl.'
                      : 'Now, it\'s your turn to bat.',
              mainTimer: 3,
            );
            await Future.delayed(Duration(seconds: 1));
          } else {
            // If it's innings2, then the game is over
            state = currentState.copyWith(
              phase: GamePhase.result,
              message: 'Game Over!',
            );
            await Future.delayed(Duration(seconds: 1));
            break; // Exit the loop
          }
        } else {
          // If the player and computer choose different numbers, update scores
          if (currentState.player.isBatting) {
            // Player is batting
            final updatedPlayer = currentState.player.copyWith(
              score: currentState.player.score + moveChoice,
              ballsFaced: currentState.player.ballsFaced + 1,
            );
            state = currentState.copyWith(
              player: updatedPlayer,
              message: _showMessaageByScore(moveChoice),
            );
            await Future.delayed(Duration(seconds: 1));
          } else {
            // Computer is batting
            final updatedComputer = currentState.computer.copyWith(
              score: currentState.computer.score + computerMoveChoice,
              ballsFaced: currentState.computer.ballsFaced + 1,
            );
            state = currentState.copyWith(
              computer: updatedComputer,
              message: 'Oh No! Computer scored $computerMoveChoice runs}',
            );
            await Future.delayed(Duration(seconds: 1));
          }
        }
      }
    }
  }

  void chooseMove(int moveChoice) {
    if (state is PracticeGameStarted) {
      final currentState = state as PracticeGameStarted;
      // Update the move choice
      state = currentState.copyWith(moveChoice: moveChoice);
    }
  }

  String _showMessaageByScore(int score) {
    if (score < 3 && score > 1) {
      return 'Nice Play! $score runs';
    } else if (score == 4) {
      return 'What a shot! $score runs';
    } else if (score == 5) {
      return 'Great Shot! $score runs';
    } else if (score == 6) {
      return "It's a six!";
    } else if (score == 1) {
      return 'Nice Play! $score run';
    } else {
      return 'No runs scored';
    }
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

  PracticeGameStarted({
    this.phase = GamePhase.toss,
    required this.player,
    required this.computer,
    required this.isBattingFirst,
    this.message = '',
    this.mainTimer = 0,
    this.moveChoice = 0,
  });

  PracticeGameStarted copyWith({
    GamePhase? phase,
    Player? player,
    Player? computer,
    bool? isBattingFirst,
    String? message,
    int? mainTimer,
    int? moveChoice,
  }) {
    return PracticeGameStarted(
      phase: phase ?? this.phase,
      player: player ?? this.player,
      computer: computer ?? this.computer,
      isBattingFirst: isBattingFirst ?? this.isBattingFirst,
      message: message ?? this.message,
      mainTimer: mainTimer ?? this.mainTimer,
      moveChoice: moveChoice ?? this.moveChoice,
    );
  }
}


class PracticeGameErorr extends PracticeGameState {
  final String error;

  PracticeGameErorr(this.error);

  @override
  String toString() => 'PracticeGameErorr: $error';
}

enum GamePhase { toss, innings1, innings2, result }
