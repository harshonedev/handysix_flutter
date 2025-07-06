import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hand_cricket/app/providers.dart';
import 'package:hand_cricket/core/routes/app_router.dart';
import 'package:hand_cricket/core/theme/app_theme.dart';
import 'package:hand_cricket/providers/auth_provider.dart';
import 'package:hand_cricket/widgets/background.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    // Check if the user is already logged in
    AuthState authState = ref.read(authProvider);
    final hasAuthChange = ref.watch(
      authProvider.select(
        (state) =>
            state is AuthSuccess ||
            state is AuthError ||
            state is Authenticated,
      ),
    );
    if (hasAuthChange) {
      authState = ref.read(authProvider);
    }
    if (authState is Authenticated) {
      // If the user is already authenticated, navigate to the home screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.isAuthenticated = true;
        context.go('/home');
      });
    }
    if (authState is AuthSuccess) {
      // If the user is logged in, navigate to the home screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        //Navigator.pushReplacementNamed(context, '/home');
        final user = (authState as AuthSuccess).user;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome Back, ${user.name ?? 'Guest'}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Set the authentication state to true
        AppRouter.isAuthenticated = true;
        context.go('/home');
      });
    }
    if (authState is AuthError) {
      // If there is an error, show a snackbar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((authState as AuthError).error),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    return Background(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Hero section at the top
            _buildHeroSection(),

            // Add buttons section below hero
            Flexible(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Spacer(),
                      _buildAuthButton(
                        text: 'Continue with Google',
                        iconPath: 'assets/images/google_logo.svg',
                        authType: AuthType.google,
                        onPressed: () {
                          final authNotifier = ref.read(authProvider.notifier);
                          final isLoading =
                              ref.read(authProvider) is AuthLoading;
                          if (!isLoading) {
                            authNotifier.signInWithGoogle();
                          }
                        },
                        color: AppTheme.redColor,
                        isLoading:
                            ref.watch(authProvider) is AuthLoading &&
                            (ref.watch(authProvider) as AuthLoading).authType ==
                                AuthType.google,
                      ),
                      SizedBox(height: 16),
                      _buildAuthButton(
                        text: 'Continue as Guest',
                        iconPath: 'assets/images/guest_icon.svg',
                        authType: AuthType.anonymous,
                        onPressed: () {
                          final authNotifier = ref.read(authProvider.notifier);
                          final isLoading =
                              ref.read(authProvider) is AuthLoading;
                          if (!isLoading) {
                            authNotifier.signInAsGuest();
                          }
                        },
                        color: AppTheme.purpleColor,
                        isLoading:
                            ref.watch(authProvider) is AuthLoading &&
                            (ref.watch(authProvider) as AuthLoading).authType ==
                                AuthType.anonymous,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.blueColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3278C8),
            offset: Offset(0, 8), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: 100,
              fit: BoxFit.fitWidth,
            ),
          ),
          Opacity(
            opacity: 0.4,
            child: Image.asset(
              'assets/images/stadium_hero.png',
              height: 164,
              width: double.maxFinite,
              fit: BoxFit.fill,
            ),
          ),

          SizedBox(height: 48),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              SizedBox(width: 24),
              Expanded(
                child: Text(
                  'A New Way of Playing Cricket',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Image.asset(
                'assets/hand_gestures/2_right.png',
                height: 60,
                fit: BoxFit.fitHeight,
              ),
            ],
          ),
          SizedBox(height: 48),
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
    required AuthType authType,
  }) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child:
            isLoading
                ? Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      iconPath,
                      height: authType == AuthType.anonymous ? 24 : 20,
                      width: authType == AuthType.anonymous ? 24 : 20,
                      colorFilter: ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcATop,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      text,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
