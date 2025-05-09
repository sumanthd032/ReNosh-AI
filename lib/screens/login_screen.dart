import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:email_validator/email_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // Helper function to show SnackBar with consistent styling
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: const Color(0xFFF9F7F3), // Soft Cream
            fontSize: 14,
          ),
        ),
        backgroundColor: const Color(0xFFFF4A4A), // Coral Red
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _submitForm() async {
    // Validate form and show SnackBar for the first error
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      if (!_emailController.text.contains('@') || !EmailValidator.validate(_emailController.text)) {
        _showErrorSnackBar('Enter a valid email address');
      } else if (_passwordController.text.isEmpty) {
        _showErrorSnackBar('Password is required');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sign in with Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Fetch user role from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        _showErrorSnackBar('User data not found. Please sign up.');
        await FirebaseAuth.instance.signOut();
        return;
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors with SnackBar
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Try again later';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during login';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3C34), // Deep Forest
      body: Stack(
        children: [
          // Animated Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A3C34), // Deep Forest
                  const Color(0xFF2D2D2D).withOpacity(0.8), // Charcoal Gray
                ],
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Image.asset(
                          'assets/logo.jpg',
                          width: 160,
                          height: 160,
                          semanticLabel: 'ReNosh Logo',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _animController,
                        child: Text(
                          'Welcome Back',
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF9F7F3), // Soft Cream
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            'Log in to continue your journey',
                            textStyle: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFFB0B0B0), // Gray
                            ),
                            textAlign: TextAlign.center,
                            speed: const Duration(milliseconds: 50),
                          ),
                        ],
                        totalRepeatCount: 1,
                      ),
                      const SizedBox(height: 32),
                      // Glassmorphism Form Card
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D).withOpacity(0.85), // Charcoal Gray
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFF9F7F3).withOpacity(0.1), // Soft Cream
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: const Color(0xFFF9F7F3), // Soft Cream
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    labelStyle: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFFB0B0B0), // Gray
                                    ),
                                    hintText: 'e.g., user@example.com',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFFB0B0B0),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.email,
                                      color: Color(0xFF39FF14), // Vibrant Lime
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF2D2D2D), // Charcoal Gray
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
                                  validator: (value) {
                                    if (value == null || !EmailValidator.validate(value)) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: const Color(0xFFF9F7F3), // Soft Cream
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFFB0B0B0), // Gray
                                    ),
                                    hintText: 'Enter your password',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFFB0B0B0),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock,
                                      color: Color(0xFF39FF14), // Vibrant Lime
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: const Color(0xFFB0B0B0), // Gray
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF2D2D2D), // Charcoal Gray
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
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submitForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF39FF14), // Vibrant Lime
                                      foregroundColor: const Color(0xFF1A3C34), // Deep Forest
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      splashFactory: InkRipple.splashFactory,
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Color(0xFF1A3C34), // Deep Forest
                                          )
                                        : Text(
                                            'Log In',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text.rich(
                        TextSpan(
                          text: 'Don’t have an account? ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFFB0B0B0), // Gray
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign Up',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF39FF14), // Vibrant Lime
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Navigator.pushNamed(context, '/signup'),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF39FF14)), // Vibrant Lime
              ),
            ),
        ],
      ),
    );
  }
}