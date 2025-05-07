import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/app/providers.dart';
import 'package:hand_cricket/core/theme/app_theme.dart';
import 'package:hand_cricket/providers/auth_provider.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if the user is already logged in
    AuthState authState = ref.read(authProvider);
    final hasAuthChange = ref.watch(
      authProvider.select(
        (state) => state is AuthSuccess || state is AuthError,
      ),
    );
    if (hasAuthChange) {
      authState = ref.read(authProvider);
    }
    if (authState is AuthSuccess) {
      // If the user is logged in, navigate to the home screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        //Navigator.pushReplacementNamed(context, '/home');
        final authState = ref.read(authProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User is already logged in ${(authState as AuthSuccess).user.uid}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      });
    }
    if (authState is AuthError) {
      // If there is an error, show a snackbar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((authState as AuthError).error),
            backgroundColor: Colors.red,
          ),
        );
      });
    }

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

          Consumer(
            builder: (context, ref, _) {
              final isLoading = ref.watch(
                authProvider.select((state) => state is AuthLoading),
              );
              final authNotifier = ref.read(authProvider.notifier);
              return SafeArea(
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

                      _buildAuthButton(
                        text: 'Contnue with Google',
                        iconPath: 'assets/images/google_logo.svg',
                        onPressed: () {
                          if (!isLoading) {
                            // Sign in with Google
                            authNotifier.signInWithGoogle();
                          }
                        },
                        color: AppTheme.redColor,
                        isLoading: isLoading,
                      ),
                      SizedBox(height: 16),

                      _buildAuthButton(
                        text: 'Contnue as Guest',
                        iconPath: 'assets/images/guest_icon.svg',
                        onPressed:
                            () =>
                                !isLoading
                                    ? authNotifier.signInAsGuest()
                                    : null,
                        color: AppTheme.blueColor,
                        isLoading: isLoading,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton({
    required String text,
    required String iconPath,
    required VoidCallback onPressed,
    required Color color,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: InkWell(
          onTap: onPressed,
          child:
              isLoading
                  ? Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white.withOpacity(0.8),
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  )
                  : Row(
                    children: [
                      const Spacer(flex: 1),
                      SvgPicture.asset(
                        iconPath,
                        height: 24,
                        width: 24,
                        colorFilter: ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcATop,
                        ),
                      ),
                      //const Spacer(flex: 1),
                      SizedBox(width: 12),
                      Text(
                        text,
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
    );
  }
}
