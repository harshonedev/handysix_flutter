import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hand_cricket/app/providers.dart';
import 'package:hand_cricket/core/routes/app_router.dart';
import 'package:hand_cricket/core/theme/app_theme.dart';
import 'package:hand_cricket/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay the getCurrentUser call using Future.microtask to avoid modifying
    // provider state during widget build lifecycle
    Future.microtask(() {
      ref.read(authProvider.notifier).getCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState is Authenticated) {
      // If the user is already authenticated, navigate to the home screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.isAuthenticated = true;
        context.go('/home');
      });
    } else if (authState is Unauthenticated) {
      // If the user is not authenticated, navigate to the auth screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppRouter.isAuthenticated = false;
        context.go('/auth');
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/app_logo.svg',
              height: 120,
              width: 60,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
            ),
          ],
        ),
      ),
    );
  }
}
