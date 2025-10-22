import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/app/providers.dart';
import 'package:hand_cricket/providers/game/game_state.dart';

class MovesController extends ConsumerWidget {
  final MoveStatus moveStatus;
  final int moveChoice;
  const MovesController({
    super.key,
    required this.moveStatus,
    required this.moveChoice,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          final isSelected = moveChoice == moveNumber;
          final isDisabled =
              moveStatus == MoveStatus.progress ||
              moveStatus == MoveStatus.progressed;

          return GestureDetector(
            onTap:
                isDisabled
                    ? null
                    : () {
                      ref
                          .read(practiceGameProvider.notifier)
                          .chooseMove(moveNumber);
                    },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.yellow : Colors.white,
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
