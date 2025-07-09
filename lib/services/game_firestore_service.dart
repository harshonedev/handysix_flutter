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
  Stream get roomStream => _roomStreamController.stream;

  Future<GameRoom> createGameRoom(GameRoom gameRoom) async {
    try {
      final data = gameRoom.toJson();
      data.remove('id');
      final docRef = await _firestore.collection(collection).add(data);
      data['id'] = docRef.id;
      return GameRoom.fromJson(data);
    } catch (e) {
      _logger.e("Error while createGameRoom - $e");
      rethrow;
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
      data['id'] = snapShot.docs.first.id;
      return GameRoom.fromJson(data);
    } catch (e) {
      _logger.e('Error while checkAvailableGameRoom - $e');
      rethrow;
    }
  }

  Future<void> joinGameRoom(GameRoom gameRoom) async {
    try {
      final data = gameRoom.toJson();
      data.remove('id');
      await _firestore.collection(collection).doc(gameRoom.id).set(data);
    } catch (e) {
      _logger.e('Error while joinGameRoom - $e');
      rethrow;
    }
  }

  void listenGameRoom(String id) async {
    _firestore.collection(collection).doc(id).snapshots().listen((docSnap) {
      final data = docSnap.data();
      if (data == null || data.isEmpty) {
        return;
      }
      data['id'] = id;
      final room = GameRoom.fromJson(data);
      _roomStreamController.add(room);
    });
  }

  Future<void> updateGameRoom(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(id).set(data);
    } catch (e) {
      _logger.e('Error while updateGameRoom - $e');
      rethrow;
    }
  }
}
