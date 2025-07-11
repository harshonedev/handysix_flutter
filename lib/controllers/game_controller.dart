import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_cricket/services/game_firestore_service.dart';

class GameController extends StateNotifier<GameState> {
  final GameFirestoreService _gameFirestoreService;
  GameController({required GameFirestoreService gameFirestoreService})
    : _gameFirestoreService = gameFirestoreService,
      super(GameInitialize());

  
}



// Game State
abstract class GameState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GameInitialize extends GameState {}
