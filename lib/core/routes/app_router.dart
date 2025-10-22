import 'package:go_router/go_router.dart';
import 'package:hand_cricket/screens/auth/auth_screen.dart';
import 'package:hand_cricket/screens/game/screens/game_result_screen.dart';
import 'package:hand_cricket/screens/game/screens/game_waiting_screen.dart';
import 'package:hand_cricket/screens/game/screens/online_game_screen.dart';
import 'package:hand_cricket/screens/game/screens/practice_game_screen.dart';
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
        builder: (context, state) {
          return PracticeGameScreen();
        },
      ), // Placeholder for practice game screen
      GoRoute(
        path: OnlineGameScreen.route,
        builder: (context, state) {
          return OnlineGameScreen();
        },
      ),
      GoRoute(
        path: GameResultScreen.route,
        builder: (context, state) => const GameResultScreen(),
      ),
      GoRoute(
        path: GameWaitingScreen.route,

        builder: (context, state) {
          return GameWaitingScreen();
        },
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
