import 'package:flutter/foundation.dart' show kIsWeb;
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
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: const Color(0xFFF9F7F3),
            fontSize: kIsWeb ? 16 : 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFFFF4A4A),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: kIsWeb ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
      ),
    );
  }

  void _submitForm() async {
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
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    Function()? toggleObscure,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool isWebLayout = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: Matrix4.identity()..scale(isWebLayout && controller.text.isNotEmpty ? 1.03 : 1.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [const Color(0xFF2D2D2D), const Color(0xFF1A3C34).withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          fontSize: isWebLayout ? 16 : 14,
          color: const Color(0xFFF9F7F3),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB0B0B0)),
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB0B0B0)),
          prefixIcon: Icon(icon, color: const Color(0xFF39FF14), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFFB0B0B0),
                    size: 20,
                  ),
                  onPressed: toggleObscure,
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF39FF14), width: 2),
          ),
          hoverColor: isWebLayout ? const Color(0xFF39FF14).withOpacity(0.1) : null,
          errorStyle: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFFFF4A4A),
            height: 1.2,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        validator: validator,
        maxLines: 1,
        textAlignVertical: TextAlignVertical.center,
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
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
            opacity: _fadeAnimation,
            child: Text(
              'Welcome Back',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFF9F7F3),
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
                  color: const Color(0xFFB0B0B0),
                ),
                textAlign: TextAlign.center,
                speed: const Duration(milliseconds: 50),
              ),
            ],
            totalRepeatCount: 1,
          ),
          const SizedBox(height: 32),
          _buildFormCard(isWebLayout: false),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              text: 'Don’t have an account? ',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFB0B0B0)),
              children: [
                TextSpan(
                  text: 'Sign Up',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF39FF14),
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, '/signup'),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 900;

    return Row(
      children: [
        if (isWideScreen)
          Expanded(
            flex: 1,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1A3C34).withOpacity(0.95),
                      const Color(0xFF39FF14).withOpacity(0.15),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: screenWidth * 0.2, maxHeight: screenWidth * 0.2),
                      child: Image.asset(
                        'assets/logo.jpg',
                        fit: BoxFit.contain,
                        semanticLabel: 'ReNosh Logo',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'ReNosh',
                          style: GoogleFonts.inter(
                            fontSize: screenWidth > 1200 ? 48 : 40,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFF9F7F3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeatureItem(
                            icon: Icons.share,
                            text: 'Share surplus food with communities',
                            screenWidth: screenWidth,
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(
                            icon: Icons.access_time,
                            text: 'Manage donations in real time',
                            screenWidth: screenWidth,
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem(
                            icon: Icons.dashboard,
                            text: 'Track your impact with insights',
                            screenWidth: screenWidth,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          flex: isWideScreen ? 1 : 2,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? 48 : 24,
              vertical: 40,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF2D2D2D), const Color(0xFF1A3C34).withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(4, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFFF9F7F3).withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(-4, -4),
                    ),
                  ],
                ),
                child: _buildFormCard(isWebLayout: true),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text, required double screenWidth}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: screenWidth > 1200 ? 20 : 18,
              color: const Color(0xFF39FF14),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: screenWidth > 1200 ? 16 : 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFF9F7F3),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({required bool isWebLayout}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWebLayout) ...[
            Text(
              'Welcome Back',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log in to continue your journey',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFB0B0B0),
              ),
            ),
            const SizedBox(height: 24),
          ],
          _buildFormField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'e.g., user@example.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) => value == null || !EmailValidator.validate(value) ? 'Enter a valid email address' : null,
            isWebLayout: isWebLayout,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock,
            isPassword: true,
            obscureText: _obscurePassword,
            toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) => value == null || value.isEmpty ? 'Password is required' : null,
            isWebLayout: isWebLayout,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: const Color(0xFF1A3C34),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                shadowColor: isWebLayout ? const Color(0xFF39FF14).withOpacity(0.3) : Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF1A3C34))
                  : Text(
                      'Log In',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: isWebLayout ? 18 : 16,
                      ),
                    ),
            ),
          ),
          if (isWebLayout) ...[
            const SizedBox(height: 16),
            Center(
              child: Text.rich(
                TextSpan(
                  text: 'Don’t have an account? ',
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFB0B0B0)),
                  children: [
                    TextSpan(
                      text: 'Sign Up',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF39FF14),
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, '/signup'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebLayout = kIsWeb || screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF1A3C34),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  const Color(0xFF1A3C34).withOpacity(0.95),
                  const Color(0xFF2D2D2D).withOpacity(0.85),
                ],
              ),
            ),
          ),
          isWebLayout ? _buildWebLayout() : _buildMobileLayout(),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF39FF14)),
              ),
            ),
        ],
      ),
    );
  }
}