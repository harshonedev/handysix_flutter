import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/core/theme/app_theme.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/images/cricket_ground.svg',

              width: MediaQuery.sizeOf(context).width * 0.9,
              colorFilter: ColorFilter.mode(
                AppTheme.backgroundColor.withOpacity(0.8),
                BlendMode.srcATop,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SvgPicture.asset(
                    'assets/images/app_logo.svg',
                    height: 80,
                    width: 160,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'A new way of playing cricket',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withAlpha(200),
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 1),

                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.redColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 18,
                      ),
                      child: InkWell(
                        onTap: () {
                          // Handle Google login
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Google login clicked')),
                          );
                        },
                        child: Row(
                          children: [
                            const Spacer(flex: 1),
                            SvgPicture.asset(
                              'assets/images/google_logo.svg',
                              height: 20,
                              width: 20,
                              colorFilter: ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcATop,
                              ),
                            ),
                            const Spacer(flex: 1),
                            Text(
                              'Continue with Google',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(flex: 1),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.blueColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black, width: 3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 18,
                      ),
                      child: InkWell(
                        onTap: () {
                          // Handle guest login
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Guest login clicked')),
                          );
                        },
                        child: Row(
                          children: [
                            const Spacer(flex: 1),
                            SvgPicture.asset(
                              'assets/images/guest_icon.svg',
                              height: 24,
                              width: 24,
                              colorFilter: ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcATop,
                              ),
                            ),
                            const Spacer(flex: 1),
                            Text(
                              'Continue as Guest',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(flex: 1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
