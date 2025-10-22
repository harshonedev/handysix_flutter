import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/core/theme/app_theme.dart';
import 'package:hand_cricket/models/game_player.dart';

class PlayerCard extends StatelessWidget {
  final GamePlayer player;
  const PlayerCard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
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
                if (player.type == PlayerType.player2) ...[
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
                  child:
                      index < player.movesPerBall.length
                          ? Center(
                            child:
                                player.getMoveForBall(index + 1) == -1
                                    ? Icon(
                                      Icons.outlet_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    )
                                    : Text(
                                      player
                                          .getMoveForBall(index + 1)
                                          .toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                          )
                          : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
