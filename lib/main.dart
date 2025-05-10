import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:renosh_app/firebase_options.dart';
import 'package:renosh_app/screens/auth_screen/login_screen.dart';
import 'package:renosh_app/screens/main_screen_establishment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getHomeScreen(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('Current user: ${user?.uid ?? 'null'}, email: ${user?.email ?? 'null'}');
    if (user == null) {
      debugPrint('No authenticated user. Redirecting to LoginScreen.');
      return const LoginScreen();
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      debugPrint('User document exists: ${doc.exists}, data: ${doc.data()}');
      if (!doc.exists) {
        debugPrint('User document not found. Signing out.');
        await FirebaseAuth.instance.signOut();
        return const LoginScreenWithError(error: 'User profile not found. Please sign up or log in again.');
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('User document is empty. Signing out.');
        await FirebaseAuth.instance.signOut();
        return const LoginScreenWithError(error: 'User profile data is empty. Please sign up again.');
      }

      final role = data['role'] as String?;
      debugPrint('User role: ${role ?? 'none'}');
      if (role == null || !['Food Establishment', 'Acceptor'].contains(role)) {
        debugPrint('Invalid or missing role: $role. Signing out.');
        await FirebaseAuth.instance.signOut();
        return const LoginScreenWithError(error: 'Invalid role. Please contact support.');
      }

      if (role == 'Food Establishment') {
        debugPrint('Routing to MainScreenEstablishment.');
        return const MainScreenEstablishment();
      } else {
        debugPrint('Acceptor role detected. Showing placeholder.');
        return Scaffold(
          backgroundColor: const Color(0xFF1A3C34),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Acceptor role not implemented yet.',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF9F7F3),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    debugPrint('Signing out from Acceptor placeholder.');
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39FF14),
                    foregroundColor: const Color(0xFF1A3C34),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Back to Login',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      await FirebaseAuth.instance.signOut();
      return LoginScreenWithError(error: 'Failed to load user data: ${e.toString().split('] ').last}. Please try again.');
    }
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF3A3A3A),
          labelStyle: GoogleFonts.inter(color: const Color(0xFFB0B0B0), fontSize: 14),
          hintStyle: GoogleFonts.inter(color: const Color(0xFFB0B0B0), fontSize: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF39FF14), width: 2),
          ),
          errorStyle: GoogleFonts.inter(fontSize: 12, color: Color(0xFFFF4A4A), height: 1.2),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF2D2D2D),
          contentTextStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFF9F7F3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      home: FutureBuilder<Widget>(
        future: _getHomeScreen(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF1A3C34),
              body: Center(child: CircularProgressIndicator(color: Color(0xFF39FF14))),
            );
          }
          if (snapshot.hasError) {
            debugPrint('FutureBuilder error: ${snapshot.error}');
            return const LoginScreenWithError(error: 'Error loading app. Please try again.');
          }
          return snapshot.data ?? const LoginScreen();
        },
      ),
    );
  }
}

class LoginScreenWithError extends StatelessWidget {
  final String error;
  const LoginScreenWithError({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error,
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFF9F7F3)),
            ),
            backgroundColor: const Color(0xFFFF4A4A),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
    });
    return const LoginScreen();
  }
}