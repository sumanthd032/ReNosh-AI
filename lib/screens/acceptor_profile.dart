import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:renosh_app/screens/auth_screen/login_screen.dart';

class AcceptorProfile extends StatefulWidget {
  const AcceptorProfile({super.key});

  @override
  _AcceptorProfileState createState() => _AcceptorProfileState();
}

class _AcceptorProfileState extends State<AcceptorProfile> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    if (_isLoading) return; // Debounce
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
            style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Theme.of(context).colorScheme.background.withOpacity(0.95),
                  Theme.of(context).colorScheme.surface.withOpacity(0.85),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: MediaQuery.of(context).padding.top + 16,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acceptor Profile',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your acceptor account',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFB0B0B0),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (user == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Please log in to view your profile.',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                    )
                  else
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                      builder: (context, snapshot) {
                        String name = 'Acceptor';
                        String email = 'email@example.com';
                        String organization = 'Your Organization';

                        if (snapshot.hasError) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Failed to load profile. Tap to retry.',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.onBackground,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.refresh,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () => (context as Element).markNeedsBuild(),
                                ),
                              ],
                            ),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF39FF14),
                            ),
                          );
                        }
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          name = data['name'] ?? 'Acceptor';
                          email = data['email'] ?? user.email ?? 'email@example.com';
                          organization = data['organization'] ?? 'Your Organization';
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                child: Icon(
                                  Icons.person,
                                  size: 36,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.onBackground,
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
                                      organization,
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
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              _signOut(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        shadowColor: Theme.of(context).colorScheme.error.withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFFF9F7F3),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Sign Out',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}