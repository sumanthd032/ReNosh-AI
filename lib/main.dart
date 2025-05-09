import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:renosh_app/firebase_options.dart';
import 'package:renosh_app/screens/signup_screen.dart';
import 'package:renosh_app/screens/login_screen.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReNosh',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF39FF14), // Vibrant Lime
          onPrimary: Color(0xFF1A3C34), // Deep Forest
          secondary: Color(0xFFF9F7F3), // Soft Cream
          onSecondary: Color(0xFF2D2D2D), // Charcoal Gray
          error: Color(0xFFFF4A4A), // Coral Red
          onError: Color(0xFFF9F7F3), // Soft Cream
          background: Color(0xFF1A3C34), // Deep Forest
          onBackground: Color(0xFFF9F7F3), // Soft Cream
          surface: Color(0xFF2D2D2D), // Charcoal Gray
          onSurface: Color(0xFFF9F7F3), // Soft Cream
        ),
        scaffoldBackgroundColor: const Color(0xFF1A3C34), // Deep Forest
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: const Color(0xFFF9F7F3), // Soft Cream
          displayColor: const Color(0xFFF9F7F3), // Soft Cream
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF39FF14), // Vibrant Lime
            foregroundColor: const Color(0xFF1A3C34), // Deep Forest
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D2D2D), // Charcoal Gray
          labelStyle: GoogleFonts.inter(
            color: const Color(0xFFB0B0B0), // Gray
            fontSize: 14,
          ),
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFFB0B0B0), // Gray
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF39FF14), // Vibrant Lime
              width: 2,
            ),
          ),
        ),
      ),
      home: const SignupScreen(),
      routes: {
        '/login': (context) => const LoginScreen(), // Updated to LoginScreen
        '/signup': (context) => const SignupScreen(), // Added for completeness
        '/dashboard': (context) => const Placeholder(), // Replace with Dashboard
      },
    );
  }
}