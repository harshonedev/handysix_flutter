import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/app/providers.dart';
import 'package:hand_cricket/models/game_room.dart';
import 'package:hand_cricket/providers/game/game_state.dart';
import 'package:hand_cricket/screens/game/game_result_screen.dart';
import 'package:hand_cricket/screens/game/widgets/forfeit_dialog.dart';
import 'package:hand_cricket/screens/game/widgets/hand_gestures_section.dart';
import 'package:hand_cricket/screens/game/widgets/moves_controller.dart';
import 'package:hand_cricket/screens/game/widgets/player_card.dart';
import 'package:hand_cricket/screens/game/widgets/start_innings_layout.dart';
import 'package:hand_cricket/screens/game/widgets/timer_and_message_section.dart';
import 'package:hand_cricket/widgets/game_background.dart';

class PracticeGameScreen extends ConsumerStatefulWidget {
  static const String route = '/game/play/practice';
  const PracticeGameScreen({super.key});

  @override
  ConsumerState<PracticeGameScreen> createState() => _PracticeGameScreenState();
}

class _PracticeGameScreenState extends ConsumerState<PracticeGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(practiceGameProvider.notifier).initializeGame();
    });
  }

  void _playAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canPop {
    final state = ref.read(practiceGameProvider);
    return !(state is GameStarted && state.phase != GamePhase.result);
  }

  Future<void> _handlePopAttempt() async {
    final shouldPop =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => const ForfeitDialog(),
        ) ??
        false;

    if (shouldPop && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !_canPop) {
          await _handlePopAttempt();
        }
      },
      child: GameBackground(
        child: SafeArea(
          child: Consumer(
            builder: (context, ref, widget) {
              final state = ref.watch(practiceGameProvider);

              if (state is GameResult) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go(GameResultScreen.route);
                });
              }

              // Listen for move status changes to trigger animation
              ref.listen<GameState>(practiceGameProvider, (previous, current) {
                if (current is GameStarted &&
                    (current.moveStatus == MoveStatus.progress ||
                        current.moveStatus == MoveStatus.next)) {
                  _playAnimation();
                }
              });

              if (state is GameStarted) {
                return Column(
                  children: [
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: PlayerCard(player: state.opponent),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: PlayerCard(player: state.player),
                      ),
                    ),

                    if (state.phase == GamePhase.toss ||
                        state.phase == GamePhase.startInnigs) ...[
                      StartInningsLayout(
                        message: state.message,
                        timer: state.mainTimer,
                      ),
                    ] else ...[
                      const Spacer(),
                      HandGesturesSection(
                        animationController: _controller,
                        move: state.moveChoice,
                        opponentMove: state.opponentChoice,
                        moveStatus: state.moveStatus,
                      ),
                      const Spacer(),
                      TimerAndMessageSection(
                        message: state.message,
                        mainTimer: state.mainTimer,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MovesController(
                          moveChoice: state.moveChoice,
                          moveStatus: state.moveStatus,
                        ),
                      ),
                    ],
                  ],
                );
              } else if (state is GameError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        state.error,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(practiceGameProvider.notifier).resetGame();
                        },
                        child: Text('Try Again'),
                      ),
                    ],
                  ),
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
