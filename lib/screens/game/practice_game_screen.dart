import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/app/providers.dart';
import 'package:hand_cricket/controllers/practice_game_controller.dart';
import 'package:hand_cricket/core/theme/app_theme.dart';
import 'package:hand_cricket/models/player.dart';
import 'package:hand_cricket/widgets/game_background.dart';
import 'package:lottie/lottie.dart';

class PracticeGameScreen extends ConsumerStatefulWidget {
  const PracticeGameScreen({super.key});

  @override
  ConsumerState<PracticeGameScreen> createState() => _PracticeGameScreenState();
}

class _PracticeGameScreenState extends ConsumerState<PracticeGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(practiceGameController.notifier).startGame();
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

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: SafeArea(
        child: Consumer(
          builder: (context, ref, widget) {
            final state = ref.watch(practiceGameController);

            // Listen for move status changes to trigger animation
            ref.listen<PracticeGameState>(practiceGameController, (
              previous,
              current,
            ) {
              if (current is PracticeGameStarted &&
                  current.moveStatus == MoveStatus.progress) {
                _playAnimation();
              }
            });

            if (state is PracticeGameStarted) {
              return Column(
                children: [
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: _buildPlayerCard(state.player),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildPlayerCard(state.computer),
                    ),
                  ),

                  if (state.phase == GamePhase.toss) ...[
                    _buildStartInnigsLayout(
                      state.isBattingFirst,
                      state.mainTimer,
                      state.phase,
                    ),
                  ] else if (state.phase == GamePhase.result) ...[
                    _buildResultLayout(state),
                  ] else ...[
                    const Spacer(),
                    _buildHandGestures(
                      state.moveChoice,
                      state.computerChoice,
                      state.moveStatus,
                    ),
                    const Spacer(),
                    _buildTimerAndMessage(state),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildMovesController(state),
                    ),
                  ],
                ],
              );
            } else if (state is PracticeGameError) {
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
                        ref.read(practiceGameController.notifier).resetGame();
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
    );
  }

  Widget _buildStartInnigsLayout(
    bool isBattingFirst,
    int timer,
    GamePhase phase,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(
              height: 300,
              width: 300,
              child: Lottie.asset(
                'assets/animation/bat_anim.json',
                width: 120,
                height: 120,
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),
            Text(
              isBattingFirst
                  ? 'You\'re batting first'
                  : 'You\'re bowling first',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Timer - Now properly shows the countdown
            Text(
              timer.toString(),
              style: GoogleFonts.montserrat(
                fontSize: 54,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultLayout(PracticeGameStarted state) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              state.player.score > state.computer.score
                  ? Icons.emoji_events
                  : state.computer.score > state.player.score
                  ? Icons.sentiment_dissatisfied
                  : Icons.handshake,
              size: 80,
              color:
                  state.player.score > state.computer.score
                      ? Colors.yellow
                      : Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              state.message,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'Your Score',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.player.score.toString(),
                      style: GoogleFonts.montserrat(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Computer Score',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.computer.score.toString(),
                      style: GoogleFonts.montserrat(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ref.read(practiceGameController.notifier).resetGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                'Play Again',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandGestures(int move, int opponentMove, MoveStatus moveStatus) {
    final handWidth = MediaQuery.of(context).size.width * 0.4;

    // Show default closed fist (0) when no move is selected or during next phase
    final playerMove =
        (moveStatus == MoveStatus.progress && move > 0) ? move : 0;
    final computerMove =
        (moveStatus == MoveStatus.progress && opponentMove > 0)
            ? opponentMove
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
                    'assets/hand_gestures/${computerMove}_right.png',
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

  Widget _buildTimerAndMessage(PracticeGameStarted state) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 4,
              width: MediaQuery.of(context).size.width * 0.35,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withAlpha(10),
                    Colors.white.withAlpha(100),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: state.mainTimer > 0 ? state.mainTimer / 4.0 : 0,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.grey.withAlpha(100),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      state.mainTimer.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 4,
              width: MediaQuery.of(context).size.width * 0.35,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withAlpha(100),
                    Colors.white.withAlpha(10),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              state.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(Player player) {
    return Column(
      crossAxisAlignment:
          player.type == PlayerType.player1
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  player.type == PlayerType.player1
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
              children: [
                if (player.type == PlayerType.player1) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.network(
                        player.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.2,
                          child: Text(
                            player.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              player.isBatting
                                  ? 'assets/images/cricket-bat.png'
                                  : 'assets/images/ball.png',
                              width: 14,
                              height: 14,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  player.isBatting
                                      ? Icons.sports_cricket
                                      : Icons.sports_baseball,
                                  size: 14,
                                  color: AppTheme.primaryColor,
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            Text(
                              player.isBatting ? 'Batting' : 'Bowling',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.blueColor.withAlpha(200),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        player.score.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.redColor.withAlpha(200),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        player.score.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.2,
                          child: Text(
                            player.name,
                            maxLines: 1,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              player.isBatting
                                  ? 'assets/images/cricket-bat.png'
                                  : 'assets/images/ball.png',
                              width: 14,
                              height: 14,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  player.isBatting
                                      ? Icons.sports_cricket
                                      : Icons.sports_baseball,
                                  size: 14,
                                  color:
                                      player.isBatting
                                          ? AppTheme.redColor
                                          : AppTheme.primaryColor,
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            Text(
                              player.isBatting ? 'Batting' : 'Bowling',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color:
                                    player.isBatting
                                        ? AppTheme.redColor
                                        : AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.network(
                        player.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey,
                            child: Icon(Icons.computer, color: Colors.white),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // balls indicator
        const SizedBox(height: 8),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color:
                        index < player.ballsFaced
                            ? Colors.blueGrey.withAlpha(150)
                            : AppTheme.redColor.withAlpha(200),
                    border: Border.all(color: Colors.white, width: 1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMovesController(PracticeGameStarted state) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.25,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          final moveNumber = index + 1;
          final isSelected = state.moveChoice == moveNumber;
          final isDisabled = state.moveStatus == MoveStatus.progress;

          return GestureDetector(
            onTap:
                isDisabled
                    ? null
                    : () {
                      ref
                          .read(practiceGameController.notifier)
                          .chooseMove(moveNumber);
                    },
            child: Container(
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.yellow
                        : isDisabled
                        ? Colors.grey.withAlpha(100)
                        : Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(200),
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  moveNumber.toString(),
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color:
                        isSelected
                            ? Colors.black87
                            : isDisabled
                            ? Colors.grey
                            : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
