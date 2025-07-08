import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/core/contstants/app_constants.dart';
import 'package:lottie/lottie.dart';

class GameWaitingScreen extends StatefulWidget {
  const GameWaitingScreen({super.key});

  @override
  State<GameWaitingScreen> createState() => _GameWaitingScreenState();
}

class _GameWaitingScreenState extends State<GameWaitingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: SvgPicture.asset(
              'assets/images/waiting-bg.svg',
              fit: BoxFit.fill,
            ),
          ),

          // Top-left player
          Positioned(
            top: 100,
            left: 50,
            child: _buildPlayerCard('Harsh', AppConstants.avatarUrl),
          ),

          // Bottom-right player
          Positioned(
            bottom: 100,
            right: 50,
            child: _buildPlayerCard(
              'Villian',
              AppConstants.computerAvatarUrl,
              isWaiting: true,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                //
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(
    String name,
    String avatarUrl, {
    bool isWaiting = false,
  }) {
    final avatarSize = MediaQuery.of(context).size.width * 0.3;
    final animSize = MediaQuery.of(context).size.width * 0.4;

    if (isWaiting) {
      return LottieBuilder.asset(
        'assets/animation/searching_player_anim.json',
        width: animSize,
        height: animSize,
        fit: BoxFit.contain,
        repeat: true,
        delegates: LottieDelegates(
          
        ),

      );
    }
    return Column(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          padding: EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(child: Image.network(avatarUrl, fit: BoxFit.contain)),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: avatarSize + 20,
          child: Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
