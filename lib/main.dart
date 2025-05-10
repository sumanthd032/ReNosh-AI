import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:renosh_app/firebase_options.dart';
import 'package:renosh_app/screens/signup_screen.dart';
import 'package:renosh_app/screens/login_screen.dart';
import 'package:renosh_app/screens/establishment_dashboard.dart';
import 'package:renosh_app/screens/food_track_screen.dart';
import 'package:renosh_app/screens/history_screen.dart';
import 'package:renosh_app/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getHomeScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SignupScreen();
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) return const SignupScreen();
    final role = doc.data()!['role'];
    return role == 'Food Establishment' ? const EstablishmentDashboard() : const Placeholder();
  }

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
            foregroundColor: const Color(0xFF1A3C34),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
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
          errorStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFFF4A4A), height: 1.2),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
      home: FutureBuilder<Widget>(
        future: _getHomeScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF1A3C34),
              body: Center(child: CircularProgressIndicator(color: Color(0xFF39FF14))),
            );
          }
          return snapshot.data ?? const SignupScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/establishment_dashboard': (context) => const EstablishmentDashboard(),
        '/acceptor_dashboard': (context) => const Placeholder(),
        '/food_track': (context) => const FoodTrackScreen(),
        '/history': (context) => const HistoryScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}