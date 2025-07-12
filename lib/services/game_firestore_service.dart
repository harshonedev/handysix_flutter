import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hand_cricket/models/game_room.dart';
import 'package:logger/logger.dart';

class GameFirestoreService {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();
  GameFirestoreService({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final String collection = 'games';
  final StreamController<GameRoom> _roomStreamController =
      StreamController.broadcast();
  Stream<GameRoom> get roomStream => _roomStreamController.stream;

  Future<GameRoom> createGameRoom(GameRoom gameRoom) async {
    try {
      final data = gameRoom.toJson();
      final docRef = await _firestore.collection(collection).add(data);
      data['id'] = docRef.id;
      _logger.i('Game room data while createGameRoom - $data');
      return GameRoom.fromJson(data);
    } catch (e) {
      _logger.e("Error while createGameRoom - $e");
      throw Exception('Error - $e');
    }
  }

  Future<GameRoom?> checkAvailableGameRoom() async {
    try {
      final snapShot =
          await _firestore
              .collection(collection)
              .where('status', isEqualTo: GameStatus.waiting.name)
              .get();
      if (snapShot.docs.isEmpty) return null;
      final data = snapShot.docs.first.data();
      _logger.i('Game room snapshot data - $data');
      data['id'] = snapShot.docs.first.id;
      return GameRoom.fromJson(data);
    } catch (e) {
      _logger.e('Error while checkAvailableGameRoom - $e');
      throw Exception('Error - $e');
    }
  }

  Future<void> joinGameRoom(GameRoom gameRoom) async {
    try {
      final data = gameRoom.toJson();
      data.remove('id');
      await _firestore.collection(collection).doc(gameRoom.id).set(data);
    } catch (e) {
      _logger.e('Error while joinGameRoom - $e');
      throw Exception('Error - $e');
    }
  }

  void listeningGameRoom(String id) async {
    try {
      _firestore.collection(collection).doc(id).snapshots().listen((docSnap) {
        final data = docSnap.data();
        if (data == null || data.isEmpty) {
          return;
        }
        data['id'] = id;
        final room = GameRoom.fromJson(data);
        _roomStreamController.add(room);
      });
    } catch (e) {
      _logger.e('Errro while listeningGameRoom - $e');
      throw Exception('Error - $e');
    }
  }

  Future<void> updateGameRoom(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(id).update(data);
    } catch (e) {
      _logger.e('Error while updateGameRoom - $e');
      throw Exception('Error - $e');
    }
  }

  void dispose() {
    _roomStreamController.close();
    roomStream.drain();
  }
}
