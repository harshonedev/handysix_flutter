import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_cricket/widgets/game_background.dart';

class PracticeGameScreen extends ConsumerStatefulWidget {
  const PracticeGameScreen({super.key});

  @override
  ConsumerState<PracticeGameScreen> createState() => _PracticeGameScreenState();
}

class _PracticeGameScreenState extends ConsumerState<PracticeGameScreen> {
  @override
  Widget build(BuildContext context) {
    return GameBackground(child: SafeArea(child: Column(children: [
          
        ],
      )));
  }
}
