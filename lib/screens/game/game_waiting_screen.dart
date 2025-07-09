import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/core/contstants/app_constants.dart';
import 'package:hand_cricket/widgets/message_card.dart';
import 'package:lottie/lottie.dart';

class GameWaitingScreen extends StatefulWidget {
  static const String route = '/game/waiting';
  const GameWaitingScreen({super.key});

  @override
  State<GameWaitingScreen> createState() => _GameWaitingScreenState();
}

class _GameWaitingScreenState extends State<GameWaitingScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
      value: 0,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              isWaiting: false,
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '3',
                style: GoogleFonts.poppins(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              MessageCard(
                message: "Finding suitable match for you...",
                widthPercent: 0.8,
              ),
            ],
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
        controller: _controller,
        onLoaded: (composition) {
          _controller.duration = composition.duration ~/ 2; // 2x speed
          _controller.repeat();
        },
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
