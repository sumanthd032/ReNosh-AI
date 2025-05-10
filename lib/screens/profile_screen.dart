import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:renosh_app/screens/auth_screen/login_screen.dart';
import 'package:intl/intl.dart';

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
    if (_isLoading) return;
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
              fontSize: 14,
              color: const Color(0xFFF9F7F3),
            ),
          ),
          backgroundColor: const Color(0xFFFF4A4A),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
    bool hasError = false;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
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
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFFF9F7F3),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFFB0B0B0),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF3A3A3A),
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
                          errorText: hasError ? 'Name cannot be empty' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: establishmentController,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFFF9F7F3),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Establishment Name',
                          labelStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFFB0B0B0),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF3A3A3A),
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
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFFB0B0B0),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          setDialogState(() => hasError = true);
                          return;
                        }
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39FF14),
                        foregroundColor: const Color(0xFF1A3C34),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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
              'name': nameController.text.trim(),
              'establishmentName': establishmentController.text.trim(),
              'email': FirebaseAuth.instance.currentUser!.email,
              'role': 'Food Establishment',
            }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1A3C34),
              ),
            ),
            backgroundColor: const Color(0xFF39FF14),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile: $e',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            backgroundColor: const Color(0xFFFF4A4A),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
    }

    nameController.dispose();
    establishmentController.dispose();
  }

  Future<void> _acceptClaim(
    String docId,
    String itemName,
    BuildContext context,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Accept Claim for $itemName',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            content: Text(
              'Accepting this claim will share your name, phone number, and address with the acceptor. Proceed?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFB0B0B0),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFFB0B0B0),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  foregroundColor: const Color(0xFF1A3C34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Accept',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        debugPrint('Attempting to accept claim for donation $docId');
        await FirebaseFirestore.instance
            .collection('donations')
            .doc(docId)
            .update({'claimStatus': 'accepted'});
        debugPrint('Successfully accepted claim for donation $docId');
        setState(() {}); // Force UI refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Accepted claim for $itemName',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1A3C34),
              ),
            ),
            backgroundColor: const Color(0xFF39FF14),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      } catch (e) {
        debugPrint('Error accepting claim for donation $docId: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to accept claim: $e',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            backgroundColor: const Color(0xFFFF4A4A),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
    }
  }

  Future<void> _rejectClaim(
    String docId,
    String itemName,
    BuildContext context,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Reject Claim for $itemName',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            content: Text(
              'Rejecting this claim will make the donation available again. Proceed?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFB0B0B0),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFFB0B0B0),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4A4A),
                  foregroundColor: const Color(0xFFF9F7F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Reject',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        debugPrint('Attempting to reject claim for donation $docId');
        await FirebaseFirestore.instance
            .collection('donations')
            .doc(docId)
            .update({
              'status': 'Available',
              'acceptorId': null,
              'claimedAt': null,
              'claimStatus': 'rejected',
            });
        debugPrint('Successfully rejected claim for donation $docId');
        setState(() {}); // Force UI refresh
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rejected claim for $itemName',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1A3C34),
              ),
            ),
            backgroundColor: const Color(0xFF39FF14),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      } catch (e) {
        debugPrint('Error rejecting claim for donation $docId: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to reject claim: $e',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            backgroundColor: const Color(0xFFFF4A4A),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
    }
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
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF39FF14),
                  ),
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
              debugPrint('Refreshing ProfileScreen');
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
                    if (user == null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4A4A).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Please log in to view your profile.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: const Color(0xFFF9F7F3),
                          ),
                        ),
                      )
                    else
                      StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .snapshots(),
                        builder: (context, snapshot) {
                          String name = 'User';
                          String email = 'email@example.com';
                          String establishment = 'Your Establishment';

                          if (snapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFF4A4A,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFFF4A4A),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Failed to load profile. Tap to retry.',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: const Color(0xFFF9F7F3),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: Color(0xFF39FF14),
                                    ),
                                    onPressed:
                                        () =>
                                            (context as Element)
                                                .markNeedsBuild(),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF39FF14),
                              ),
                            );
                          }
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            name = data['name'] ?? 'User';
                            email =
                                data['email'] ??
                                user.email ??
                                'email@example.com';
                            establishment =
                                data['establishmentName'] ??
                                'Your Establishment';
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2D2D2D,
                                  ).withOpacity(0.85),
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
                                    color: const Color(
                                      0xFF39FF14,
                                    ).withOpacity(0.1),
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
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2D2D2D,
                                  ).withOpacity(0.85),
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
                                    color: const Color(
                                      0xFF39FF14,
                                    ).withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pending Claims',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFF9F7F3),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    StreamBuilder<QuerySnapshot>(
                                      stream:
                                          FirebaseFirestore.instance
                                              .collection('donations')
                                              .where(
                                                'establishmentId',
                                                isEqualTo: user.uid,
                                              )
                                              .where(
                                                'status',
                                                isEqualTo: 'Claimed',
                                              )
                                              .where(
                                                'claimStatus',
                                                isEqualTo: 'pending',
                                              )
                                              .snapshots(),
                                      builder: (context, snapshot) {
                                        debugPrint(
                                          'Pending claims query for user: ${user.uid}, state: ${snapshot.connectionState}, docs: ${snapshot.data?.docs.length ?? 0}',
                                        );
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF39FF14),
                                            ),
                                          );
                                        }
                                        if (snapshot.hasError) {
                                          debugPrint(
                                            'Error in pending claims query: ${snapshot.error}',
                                          );
                                          return Text(
                                            'Failed to load pending claims: ${snapshot.error}',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: const Color(0xFFF9F7F3),
                                            ),
                                          );
                                        }
                                        if (!snapshot.hasData ||
                                            snapshot.data!.docs.isEmpty) {
                                          debugPrint(
                                            'No pending claims found for user: ${user.uid}',
                                          );
                                          return Text(
                                            'No pending claims at the moment.',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: const Color(0xFFB0B0B0),
                                            ),
                                          );
                                        }
                                        debugPrint(
                                          'Found ${snapshot.data!.docs.length} pending claims',
                                        );
                                        return ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: snapshot.data!.docs.length,
                                          itemBuilder: (context, index) {
                                            final doc =
                                                snapshot.data!.docs[index];
                                            final data =
                                                doc.data()
                                                    as Map<String, dynamic>;
                                            final itemName =
                                                data['item_name'] as String;
                                            final quantity =
                                                data['quantity'] as int;
                                            final timestamp =
                                                (data['createdAt'] as Timestamp)
                                                    .toDate();
                                            final pickupTime =
                                                data['pickupTime'] as String;
                                            final acceptorId =
                                                data['acceptorId'] as String;

                                            return FutureBuilder<
                                              DocumentSnapshot
                                            >(
                                              future:
                                                  FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(acceptorId)
                                                      .get(),
                                              builder: (context, userSnapshot) {
                                                String acceptorName = 'Unknown';
                                                if (userSnapshot.hasData &&
                                                    userSnapshot.data!.exists) {
                                                  final userData =
                                                      userSnapshot.data!.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  acceptorName =
                                                      userData['name'] ??
                                                      'Unknown';
                                                }
                                                if (userSnapshot.hasError) {
                                                  debugPrint(
                                                    'Error fetching acceptor: ${userSnapshot.error}',
                                                  );
                                                }

                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 12,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    14,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF3A3A3A,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF39FF14,
                                                      ).withOpacity(0.2),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        itemName,
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  const Color(
                                                                    0xFFF9F7F3,
                                                                  ),
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Quantity: $quantity',
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 14,
                                                              color:
                                                                  const Color(
                                                                    0xFFB0B0B0,
                                                                  ),
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Posted: ${DateFormat('MMM dd, yyyy – HH:mm').format(timestamp)}',
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 14,
                                                              color:
                                                                  const Color(
                                                                    0xFFB0B0B0,
                                                                  ),
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Pickup Time: $pickupTime',
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 14,
                                                              color:
                                                                  const Color(
                                                                    0xFFB0B0B0,
                                                                  ),
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Claimed by: $acceptorName',
                                                        style:
                                                            GoogleFonts.inter(
                                                              fontSize: 14,
                                                              color:
                                                                  const Color(
                                                                    0xFFB0B0B0,
                                                                  ),
                                                            ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          ElevatedButton(
                                                            onPressed:
                                                                () =>
                                                                    _acceptClaim(
                                                                      doc.id,
                                                                      itemName,
                                                                      context,
                                                                    ),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  const Color(
                                                                    0xFF39FF14,
                                                                  ),
                                                              foregroundColor:
                                                                  const Color(
                                                                    0xFF1A3C34,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical: 8,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              'Accept',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          ElevatedButton(
                                                            onPressed:
                                                                () =>
                                                                    _rejectClaim(
                                                                      doc.id,
                                                                      itemName,
                                                                      context,
                                                                    ),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  const Color(
                                                                    0xFFFF4A4A,
                                                                  ),
                                                              foregroundColor:
                                                                  const Color(
                                                                    0xFFF9F7F3,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                              ),
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        16,
                                                                    vertical: 8,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              'Reject',
                                                              style: GoogleFonts.inter(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2D2D2D,
                                  ).withOpacity(0.85),
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
                                    color: const Color(
                                      0xFF39FF14,
                                    ).withOpacity(0.1),
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
                                        HapticFeedback.lightImpact();
                                        _editProfile(
                                          context,
                                          name,
                                          establishment,
                                        );
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
                                          HapticFeedback.lightImpact();
                                          setState(
                                            () => _notificationsEnabled = value,
                                          );
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
                                  color: const Color(
                                    0xFF2D2D2D,
                                  ).withOpacity(0.85),
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
                                    color: const Color(
                                      0xFF39FF14,
                                    ).withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'About Renosh',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
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
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () {
                                            HapticFeedback.lightImpact();
                                            _signOut(context);
                                          },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF4A4A),
                                    foregroundColor: const Color(0xFFF9F7F3),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    shadowColor: const Color(
                                      0xFFFF4A4A,
                                    ).withOpacity(0.3),
                                  ),
                                  child:
                                      _isLoading
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
