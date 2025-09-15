import 'package:edentify/features/imagePickerClassify.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔹 Required for Firestore settings
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import '/features/classifyCamera.dart';
import '/features/edema_classifier_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔹 Enable offline persistence for Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const EdentifyApp());
}

class EdentifyApp extends StatelessWidget {
  const EdentifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edentify',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/landing': (context) => LandingScreen(),
        '/sign-in': (context) => SignInScreen(),
        '/login': (context) => LoginScreen(),
        '/classify': (context) => EdemaClassifierScreen(),
        '/classifyCamera': (context) => const ClassifyCamera(),
        '/imagePickerClassify': (context) => const ImagePickerClassify(),
        '/home': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return MainNavigation(userId: args['uid']);
        },
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        } else if (snapshot.hasData && snapshot.data != null) {
          return MainNavigation(userId: snapshot.data!.uid);
        } else {
          return const SplashScreen();
        }
      },
    );
  }
}
