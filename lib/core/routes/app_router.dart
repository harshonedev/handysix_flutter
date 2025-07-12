import 'package:go_router/go_router.dart';
import 'package:hand_cricket/controllers/game_controller.dart';
import 'package:hand_cricket/screens/auth/auth_screen.dart';
import 'package:hand_cricket/screens/game/game_result_screen.dart';
import 'package:hand_cricket/screens/game/game_waiting_screen.dart';
import 'package:hand_cricket/screens/game/game_screen.dart';
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
        path: '${GameScreen.route}/:mode',
        builder: (context, state) {
          final param = state.pathParameters['mode'] ?? GameMode.practice;
          final mode = GameMode.values.firstWhere((e) => param == e);
          return GameScreen(mode: mode);
        },
      ), // Placeholder for practice game screen
      GoRoute(
        path: GameResultScreen.route,
        builder: (context, state) => const GameResultScreen(),
      ),
      GoRoute(
        path: '${GameWaitingScreen.route}/:mode',

        builder: (context, state) {
          final param = state.pathParameters['mode'] ?? GameMode.practice;
          final mode = GameMode.values.firstWhere((e) => param == e);
          return GameWaitingScreen(mode: mode);
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
