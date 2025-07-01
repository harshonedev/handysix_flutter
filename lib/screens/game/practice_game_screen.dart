import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hand_cricket/core/contstants/app_constants.dart';
import 'package:hand_cricket/core/theme/app_theme.dart';

class PracticeGameScreen extends ConsumerStatefulWidget {
  const PracticeGameScreen({super.key});

  @override
  ConsumerState<PracticeGameScreen> createState() => _PracticeGameScreenState();
}

class _PracticeGameScreenState extends ConsumerState<PracticeGameScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor1,
      body: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/images/cricket_ground.svg',

              width: MediaQuery.sizeOf(context).width * 0.9,
              colorFilter: ColorFilter.mode(
                AppTheme.backgroundColor1.withOpacity(0.8),
                BlendMode.srcATop,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 40),
                        child: SizedBox(
                          width: MediaQuery.sizeOf(context).width * 0.5,
                          child: LinearProgressIndicator(
                            value: 0.32,
                            borderRadius: BorderRadius.circular(16),
                            backgroundColor: Colors.blue.shade100,
                            color: Colors.blue.shade800,
                            minHeight: 16,
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(AppConstants.avatarUrl),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
