import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:email_validator/email_validator.dart';
import 'package:country_code_picker/country_code_picker.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();

  String _selectedRole = 'Food Establishment';
  String? _establishmentType;
  String? _orgType;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  CountryCode _countryCode = CountryCode(code: 'IN', dialCode: '+91');
  String _selectedCountryCode = '+91';

  final Map<String, String> _countryCodes = {
    '+91': 'India (+91)',
    '+1': 'United States (+1)',
    '+44': 'United Kingdom (+44)',
    '+61': 'Australia (+61)',
  };

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _contactController.dispose();
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
      if (_nameController.text.trim().isEmpty) {
        _showErrorSnackBar(_selectedRole == 'Food Establishment'
            ? 'Establishment name is required'
            : 'Organization name is required');
      } else if (_selectedRole == 'Food Establishment' && _establishmentType == null ||
          _selectedRole == 'Food Acceptor' && _orgType == null) {
        _showErrorSnackBar('Please select a type');
      } else if (!_emailController.text.contains('@') || !EmailValidator.validate(_emailController.text)) {
        _showErrorSnackBar('Enter a valid email address');
      } else if (_passwordController.text.length < 8) {
        _showErrorSnackBar('Password must be at least 8 characters');
      } else if (!_passwordController.text.contains(RegExp(r'[0-9]')) ||
          !_passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        _showErrorSnackBar('Password must include a number and special character');
      } else if (_confirmPasswordController.text != _passwordController.text) {
        _showErrorSnackBar('Passwords do not match');
      } else if (_addressController.text.trim().isEmpty) {
        _showErrorSnackBar('Address is required');
      } else if (_contactController.text.trim().isEmpty) {
        _showErrorSnackBar('Contact number is required');
      } else if (!RegExp(r'^\d{10}$').hasMatch(_contactController.text.trim())) {
        _showErrorSnackBar('Enter a valid 10-digit phone number');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final userData = {
        'role': _selectedRole,
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'contact': (kIsWeb ? _selectedCountryCode : _countryCode.dialCode!) + _contactController.text.trim(),
        if (_selectedRole == 'Food Establishment') ...{
          'name': _nameController.text.trim(),
          'type': _establishmentType,
        } else ...{
          'org_name': _nameController.text.trim(),
          'org_type': _orgType,
        },
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password sign-up is disabled';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign-up';
      }
      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double _getPasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    return strength / 4;
  }

  Widget _buildToggle({required bool isWebLayout}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(3, 3),
          ),
          BoxShadow(
            color: const Color(0xFFF9F7F3).withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(-3, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Food Establishment', Icons.restaurant, isWebLayout),
          const SizedBox(width: 8),
          _buildToggleButton('Food Acceptor', Icons.volunteer_activism, isWebLayout),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String role, IconData icon, bool isWebLayout) {
    final isSelected = _selectedRole == role;
    return MouseRegion(
      cursor: isWebLayout ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: () {
          if (!isWebLayout) HapticFeedback.lightImpact();
          setState(() {
            _selectedRole = role;
            _nameController.clear();
            _establishmentType = null;
            _orgType = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: isWebLayout ? 24 : 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF39FF14) : const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF39FF14).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: isWebLayout ? 28 : 24,
                color: isSelected ? const Color(0xFF1A3C34) : const Color(0xFFF9F7F3),
              ),
              SizedBox(width: isWebLayout ? 12 : 8),
              Text(
                role,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: isWebLayout ? 16 : 14,
                  color: isSelected ? const Color(0xFF1A3C34) : const Color(0xFFF9F7F3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          const SizedBox(height: 32),
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
              'Join ReNosh',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFF9F7F3),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                'Empowering sustainable food sharing',
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
          _buildToggle(isWebLayout: false),
          const SizedBox(height: 24),
          _buildFormCard(isWebLayout: false),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              text: 'Already have an account? ',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFB0B0B0)),
              children: [
                TextSpan(
                  text: 'Log In',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF39FF14),
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, '/login'),
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
                    // Features List
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
              'Join ReNosh',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create an account to start sharing',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFB0B0B0),
              ),
            ),
            const SizedBox(height: 24),
          ],
          _buildToggle(isWebLayout: isWebLayout),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _nameController,
            label: _selectedRole == 'Food Establishment' ? 'Establishment Name' : 'Organization Name',
            hint: _selectedRole == 'Food Establishment' ? 'e.g., Green Leaf Restaurant' : 'e.g., Hope NGO',
            icon: Icons.store,
            validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
            isWebLayout: isWebLayout,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedRole == 'Food Establishment' ? _establishmentType : _orgType,
            style: GoogleFonts.inter(fontSize: isWebLayout ? 16 : 14, color: const Color(0xFFF9F7F3)),
            decoration: InputDecoration(
              labelText: _selectedRole == 'Food Establishment' ? 'Establishment Type' : 'Organization Type',
              labelStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB0B0B0)),
              prefixIcon: const Icon(Icons.category, color: Color(0xFF39FF14), size: 20),
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
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
            dropdownColor: const Color(0xFF2D2D2D),
            items: (_selectedRole == 'Food Establishment'
                    ? ['Restaurant', 'Function Hall', 'Paying Guest (PG)', 'Other']
                    : ['NGO', 'Food Bank', 'Community Organization', 'Other'])
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        type,
                        style: GoogleFonts.inter(fontSize: isWebLayout ? 16 : 14, color: const Color(0xFFF9F7F3)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                if (_selectedRole == 'Food Establishment') {
                  _establishmentType = value;
                } else {
                  _orgType = value;
                }
              });
            },
            validator: (value) => value == null ? 'Please select a type' : null,
          ),
          const SizedBox(height: 20),
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
            hint: 'At least 8 characters',
            icon: Icons.lock,
            isPassword: true,
            obscureText: _obscurePassword,
            toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) {
              if (value == null || value.length < 8) return 'Password must be at least 8 characters';
              if (!value.contains(RegExp(r'[0-9]')) || !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
                return 'Include a number and special character';
              return null;
            },
            isWebLayout: isWebLayout,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _getPasswordStrength(_passwordController.text),
            backgroundColor: const Color(0xFF2D2D2D).withOpacity(0.5),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getPasswordStrength(_passwordController.text) < 0.5 ? const Color(0xFFFF4A4A) : const Color(0xFF39FF14),
            ),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter password',
            icon: Icons.lock,
            isPassword: true,
            obscureText: _obscureConfirmPassword,
            toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            validator: (value) => value == null || value != _passwordController.text ? 'Passwords do not match' : null,
            isWebLayout: isWebLayout,
          ),
          const SizedBox(height: 20),
          _buildFormField(
            controller: _addressController,
            label: 'Address',
            hint: 'Enter your address',
            icon: Icons.location_on,
            validator: (value) => value == null || value.trim().isEmpty ? 'Address is required' : null,
            isWebLayout: isWebLayout,
          ),
          const SizedBox(height: 20),
          if (kIsWeb)
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCountryCode,
                    style: GoogleFonts.inter(fontSize: isWebLayout ? 16 : 14, color: const Color(0xFFF9F7F3)),
                    decoration: InputDecoration(
                      labelText: 'Country Code',
                      labelStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB0B0B0)),
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
                      hoverColor: const Color(0xFF39FF14).withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    dropdownColor: const Color(0xFF2D2D2D),
                    items: _countryCodes.entries
                        .map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                style: GoogleFonts.inter(fontSize: isWebLayout ? 16 : 14, color: const Color(0xFFF9F7F3)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedCountryCode = value!),
                    validator: (value) => value == null ? 'Select a country code' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 3,
                  child: _buildFormField(
                    controller: _contactController,
                    label: 'Contact Number',
                    hint: 'e.g., 9876543210',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Contact number is required';
                      if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) return 'Enter a valid 10-digit number';
                      return null;
                    },
                    isWebLayout: isWebLayout,
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormField(
                  controller: _contactController,
                  label: 'Contact Number',
                  hint: 'e.g., 9876543210',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Contact number is required';
                    if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) return 'Enter a valid 10-digit number';
                    return null;
                  },
                  isWebLayout: isWebLayout,
                ),
                Container(
                  child: CountryCodePicker(
                    onChanged: (code) => setState(() => _countryCode = code),
                    initialSelection: 'IN',
                    favorite: ['+91', 'IN'],
                    showCountryOnly: false,
                    alignLeft: false,
                    textStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFF9F7F3)),
                    dialogBackgroundColor: const Color(0xFF2D2D2D),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                ),
              ],
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
                      'Sign Up',
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
                  text: 'Already have an account? ',
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFB0B0B0)),
                  children: [
                    TextSpan(
                      text: 'Log In',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF39FF14),
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, '/login'),
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