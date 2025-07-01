import 'dart:async';

import 'package:logger/logger.dart';

class TimerService {
  

  final _logger  = Logger();
 
  static const int defaultDuration = 5; // 5 seconds
  static const int defaultMatchStartDelay = 3; // 3 seconds before match starts

  final _timerController = StreamController<int>.broadcast();
  final _timerFinishedController = StreamController<bool>.broadcast();
  Stream<int> get timerStream => _timerController.stream;
  Stream<bool> get timerFinishedStream => _timerFinishedController.stream;

  Timer? _timer;

  Future<void> startTimer({
    int matchStartDelay = defaultMatchStartDelay, // Delay before the match starts
  }) async {
    _timer?.cancel();

    // start timer after a delay of 3 seconds
    await Future.delayed(Duration(seconds: matchStartDelay));
    _timer  = Timer.periodic(Duration(seconds: 1), _onTick);
    _onTick(_timer!); // Initial tick to start the timer immediately
  }

  void _onTick(Timer timer) {
    if (timer.tick >= defaultDuration) {
      timer.cancel();
      // Timer finished, you can add your logic here
      _timerFinishedController.add(true);
      _logger.i('Timer finished');
    } else {
      // Timer is still running, you can update UI or perform actions
      _timerController.add(defaultDuration - timer.tick);
      _logger.i('Timer tick: ${timer.tick}');
    }
  }

  Future<void> startMatchStartTimer({
    int matchStartDelay = defaultMatchStartDelay, // Delay before the match starts
  }) async {
    _timer?.cancel();

    // start match start timer after a delay of 3 seconds
    await Future.delayed(Duration(seconds: matchStartDelay));
    _timer = Timer.periodic(Duration(seconds: 1), _onMatchStartTick);
    _onMatchStartTick(_timer!); // Initial tick to start the timer immediately
  }

  void _onMatchStartTick(Timer timer) {
    if (timer.tick >= defaultMatchStartDelay) {
      timer.cancel();
      // Match start timer finished, you can add your logic here
      _timerFinishedController.add(true);
      _logger.i('Match Start Timer finished');
    } else {
      // Match start timer is still running, you can update UI or perform actions
      _timerController.add(defaultMatchStartDelay - timer.tick);
      _logger.i('Match Start Timer tick: ${timer.tick}');
    }
  }

  void stopTimer() {
    _timer?.cancel();
    _timerController.add(0); // Reset the timer stream
    _logger.i('Timer stopped');
  }

  void stopMatchStartTimer() {
    _timer?.cancel();
    _timerController.add(0); // Reset the match start timer stream
    _logger.i('Match Start Timer stopped');
  }


  void dispose() {
    _timer?.cancel();
    _timerController.close();
    _timerFinishedController.close();
  }
}