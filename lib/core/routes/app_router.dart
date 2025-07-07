import 'package:go_router/go_router.dart';
import 'package:hand_cricket/screens/auth/auth_screen.dart';
import 'package:hand_cricket/screens/game/game_result_screen.dart';
import 'package:hand_cricket/screens/game/practice_game_screen.dart';
import 'package:hand_cricket/screens/home/home_screen.dart';
import 'package:hand_cricket/screens/home/splash_screen.dart';

class AppRouter {
  static bool isAuthenticated = false;
  static final GoRouter router = GoRouter(
    initialLocation: '/',

    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: HomeScreen.route,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: PracticeGameScreen.route,
        builder: (context, state) => const PracticeGameScreen(),
      ), // Placeholder for practice game screen
      GoRoute(
        path: GameResultScreen.route,
        builder: (context, state) => const GameResultScreen(),
      ),
    ],
    redirect: (context, state) {
      final isAuth = state.matchedLocation == '/auth';
      final isInitital = state.matchedLocation == '/';
      if (!isAuthenticated && !isInitital) {
        return '/auth';
      }

      if (isAuthenticated && isInitital) {
        return '/home';
      }
      if (isAuthenticated && isAuth) {
        return '/home';
      }

      return null;
    },
  );
}
