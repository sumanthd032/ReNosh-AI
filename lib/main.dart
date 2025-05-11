import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:renosh_app/firebase_options.dart';
import 'package:renosh_app/screens/auth_screen/login_screen.dart';
import 'package:renosh_app/screens/main_screen_establishment.dart';
import 'package:renosh_app/screens/main_screen_acceptor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _buildHomeScreen(User? user) {
    if (user == null) {
      debugPrint('No authenticated user. Showing LoginScreen.');
      return const LoginScreen();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('Waiting for user document for UID: ${user.uid}');
          return const Scaffold(
            backgroundColor: Color(0xFF1A3C34),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF39FF14)),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error fetching user document: ${snapshot.error}');
          FirebaseAuth.instance.signOut(); // Sign out on error
          return const LoginScreenWithError(
            error: 'Failed to load user data. Please try again.',
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          debugPrint(
            'User document not found for UID: ${user.uid}. Signing out.',
          );
          FirebaseAuth.instance.signOut();
          return const LoginScreenWithError(
            error: 'User profile not found. Please sign up or log in again.',
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          debugPrint(
            'User document is empty for UID: ${user.uid}. Signing out.',
          );
          FirebaseAuth.instance.signOut();
          return const LoginScreenWithError(
            error: 'User profile data is empty. Please sign up again.',
          );
        }

        final role = data['role'] as String?;
        debugPrint(
          'User role: ${role ?? 'none'} for UID: ${user.uid}, email: ${user.email}',
        );
        if (role == null ||
            !['Food Establishment', 'Acceptor'].contains(role)) {
          debugPrint('Invalid or missing role: $role. Signing out.');
          FirebaseAuth.instance.signOut();
          return const LoginScreenWithError(
            error: 'Invalid role. Please contact support.',
          );
        }

        if (role == 'Food Establishment') {
          debugPrint('Routing to MainScreenEstablishment for UID: ${user.uid}');
          return const MainScreenEstablishment();
        } else {
          debugPrint(
            'Acceptor role detected. Routing to MainScreenAcceptor for UID: ${user.uid}',
          );
          return const MainScreenAcceptor();
        }
      },
    );
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF3A3A3A),
          labelStyle: GoogleFonts.inter(
            color: const Color(0xFFB0B0B0),
            fontSize: 14,
          ),
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFFB0B0B0),
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF39FF14), width: 2),
          ),
          errorStyle: GoogleFonts.inter(
            fontSize: 12,
            color: Color(0xFFFF4A4A),
            height: 1.2,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF2D2D2D),
          contentTextStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFFF9F7F3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('Waiting for auth state');
            return const Scaffold(
              backgroundColor: Color(0xFF1A3C34),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF39FF14)),
              ),
            );
          }
          if (snapshot.hasError) {
            debugPrint('Auth state error: ${snapshot.error}');
            return const LoginScreenWithError(
              error: 'Authentication error. Please try again.',
            );
          }
          debugPrint(
            'Auth state received: User ${snapshot.data?.uid ?? 'null'}',
          );
          return _buildHomeScreen(snapshot.data);
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
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            backgroundColor: const Color(0xFFFF4A4A),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
    });
    return const LoginScreen();
  }
}
