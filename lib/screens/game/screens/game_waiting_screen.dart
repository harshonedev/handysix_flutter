import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/app/providers.dart';
import 'package:hand_cricket/core/constants/app_constants.dart';
import 'package:hand_cricket/providers/game/game_state.dart';
import 'package:hand_cricket/screens/game/screens/online_game_screen.dart';
import 'package:hand_cricket/widgets/message_card.dart';
import 'package:lottie/lottie.dart';

class GameWaitingScreen extends ConsumerStatefulWidget {
  static const String route = '/game/waiting';

  const GameWaitingScreen({super.key});

  @override
  ConsumerState<GameWaitingScreen> createState() => _GameWaitingScreenState();
}

class _GameWaitingScreenState extends ConsumerState<GameWaitingScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onlineGameProvider.notifier).initializeGame();
    });

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
    final state = ref.watch(onlineGameProvider);

    if (state is GameWaiting) {
      if (state.status == GameWaitingStatus.started) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(OnlineGameScreen.route);
        });
      }
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
              child: _buildPlayerCard(
                state.player.name,
                state.player.avatarUrl.isNotEmpty
                    ? state.player.avatarUrl
                    : AppConstants.avatarUrl,
              ),
            ),

            // Bottom-right player
            Positioned(
              bottom: 100,
              right: 50,
              child: _buildPlayerCard(
                state.opponent?.name ?? "Opponent",
                state.opponent?.avatarUrl ?? AppConstants.avatarUrl,
                isWaiting: state.status != GameWaitingStatus.matched,
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.status == GameWaitingStatus.matched)
                  Text(
                    state.mainTimer.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (state.message.isNotEmpty)
                  MessageCard(message: state.message, widthPercent: 0.8),
              ],
            ),
          ],
        ),
      );
    }

    return Container();
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
          padding: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.network(
              avatarUrl.isEmpty ? AppConstants.avatarUrl : avatarUrl,
              fit: BoxFit.contain,
            ),
          ),
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
