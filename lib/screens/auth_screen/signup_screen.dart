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
import 'package:flutter_animate/flutter_animate.dart';
import 'package:renosh_app/screens/auth_screen/login_screen.dart';
import 'package:renosh_app/main.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
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
  late Animation<double> _scaleAnimation;
  CountryCode _countryCode = CountryCode(code: 'IN', dialCode: '+91');

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
            fontSize: 14,
          ),
        ),
        backgroundColor: const Color(0xFFFF4A4A),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _submitForm() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      if (_nameController.text.trim().isEmpty) {
        _showErrorSnackBar(
          _selectedRole == 'Food Establishment'
              ? 'Establishment name is required'
              : 'Organization name is required',
        );
      } else if (_selectedRole == 'Food Establishment' &&
              _establishmentType == null ||
          _selectedRole == 'Food Acceptor' && _orgType == null) {
        _showErrorSnackBar('Please select a type');
      } else if (!EmailValidator.validate(_emailController.text)) {
        _showErrorSnackBar('Enter a valid email address');
      } else if (_passwordController.text.length < 8) {
        _showErrorSnackBar('Password must be at least 8 characters');
      } else if (!_passwordController.text.contains(RegExp(r'[0-9]')) ||
          !_passwordController.text.contains(
            RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
          )) {
        _showErrorSnackBar(
          'Password must include a number and special character',
        );
      } else if (_confirmPasswordController.text != _passwordController.text) {
        _showErrorSnackBar('Passwords do not match');
      } else if (_addressController.text.trim().isEmpty) {
        _showErrorSnackBar('Address is required');
      } else if (!RegExp(
        r'^\d{10}$',
      ).hasMatch(_contactController.text.trim())) {
        _showErrorSnackBar('Enter a valid 10-digit phone number');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final userData = {
        'role':
            _selectedRole == 'Food Establishment'
                ? 'Food Establishment'
                : 'Acceptor',
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'contact': _countryCode.dialCode! + _contactController.text.trim(),
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyApp()),
        );
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
    } catch (e) {
      _showErrorSnackBar('Unexpected error: ${e.toString().split('] ').last}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A3C34).withOpacity(0.9),
            const Color(0xFF2D2D2D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton('Food Establishment', Icons.restaurant),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildToggleButton(
              'Food Acceptor',
              Icons.volunteer_activism,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String role, IconData icon) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 600;
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        if (!kIsWeb) HapticFeedback.lightImpact();
        setState(() {
          _selectedRole = role;
          _nameController.clear();
          _establishmentType = null;
          _orgType = null;
        });
      },
      child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? const Color(0xFF39FF14)
                      : const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(24),
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: const Color(0xFF39FF14).withOpacity(0.5),
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
                  size: 20,
                  color:
                      isSelected
                          ? const Color(0xFF1A3C34)
                          : const Color(0xFFF9F7F3),
                ),
                const SizedBox(width: 4),
                Text(
                  role,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color:
                        isSelected
                            ? const Color(0xFF1A3C34)
                            : const Color(0xFFF9F7F3),
                  ),
                ),
              ],
            ),
          )
          .animate(
            onPlay:
                (controller) =>
                    isWeb
                        ? controller.repeat(reverse: true)
                        : controller.forward(),
          )
          .scale(
            duration: 1000.ms,
            begin: const Offset(1.0, 1.0),
            end:
                isWeb && isSelected
                    ? const Offset(1.05, 1.05)
                    : const Offset(1.0, 1.0),
            curve: Curves.easeInOut,
          ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A3C34).withOpacity(0.9),
            const Color(0xFF2D2D2D).withOpacity(0.8),
          ],
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ReNosh: Share Food, Save Lives',
            style: GoogleFonts.inter(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFF9F7F3),
            ),
          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),
          Text(
            'Join our mission to reduce food waste and support communities by sharing surplus food with those in need.',
            style: GoogleFonts.inter(
              fontSize: 18,
              color: const Color(0xFFB0B0B0),
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildAnimatedIcon(Icons.restaurant, 0),
              const SizedBox(width: 24),
              _buildAnimatedIcon(Icons.favorite, 1),
              const SizedBox(width: 24),
              _buildAnimatedIcon(Icons.eco, 2),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39FF14),
              foregroundColor: const Color(0xFF1A3C34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Learn More',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 400.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData icon, int index) {
    return Icon(icon, size: 40, color: const Color(0xFF39FF14))
        .animate()
        .scale(
          duration: 1000.ms,
          delay: (200 * index).ms,
          curve: Curves.easeInOut,
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
        )
        .then()
        .scale(
          duration: 1000.ms,
          begin: const Offset(1.2, 1.2),
          end: const Offset(0.8, 0.8),
        );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Function(String?)? validator,
    Function(String)? onChanged,
    Widget? prefix,
    int index = 0,
  }) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 600;
    return TextFormField(
          controller: controller,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFFF9F7F3),
          ),
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFB0B0B0),
            ),
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFFB0B0B0),
            ),
            prefixIcon:
                prefixIcon != null
                    ? Icon(prefixIcon, color: const Color(0xFF39FF14))
                    : null,
            prefix: prefix,
            suffixIcon:
                suffixIcon != null
                    ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFFB0B0B0),
                      ),
                      onPressed:
                          () => setState(() {
                            if (labelText == 'Password')
                              _obscurePassword = !_obscurePassword;
                            if (labelText == 'Confirm Password')
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                          }),
                    )
                    : null,
            filled: true,
            fillColor: const Color(0xFF2D2D2D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF39FF14), width: 2),
            ),
            hoverColor: isWeb ? const Color(0xFF39FF14).withOpacity(0.1) : null,
          ),
          // validator: validator,
          onChanged: onChanged,
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: (100 * index).ms)
        .slideY(begin: 0.2);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = kIsWeb && screenWidth > 600;
    final horizontalPadding = isWeb ? screenWidth * 0.05 : 24.0;
    final maxContainerWidth = isWeb ? 500.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFF1A3C34),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A3C34),
                  const Color(0xFF2D2D2D).withOpacity(0.8),
                ],
              ),
            ),
          ),
          if (isWeb)
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.centerLeft,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF39FF14).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 2000.ms),
          isWeb
              ? Row(
                children: [
                  Expanded(child: _buildLeftPanel()),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildFormContent(
                            horizontalPadding,
                            maxContainerWidth,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
              : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildFormContent(
                      horizontalPadding,
                      maxContainerWidth,
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildFormContent(double horizontalPadding, double maxContainerWidth) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 600;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContainerWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: isWeb ? 64 : 48),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  'assets/logo.png',
                  width: isWeb ? 200 : 160,
                  height: isWeb ? 200 : 160,
                  semanticLabel: 'ReNosh Logo',
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _animController,
                child: Text(
                  'Join ReNosh',
                  style: GoogleFonts.inter(
                    fontSize: isWeb ? 48 : 36,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF9F7F3),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Empowering sustainable food sharing',
                    textStyle: GoogleFonts.inter(
                      fontSize: isWeb ? 18 : 16,
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
              _buildToggle()
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2),
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D2D).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFF9F7F3).withOpacity(0.1),
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
                        _buildFormField(
                          controller: _nameController,
                          labelText:
                              _selectedRole == 'Food Establishment'
                                  ? 'Establishment Name'
                                  : 'Organization Name',
                          hintText:
                              _selectedRole == 'Food Establishment'
                                  ? 'e.g., Green Leaf Restaurant'
                                  : 'e.g., Hope NGO',
                          prefixIcon: Icons.store,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'Name is required';
                            return null;
                          },
                          index: 1,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                              value:
                                  _selectedRole == 'Food Establishment'
                                      ? _establishmentType
                                      : _orgType,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: const Color(0xFFF9F7F3),
                              ),
                              decoration: InputDecoration(
                                labelText:
                                    _selectedRole == 'Food Establishment'
                                        ? 'Establishment Type'
                                        : 'Organization Type',
                                labelStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFFB0B0B0),
                                ),
                                prefixIcon: const Icon(
                                  Icons.category,
                                  color: Color(0xFF39FF14),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF2D2D2D),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF39FF14),
                                    width: 2,
                                  ),
                                ),
                                hoverColor:
                                    isWeb
                                        ? const Color(
                                          0xFF39FF14,
                                        ).withOpacity(0.1)
                                        : null,
                              ),
                              dropdownColor: const Color(0xFF2D2D2D),
                              items:
                                  (_selectedRole == 'Food Establishment'
                                          ? [
                                            'Restaurant',
                                            'Function Hall',
                                            'Paying Guest (PG)',
                                            'Other',
                                          ]
                                          : [
                                            'NGO',
                                            'Food Bank',
                                            'Community Organization',
                                            'Other',
                                          ])
                                      .map(
                                        (type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(
                                            type,
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              color: const Color(0xFFF9F7F3),
                                            ),
                                          ),
                                        ),
                                      )
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
                              validator: (value) {
                                if (value == null)
                                  return 'Please select a type';
                                return null;
                              },
                            )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 200.ms)
                            .slideY(begin: 0.2),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          hintText: 'e.g., user@example.com',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null ||
                                !EmailValidator.validate(value))
                              return 'Enter a valid email address';
                            return null;
                          },
                          index: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'At least 8 characters',
                          prefixIcon: Icons.lock,
                          suffixIcon:
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.length < 8)
                              return 'Password must be at least 8 characters';
                            if (!value.contains(RegExp(r'[0-9]')) ||
                                !value.contains(
                                  RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
                                ))
                              return 'Include a number and special character';
                            return null;
                          },
                          onChanged: (value) => setState(() {}),
                          index: 4,
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _getPasswordStrength(_passwordController.text),
                          backgroundColor: const Color(
                            0xFF2D2D2D,
                          ).withOpacity(0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getPasswordStrength(_passwordController.text) < 0.5
                                ? const Color(0xFFFF4A4A)
                                : const Color(0xFF39FF14),
                          ),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ).animate().fadeIn(duration: 600.ms, delay: 500.ms),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          hintText: 'Re-enter password',
                          prefixIcon: Icons.lock,
                          suffixIcon:
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                          obscureText: _obscureConfirmPassword,
                          validator: (value) {
                            if (value == null ||
                                value != _passwordController.text)
                              return 'Passwords do not match';
                            return null;
                          },
                          index: 5,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _addressController,
                          labelText: 'Address',
                          hintText: 'Enter your address',
                          prefixIcon: Icons.location_on,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'Address is required';
                            return null;
                          },
                          index: 6,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: _contactController,
                          labelText: 'Contact Number',
                          hintText: 'e.g., 9876543210',
                          keyboardType: TextInputType.phone,
                          prefix: CountryCodePicker(
                            onChanged:
                                (code) => setState(() => _countryCode = code),
                            initialSelection: 'IN',
                            favorite: ['+91', 'IN'],
                            showCountryOnly: false,
                            alignLeft: false,
                            textStyle: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFFF9F7F3),
                            ),
                            dialogBackgroundColor: const Color(0xFF2D2D2D),
                            dialogTextStyle: GoogleFonts.inter(
                              color: const Color(0xFFF9F7F3),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'Contact number is required';
                            if (!RegExp(r'^\d{10}$').hasMatch(value.trim()))
                              return 'Enter a valid 10-digit number';
                            return null;
                          },
                          index: 7,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF39FF14),
                                  foregroundColor: const Color(0xFF1A3C34),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                child:
                                    _isLoading
                                        ? const CircularProgressIndicator(
                                          color: Color(0xFF1A3C34),
                                        )
                                        : Text(
                                          'Sign Up',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 800.ms)
                            .scale(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFFB0B0B0),
                  ),
                  children: [
                    TextSpan(
                      text: 'Log In',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF39FF14),
                        decoration: TextDecoration.underline,
                      ),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap =
                                () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                ),
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
    );
  }
}
