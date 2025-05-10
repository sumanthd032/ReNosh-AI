import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:renosh_app/screens/auth_screen/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to sign out: $e',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFF9F7F3),
            ),
          ),
          backgroundColor: const Color(0xFFFF4A4A),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    }
  }

  Future<void> _editProfile(
    BuildContext context,
    String currentName,
    String currentEstablishment,
  ) async {
    final nameController = TextEditingController(text: currentName);
    final establishmentController = TextEditingController(
      text: currentEstablishment,
    );
    String? error;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Edit Profile',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: GoogleFonts.inter(color: const Color(0xFFF9F7F3)),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: GoogleFonts.inter(
                      color: const Color(0xFFB0B0B0),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A3C34).withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: const Color(0xFF39FF14).withOpacity(0.2),
                      ),
                    ),
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: establishmentController,
                  style: GoogleFonts.inter(color: const Color(0xFFF9F7F3)),
                  decoration: InputDecoration(
                    labelText: 'Establishment Name',
                    labelStyle: GoogleFonts.inter(
                      color: const Color(0xFFB0B0B0),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A3C34).withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: const Color(0xFF39FF14).withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: const Color(0xFFB0B0B0)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    setState(() => error = 'Name cannot be empty');
                    return;
                  }
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .set({
                          'name': name,
                          'establishmentName':
                              establishmentController.text.trim(),
                          'email': FirebaseAuth.instance.currentUser?.email,
                        }, SetOptions(merge: true));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Profile updated successfully',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF1A3C34),
                          ),
                        ),
                        backgroundColor: const Color(0xFF39FF14),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to update profile: $e',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFF9F7F3),
                          ),
                        ),
                        backgroundColor: const Color(0xFFFF4A4A),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: Text(
                  'Save',
                  style: GoogleFonts.inter(color: const Color(0xFF39FF14)),
                ),
              ),
            ],
          ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            content: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFB0B0B0),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(color: const Color(0xFF39FF14)),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 600),
                    childAnimationBuilder:
                        (widget) => FadeTransition(
                          opacity: _fadeAnimation,
                          child: widget,
                        ),
                    children: [
                      // Header
                      Text(
                        'Profile',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFF9F7F3),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your account and preferences',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFB0B0B0),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // User Info Card
                      StreamBuilder<DocumentSnapshot>(
                        stream:
                            user != null
                                ? FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .snapshots()
                                : null,
                        builder: (context, snapshot) {
                          String name = 'User';
                          String email = 'email@example.com';
                          String establishment = 'Your Establishment';

                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            name = data['name'] ?? 'User';
                            email =
                                data['email'] ??
                                user?.email ??
                                'email@example.com';
                            establishment =
                                data['establishmentName'] ??
                                'Your Establishment';
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D2D).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFF39FF14,
                                  ).withOpacity(0.05),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFF39FF14).withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: const Color(
                                    0xFF39FF14,
                                  ).withOpacity(0.3),
                                  child: const Icon(
                                    Icons.person,
                                    size: 36,
                                    color: Color(0xFFF9F7F3),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFF9F7F3),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        email,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFFB0B0B0),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        establishment,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFFB0B0B0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Settings Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: const Color(0xFF39FF14).withOpacity(0.05),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF39FF14).withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF9F7F3),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Edit Profile',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFF9F7F3),
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF39FF14),
                                size: 16,
                              ),
                              onTap: () {
                                final snapshot =
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(
                                          FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid,
                                        )
                                        .get();
                                snapshot.then((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>?;
                                  _editProfile(
                                    context,
                                    data?['name'] ?? 'User',
                                    data?['establishmentName'] ??
                                        'Your Establishment',
                                  );
                                });
                              },
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Notifications',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFF9F7F3),
                                ),
                              ),
                              trailing: Switch(
                                value: _notificationsEnabled,
                                activeColor: const Color(0xFF39FF14),
                                onChanged: (value) {
                                  setState(() => _notificationsEnabled = value);
                                  // Placeholder for notification logic
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // About Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: const Color(0xFF39FF14).withOpacity(0.05),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF39FF14).withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About Renosh',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF9F7F3),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Renosh helps establishments manage surplus food by facilitating donations to those in need. Version 1.0.0.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFFB0B0B0),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Terms of Service',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFF9F7F3),
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF39FF14),
                                size: 16,
                              ),
                              onTap:
                                  () => _showInfoDialog(
                                    context,
                                    'Terms of Service',
                                    'By using Renosh, you agree to our terms, which ensure fair use and protect user data. Contact support for details.',
                                  ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Privacy Policy',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFF9F7F3),
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF39FF14),
                                size: 16,
                              ),
                              onTap:
                                  () => _showInfoDialog(
                                    context,
                                    'Privacy Policy',
                                    'We value your privacy. Your data is securely stored and only used to improve your experience with Renosh.',
                                  ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Contact Support',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFF9F7F3),
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF39FF14),
                                size: 16,
                              ),
                              onTap:
                                  () => _showInfoDialog(
                                    context,
                                    'Contact Support',
                                    'Email: sumanth@gmail.com\nPhone: +91-7019938475\nWe’re here to help with any issues!',
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sign Out Button
                      Center(
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Color(0xFF39FF14),
                                )
                                : GestureDetector(
                                  onTap: () => _signOut(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF4A4A,
                                      ).withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Sign Out',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFF9F7F3),
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
