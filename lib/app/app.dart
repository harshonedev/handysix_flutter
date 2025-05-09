import 'package:flutter/material.dart';
import 'package:hand_cricket/core/routes/app_router.dart';

class HandCricketApp extends StatelessWidget {
  const HandCricketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'HandySix',
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}
