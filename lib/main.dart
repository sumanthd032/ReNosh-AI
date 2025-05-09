import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:renosh_app/firebase_options.dart';
import 'package:renosh_app/screens/signup_screen.dart';
import 'package:renosh_app/screens/login_screen.dart';

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
          primary: Color(0xFF39FF14),
          onPrimary: Color(0xFF1A3C34),
          secondary: Color(0xFFF9F7F3),
          onSecondary: Color(0xFF2D2D2D),
          error: Color(0xFFFF4A4A),
          onError: Color(0xFFF9F7F3),
          background: Color(0xFF1A3C34),
          onBackground: Color(0xFFF9F7F3),
          surface: Color(0xFF2D2D2D),
          onSurface: Color(0xFFF9F7F3),
        ),
        scaffoldBackgroundColor: const Color(0xFF1A3C34),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: const Color(0xFFF9F7F3),
          displayColor: const Color(0xFFF9F7F3),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF39FF14),
            foregroundColor: Color(0xFF1A3C34),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: kIsWeb ? 18 : 16),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D2D2D),
          labelStyle: GoogleFonts.inter(color: const Color(0xFFB0B0B0), fontSize: 12),
          hintStyle: GoogleFonts.inter(color: const Color(0xFFB0B0B0), fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF39FF14), width: 2),
          ),
          hoverColor: kIsWeb ? const Color(0xFF39FF14).withOpacity(0.1) : null,
          errorStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFFF4A4A), height: 1.2),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
      home: const SignupScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const Placeholder(),
      },
    );
  }
}