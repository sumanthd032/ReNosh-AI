import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:renosh_app/screens/auth_screen/login_screen.dart';

class AcceptorProfile extends StatefulWidget {
  const AcceptorProfile({super.key});

  @override
  State<AcceptorProfile> createState() => _AcceptorProfileState();
}

class _AcceptorProfileState extends State<AcceptorProfile> with SingleTickerProviderStateMixin {
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
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to sign out: ${e.toString().split('] ').last}',
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFF9F7F3)),
          ),
          backgroundColor: const Color(0xFFFF4A4A),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    }
  }

  Future<void> _editProfile(BuildContext context, String currentOrgName, String currentOrgType) async {
    final orgNameController = TextEditingController(text: currentOrgName);
    final orgTypeController = TextEditingController(text: currentOrgType);
    bool hasError = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Edit Profile',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFF9F7F3)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: orgNameController,
                style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFF9F7F3)),
                decoration: InputDecoration(
                  labelText: 'Organization Name',
                  labelStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFB0B0B0)),
                  filled: true,
                  fillColor: const Color(0xFF3A3A3A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF39FF14), width: 2),
                  ),
                  errorText: hasError ? 'Organization name cannot be empty' : null,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: orgTypeController.text.isEmpty ? null : orgTypeController.text,
                style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFF9F7F3)),
                decoration: InputDecoration(
                  labelText: 'Organization Type',
                  labelStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFB0B0B0)),
                  filled: true,
                  fillColor: const Color(0xFF3A3A3A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF39FF14), width: 2),
                  ),
                ),
                dropdownColor: const Color(0xFF3A3A3A),
                items: ['NGO', 'Food Bank', 'Community Organization', 'Other']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  orgTypeController.text = value ?? '';
                },
                validator: (value) => value == null ? 'Please select an organization type' : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFB0B0B0)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final orgName = orgNameController.text.trim();
                if (orgName.isEmpty) {
                  setDialogState(() => hasError = true);
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: const Color(0xFF1A3C34),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .set({
              'org_name': orgNameController.text.trim(),
              'org_type': orgTypeController.text.trim(),
              'email': FirebaseAuth.instance.currentUser!.email,
              'role': 'Acceptor',
            }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1A3C34)),
            ),
            backgroundColor: const Color(0xFF39FF14),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile: ${e.toString().split('] ').last}',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFF9F7F3)),
            ),
            backgroundColor: const Color(0xFFFF4A4A),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
    }

    orgNameController.dispose();
    orgTypeController.dispose();
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFF9F7F3)),
        ),
        content: Text(
          content,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF39FF14)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Stack(
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
          child: RefreshIndicator(
            color: const Color(0xFF39FF14),
            backgroundColor: const Color(0xFF2D2D2D),
            onRefresh: () async {
              debugPrint('Refreshing AcceptorProfile');
              setState(() {});
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    if (user == null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4A4A).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Please log in to view your profile.',
                          style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFF9F7F3)),
                        ),
                      )
                    else
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                        builder: (context, snapshot) {
                          String orgName = 'Organization';
                          String email = 'email@example.com';
                          String orgType = 'Type';

                          if (snapshot.hasError) {
                            debugPrint('Error loading profile: ${snapshot.error}');
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4A4A).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Color(0xFFFF4A4A), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Failed to load profile. Tap to retry.',
                                      style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFF9F7F3)),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: Color(0xFF39FF14)),
                                    onPressed: () => (context as Element).markNeedsBuild(),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)));
                          }
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            orgName = data['org_name'] ?? 'Organization';
                            email = data['email'] ?? user.email ?? 'email@example.com';
                            orgType = data['org_type'] ?? 'Type';
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D2D2D).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
                                    BoxShadow(color: const Color(0xFF39FF14).withOpacity(0.05), blurRadius: 4, spreadRadius: 0),
                                  ],
                                  border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.1)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: const Color(0xFF39FF14).withOpacity(0.3),
                                      child: const Icon(Icons.person, size: 36, color: Color(0xFFF9F7F3)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            orgName,
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
                                            orgType,
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
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D2D2D).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
                                    BoxShadow(color: const Color(0xFF39FF14).withOpacity(0.05), blurRadius: 4, spreadRadius: 0),
                                  ],
                                  border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Settings',
                                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFF9F7F3)),
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        'Edit Profile',
                                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFF9F7F3)),
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF39FF14), size: 16),
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        _editProfile(context, orgName, orgType);
                                      },
                                    ),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        'Notifications',
                                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFF9F7F3)),
                                      ),
                                      trailing: Switch(
                                        value: _notificationsEnabled,
                                        activeColor: const Color(0xFF39FF14),
                                        onChanged: (value) {
                                          HapticFeedback.lightImpact();
                                          setState(() => _notificationsEnabled = value);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2D2D2D).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
                                    BoxShadow(color: const Color(0xFF39FF14).withOpacity(0.05), blurRadius: 4, spreadRadius: 0),
                                  ],
                                  border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'About Renosh',
                                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFF9F7F3)),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Renosh helps establishments manage surplus food by facilitating donations to those in need. Version 1.0.0.',
                                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFFB0B0B0)),
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        'Terms of Service',
                                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFF9F7F3)),
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF39FF14), size: 16),
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        _showInfoDialog(
                                          context,
                                          'Terms of Service',
                                          'By using Renosh, you agree to our terms, which ensure fair use and protect user data. Contact support for details.',
                                        );
                                      },
                                    ),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        'Privacy Policy',
                                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFF9F7F3)),
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF39FF14), size: 16),
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        _showInfoDialog(
                                          context,
                                          'Privacy Policy',
                                          'We value your privacy. Your data is securely stored and only used to improve your experience with Renosh.',
                                        );
                                      },
                                    ),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        'Contact Support',
                                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFF9F7F3)),
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF39FF14), size: 16),
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        _showInfoDialog(
                                          context,
                                          'Contact Support',
                                          'Email: sumanth@gmail.com\nPhone: +91-7019938475\nWe’re here to help with any issues!',
                                        );
                                      },
                                    ),
                                  ],
                                ),
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
                                    backgroundColor: const Color(0xFFFF4A4A),
                                    foregroundColor: const Color(0xFFF9F7F3),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                    shadowColor: const Color(0xFFFF4A4A).withOpacity(0.3),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(color: Color(0xFFF9F7F3), strokeWidth: 2),
                                        )
                                      : Text(
                                          'Sign Out',
                                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}