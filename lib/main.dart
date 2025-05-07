import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hand_cricket/firebase_options.dart';
import 'package:hand_cricket/screens/auth/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);


  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});


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
