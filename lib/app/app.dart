import 'package:flutter/material.dart';
import 'package:hand_cricket/screens/auth/auth_screen.dart';

class HandCricketApp extends StatelessWidget {
  const HandCricketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HandySix',
      themeMode: ThemeMode.light,
      home: const AuthScreen(),
    );
  }
}
