import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/core/theme/app_theme.dart';
import 'package:hand_cricket/screens/home/home_screen.dart';

class ForfeitDialog extends StatelessWidget {
  final void Function() onResume;
  final void Function() onForfeit;
  const ForfeitDialog({super.key, required this.onResume, required this.onForfeit});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.exit_to_app, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Text(
            'Forfeit Game?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to quit the game? Your progress will be lost.',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onResume();
            Navigator.of(context).pop(false);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Continue',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onForfeit();
            context.go(HomeScreen.route);
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Forfeit',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
