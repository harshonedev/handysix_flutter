import 'package:flutter/material.dart';
import 'package:hand_cricket/providers/game/game_state.dart';

class HandGesturesSection extends StatefulWidget {
  final AnimationController animationController;
  final int move;
  final int opponentMove;
  final MoveStatus moveStatus;
  const HandGesturesSection({
    super.key,
    required this.animationController,
    required this.move,
    required this.opponentMove,
    required this.moveStatus,
  });

  @override
  State<HandGesturesSection> createState() => _HandGesturesSectionState();
}

class _HandGesturesSectionState extends State<HandGesturesSection> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animation = CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final handWidth = MediaQuery.of(context).size.width * 0.4;

    // Show default closed fist (0) when no move is selected or during next phase
    final playerMove =
        (widget.moveStatus != MoveStatus.next && widget.move > 0)
            ? widget.move
            : 0;
    final opponentMove =
        (widget.moveStatus != MoveStatus.next && widget.opponentMove > 0)
            ? widget.opponentMove
            : 0;

    return SizedBox(
      height: 200,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        fit: StackFit.expand,
        children: [
          // LEFT HAND (Player)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final leftOffset = -handWidth * (1 - _animation.value);
              return Positioned(
                left: leftOffset,
                top: 0,
                bottom: 0,
                width: handWidth,
                child: Center(
                  child: Image.asset(
                    'assets/hand_gestures/${playerMove}_left.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey,
                        child: Icon(Icons.error, color: Colors.white),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // RIGHT HAND (Computer)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final rightOffset = -handWidth * (1 - _animation.value);
              return Positioned(
                right: rightOffset,
                top: 0,
                bottom: 0,
                width: handWidth,
                child: Center(
                  child: Image.asset(
                    'assets/hand_gestures/${opponentMove}_right.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey,
                        child: Icon(Icons.error, color: Colors.white),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
