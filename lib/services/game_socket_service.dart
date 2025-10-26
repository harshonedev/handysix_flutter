import 'dart:async';

import 'package:hand_cricket/models/game_player.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Service for managing Socket.IO connection and game events
class GameSocketService {
  final Logger _logger = Logger();
  IO.Socket? _socket;

  final String serverUrl;
  final String userId;
  final String userName;
  final String? userEmail;

  // Stream controllers for different events
  final _matchmakingStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _gameMatchedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _gameStartCountdownController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _playerMovedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _moveResultController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _inningsEndController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _inningsStartController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _continueInningsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _gameOverController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _gamePausedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _gameResumedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _playerDisconnectedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get matchmakingStatusStream =>
      _matchmakingStatusController.stream;
  Stream<Map<String, dynamic>> get gameMatchedStream =>
      _gameMatchedController.stream;
  Stream<Map<String, dynamic>> get gameStartCountdownStream =>
      _gameStartCountdownController.stream;
  Stream<Map<String, dynamic>> get playerMovedStream =>
      _playerMovedController.stream;
  Stream<Map<String, dynamic>> get moveResultStream =>
      _moveResultController.stream;
  Stream<Map<String, dynamic>> get inningsEndStream =>
      _inningsEndController.stream;
  Stream<Map<String, dynamic>> get inningsStartStream =>
      _inningsStartController.stream;
  Stream<Map<String, dynamic>> get continueInningsStream =>
      _continueInningsController.stream;
  Stream<Map<String, dynamic>> get gameOverStream => _gameOverController.stream;
  Stream<Map<String, dynamic>> get gamePausedStream =>
      _gamePausedController.stream;
  Stream<Map<String, dynamic>> get gameResumedStream =>
      _gameResumedController.stream;
  Stream<Map<String, dynamic>> get playerDisconnectedStream =>
      _playerDisconnectedController.stream;
  Stream<Map<String, dynamic>> get errorStream => _errorController.stream;

  bool get isConnected => _socket?.connected ?? false;

  GameSocketService({
    required this.serverUrl,
    required this.userId,
    required this.userName,
    this.userEmail,
  });

  /// Connect to Socket.IO server
  Future<void> connect() async {
    if (_socket?.connected == true) {
      _logger.i('Socket already connected');
      return;
    }

    try {
      _logger.i('Connecting to Socket.IO server: $serverUrl');

      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setAuth({'uid': userId, 'name': userName, 'email': userEmail})
            .build(),
      );

      _setupEventListeners();

      _socket!.connect();

      _logger.i('Socket.IO connection initiated');
    } catch (e) {
      _logger.e('Failed to connect to Socket.IO server: $e');
      rethrow;
    }
  }

  /// Setup all event listeners
  void _setupEventListeners() {
    _socket!.onConnect((_) {
      _logger.i('Socket connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      _logger.w('Socket disconnected');
    });

    _socket!.onError((error) {
      _logger.e('Socket error: $error');
      _errorController.add({'type': 'connection', 'message': error.toString()});
    });

    // Matchmaking events
    _socket!.on('matchmaking_status', (data) {
      _logger.d('Matchmaking status: $data');
      _matchmakingStatusController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('matchmaking_error', (data) {
      _logger.e('Matchmaking error: $data');
      _errorController.add({'type': 'matchmaking', 'message': data['message']});
    });

    _socket!.on('matchmaking_cancelled', (data) {
      _logger.i('Matchmaking cancelled: $data');
      _matchmakingStatusController.add({
        'status': 'cancelled',
        'message': data['message'],
      });
    });

    // Game events
    _socket!.on('game_matched', (data) {
      _logger.i('Game matched: ${data['gameId']}');
      _gameMatchedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('game_start_countdown', (data) {
      _logger.d('Game start countdown: $data');
      _gameStartCountdownController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('player_moved', (data) {
      _logger.d('Player moved: $data');
      _playerMovedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('move_result', (data) {
      _logger.i('Move result: $data');
      _moveResultController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('innings_end', (data) {
      _logger.i('Innings end: $data');
      _inningsEndController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('innings_start', (data) {
      _logger.i('Innings start: $data');
      _inningsStartController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('continue_innings', (data) {
      _logger.d('Continue innings: $data');
      _continueInningsController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('game_over', (data) {
      _logger.i('Game over: $data');
      _gameOverController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('game_paused', (data) {
      _logger.i('Game paused: $data');
      _gamePausedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('game_resumed', (data) {
      _logger.i('Game resumed: $data');
      _gameResumedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('player_disconnected', (data) {
      _logger.w('Player disconnected: $data');
      _playerDisconnectedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('move_error', (data) {
      _logger.e('Move error: $data');
      _errorController.add({'type': 'move', 'message': data['message']});
    });

    _socket!.on('game_error', (data) {
      _logger.e('Game error: $data');
      _errorController.add({'type': 'game', 'message': data['message']});
    });
  }

  /// Find a game (join matchmaking)
  void findGame() {
    if (!isConnected) {
      _logger.e('Socket not connected');
      return;
    }
    _logger.i('Finding game...');
    _socket!.emit('find_game');
  }

  /// Cancel matchmaking
  void cancelMatchmaking() {
    if (!isConnected) {
      _logger.e('Socket not connected');
      return;
    }
    _logger.i('Cancelling matchmaking...');
    _socket!.emit('cancel_matchmaking');
  }

  /// Submit player move
  void submitMove(String gameId, int move) {
    if (!isConnected) {
      _logger.e('Socket not connected');
      return;
    }
    _logger.i('Submitting move: $move for game: $gameId');
    _socket!.emit('player_move', {'gameId': gameId, 'move': move});
  }

  /// Pause game
  void pauseGame(String gameId) {
    if (!isConnected) {
      _logger.e('Socket not connected');
      return;
    }
    _logger.i('Pausing game: $gameId');
    _socket!.emit('pause_game', {'gameId': gameId});
  }

  /// Resume game
  void resumeGame(String gameId) {
    if (!isConnected) {
      _logger.e('Socket not connected');
      return;
    }
    _logger.i('Resuming game: $gameId');
    _socket!.emit('resume_game', {'gameId': gameId});
  }

  /// Disconnect from server
  void disconnect() {
    _logger.i('Disconnecting from Socket.IO server');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _matchmakingStatusController.close();
    _gameMatchedController.close();
    _gameStartCountdownController.close();
    _playerMovedController.close();
    _moveResultController.close();
    _inningsEndController.close();
    _inningsStartController.close();
    _continueInningsController.close();
    _gameOverController.close();
    _gamePausedController.close();
    _gameResumedController.close();
    _playerDisconnectedController.close();
    _errorController.close();
  }

  /// Helper to parse GamePlayer from JSON
  GamePlayer parsePlayer(Map<String, dynamic> json) {
    return GamePlayer.fromJson(json);
  }
}
