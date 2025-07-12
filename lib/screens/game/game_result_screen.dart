import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/app/providers.dart';
import 'package:hand_cricket/controllers/game_controller.dart';
import 'package:hand_cricket/core/theme/app_theme.dart';
import 'package:hand_cricket/models/game_player.dart';
import 'package:hand_cricket/screens/game/game_screen.dart';
import 'package:hand_cricket/screens/home/home_screen.dart';
import 'package:hand_cricket/widgets/background.dart';

class GameResultScreen extends StatefulWidget {
  static const String route = '/game/result';
  const GameResultScreen({super.key});

  @override
  State<GameResultScreen> createState() => _GameResultScreenState();
}

class _GameResultScreenState extends State<GameResultScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Background(
        child: Consumer(
          builder: (context, ref, child) {
            final state = ref.read(gameController);
            if (state is GameResult) {
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  ref.read(gameController.notifier).exitGame();
                  context.go(HomeScreen.route);
                },
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildResultCard(state),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  ref
                                      .read(gameController.notifier)
                                      .exitGame();
                                  context.go(HomeScreen.route);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.blueColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Back To Home',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  ref
                                      .read(gameController.notifier)
                                      .exitGame();
                                  context.go(GameScreen.route);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.purpleColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Play Again',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Center(child: Text('Something Went Wrong'));
          },
        ),
      ),
    );
  }

  Widget _buildResultCard(GameResult gameResult) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1565C0), offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          _buildGameMessage(gameResult),
          const SizedBox(height: 40),
          _buildPlayerComparison(gameResult),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGameMessage(GameResult gameResult) {
    final isTie = gameResult.winner == null;
    final isPlayerWinner = gameResult.player1.type == gameResult.winner;
    final playerStatus = _getPlayerStatus(isTie, isPlayerWinner);
    return Column(
      children: [
        Text(
          playerStatus == PlayerStatus.tie
              ? 'It\'s a tie'
              : playerStatus == PlayerStatus.winner
              ? 'You Won'
              : 'You Lost',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          gameResult.message,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPlayerComparison(GameResult gameResult) {
    final isTie = gameResult.winner == null;
    final isPlayerWinner = gameResult.player1.type == gameResult.winner;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPlayerCard(
          gameResult.player1,
          _getPlayerStatus(isTie, isPlayerWinner),
        ),
        _buildPlayerCard(
          gameResult.player2,
          _getPlayerStatus(isTie, !isPlayerWinner),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(GamePlayer player, PlayerStatus status) {
    final config = _getStatusConfig(status);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          width: config.avatarSize,
          height: config.avatarSize,
          decoration: BoxDecoration(
            color: config.color,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.network(player.avatarUrl, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          player.name,
          style: GoogleFonts.poppins(
            fontSize: config.nameFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              player.score.toString(),
              style: GoogleFonts.poppins(
                fontSize: config.runsFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1,
              ),
            ),
            SizedBox(width: status == PlayerStatus.loser ? 2 : 4),
            Text(
              'Runs',
              style: GoogleFonts.poppins(
                fontSize: config.runsTextFontSize,
                color: Colors.black26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  _StatusConfig _getStatusConfig(PlayerStatus status) {
    switch (status) {
      case PlayerStatus.winner:
        return _StatusConfig(
          color: Colors.green.withAlpha(100),
          avatarSize: 100,
          nameFontSize: 14,
          runsFontSize: 32,
          runsTextFontSize: 12,
        );
      case PlayerStatus.loser:
        return _StatusConfig(
          color: Colors.red.withAlpha(100),
          avatarSize: 60,
          nameFontSize: 12,
          runsFontSize: 24,
          runsTextFontSize: 10,
        );
      case PlayerStatus.tie:
        return _StatusConfig(
          color: Colors.orange.withAlpha(100),
          avatarSize: 80,
          nameFontSize: 14,
          runsFontSize: 32,
          runsTextFontSize: 12,
        );
      case PlayerStatus.left:
        return _StatusConfig(
          color: Colors.red.withAlpha(100),
          avatarSize: 60,
          nameFontSize: 12,
          runsFontSize: 24,
          runsTextFontSize: 10,
        );
    }
  }

  PlayerStatus _getPlayerStatus(bool isTie, bool isWinner) {
    if (isTie) return PlayerStatus.tie;
    return isWinner ? PlayerStatus.winner : PlayerStatus.loser;
  }
}

class _StatusConfig {
  final Color color;
  final double avatarSize;
  final double nameFontSize;
  final double runsFontSize;
  final double runsTextFontSize;

  _StatusConfig({
    required this.color,
    required this.avatarSize,
    required this.nameFontSize,
    required this.runsFontSize,
    required this.runsTextFontSize,
  });
}
