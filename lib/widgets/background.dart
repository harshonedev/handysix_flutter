import 'package:flutter/material.dart';
import 'package:hand_cricket/core/theme/app_theme.dart';

class Background extends StatelessWidget {
 final Widget child;
  const Background({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundColor1, AppTheme.backgroundColor2],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 100,
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/images/cricket-ball.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned(
            left: 30,
            bottom: -12,
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/images/cricket-wickets.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned(
            right: -20,
            bottom: 300,
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/images/catching.png',
                width: 140,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
          ),

          child
        ],
      ),
    );
  }
}
