import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/core/contstants/app_constants.dart';
import 'package:hand_cricket/core/theme/app_theme.dart';
import 'package:hand_cricket/models/player.dart';
import 'package:hand_cricket/widgets/game_background.dart';

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
        child: Column(
          children: [
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildPlayerCard(
                  Player(
                    name: 'Guest',
                    avatarUrl: AppConstants.avatarUrl,
                    type: PlayerType.player1,
                    isBatting: false,
                    ballsFaced: 3,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: _buildPlayerCard(
                  Player(
                    name: 'Computer',
                    avatarUrl: AppConstants.computerAvatarUrl,
                    type: PlayerType.computer,
                    isBatting: true,
                    score: 42,
                  ),
                ),
              ),
            ),
            const Spacer(),
            _buildHandGestures(),
            const Spacer(),
            _buildTimerAndMessage(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildMovesController(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandGestures() {
    final handWidth = MediaQuery.of(context).size.width * 0.4;
    return SizedBox(
      height: 200,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        fit: StackFit.expand,
        children: [
          // LEFT HAND
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
                    'assets/hand_gestures/1_left.png',
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),

          // RIGHT HAND
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
                    'assets/hand_gestures/1_right.png',
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimerAndMessage() {
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
                      value: 0.75, // Example value
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
                      '3',
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
              'What a shot!',
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.network(
                      player.avatarUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
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
                      color:
                          player.type == PlayerType.player1
                              ? AppTheme.blueColor.withAlpha(100)
                              : AppTheme.redColor.withAlpha(100),
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
                      color:
                          player.type == PlayerType.player1
                              ? AppTheme.blueColor.withAlpha(100)
                              : AppTheme.redColor.withAlpha(100),
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
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.network(
                      player.avatarUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // balls set
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
                        6 - player.ballsFaced > index
                            ? AppTheme.redColor.withAlpha(200)
                            : Colors.blueGrey.withAlpha(150),
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

  Widget _buildMovesController() {
    // Placeholder for moves controller
    // 6 buttons 1 to 6 in a grid view 3x2
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
          return GestureDetector(
            onTap: () {
              // Handle move selection
              _playAnimation();
              // You can add logic to handle the selected move here
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                  '${index + 1}',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.black87,
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
