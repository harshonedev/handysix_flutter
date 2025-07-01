import 'package:flutter/material.dart';

class GameBackground extends StatelessWidget {
  const GameBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Green field
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF239B56), // Bright green
                    Color(0xFF186A3B), // Darker green
                  ],
                ),
              ),
            ),
          ),
          // Sky background with gradient
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF3498DB), // Sky blue
                    Color(0xFF85C1E9), // Deeper blue
                  ],
                ),
              ),
            ),
          ),

          // stadium image
          Align(
            alignment: Alignment.center,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                'assets/images/stadium.png',
                fit: BoxFit.fitHeight,
                width: double.maxFinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
