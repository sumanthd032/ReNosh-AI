import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class EstablishmentDashboard extends StatefulWidget {
  const EstablishmentDashboard({super.key});

  @override
  State<EstablishmentDashboard> createState() => _EstablishmentDashboardState();
}

class _EstablishmentDashboardState extends State<EstablishmentDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String? _establishmentName;
  bool _isLoading = true;
  final _quantityController = TextEditingController();
  final _pickupTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    _fetchUserData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _quantityController.dispose();
    _pickupTimeController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()!['role'] == 'Food Establishment') {
          setState(() {
            _establishmentName = doc.data()!['name'];
            _isLoading = false;
          });
        } else {
          _showErrorSnackBar('Invalid role or user data.');
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load user data.');
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: const Color(0xFFF9F7F3), fontSize: kIsWeb ? 16 : 14),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFFFF4A4A),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: kIsWeb ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: const Color(0xFF1A3C34), fontSize: kIsWeb ? 16 : 14),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF39FF14),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: kIsWeb ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Future<void> _createDonation() async {
    if (_quantityController.text.isEmpty || _pickupTimeController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all fields.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('donations').add({
        'establishmentId': user!.uid,
        'quantity': _quantityController.text,
        'pickupTime': _pickupTimeController.text,
        'status': 'Available',
        'createdAt': Timestamp.now(),
      });
      _quantityController.clear();
      _pickupTimeController.clear();
      _showSuccessSnackBar('Donation created successfully.');
    } catch (e) {
      _showErrorSnackBar('Failed to create donation.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset('assets/logo.jpg', width: 80, height: 80, semanticLabel: 'ReNosh Logo'),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              _establishmentName ?? 'Loading...',
              style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFFF9F7F3)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Food Establishment Dashboard',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFFB0B0B0)),
          ),
          const SizedBox(height: 24),
          _buildDonationSection(isWebLayout: false),
          const SizedBox(height: 24),
          _buildImpactSection(isWebLayout: false),
          const SizedBox(height: 24),
          _buildProfileSection(isWebLayout: false),
          const SizedBox(height: 24),
          _buildLogoutButton(isWebLayout: false),
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
          Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF1A3C34).withOpacity(0.95), const Color(0xFF39FF14).withOpacity(0.15)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/logo.jpg', width: 80, height: 80, semanticLabel: 'ReNosh Logo'),
                const SizedBox(height: 16),
                Text(
                  'ReNosh',
                  style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFFF9F7F3)),
                ),
                const SizedBox(height: 8),
                Text(
                  _establishmentName ?? 'Loading...',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFFF9F7F3)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                _buildSidebarItem('Donations', Icons.restaurant_menu, () {}),
                const SizedBox(height: 12),
                _buildSidebarItem('Impact', Icons.insights, () {}),
                const SizedBox(height: 12),
                _buildSidebarItem('Profile', Icons.person, () {}),
                const Spacer(),
                _buildSidebarItem('Logout', Icons.logout, () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) Navigator.pushReplacementNamed(context, '/login');
                }),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 48 : 24, vertical: 40),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isWideScreen) ...[
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Image.asset('assets/logo.jpg', width: 80, height: 80, semanticLabel: 'ReNosh Logo'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _establishmentName ?? 'Loading...',
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFFF9F7F3)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Food Establishment Dashboard',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFFB0B0B0)),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildDonationSection(isWebLayout: true),
                  const SizedBox(height: 24),
                  _buildImpactSection(isWebLayout: true),
                  const SizedBox(height: 24),
                  _buildProfileSection(isWebLayout: true),
                  if (!isWideScreen) ...[
                    const SizedBox(height: 24),
                    _buildLogoutButton(isWebLayout: true),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(String title, IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF2D2D2D).withOpacity(0.5),
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: const Color(0xFF39FF14)),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFFF9F7F3)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationSection({required bool isWebLayout}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2D2D2D), const Color(0xFF1A3C34).withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(4, 4)),
          BoxShadow(color: const Color(0xFFF9F7F3).withOpacity(0.03), blurRadius: 8, offset: const Offset(-4, -4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Donation',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFF9F7F3)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            style: GoogleFonts.inter(fontSize: isWebLayout ? 16 : 14, color: const Color(0xFFF9F7F3)),
            decoration: InputDecoration(
              labelText: 'Quantity (e.g., 10 meals)',
              labelStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB0B0B0)),
              prefixIcon: const Icon(Icons.food_bank, color: Color(0xFF39FF14)),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF39FF14), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pickupTimeController,
            style: GoogleFonts.inter(fontSize: isWebLayout ? 16 : 14, color: const Color(0xFFF9F7F3)),
            decoration: InputDecoration(
              labelText: 'Pickup Time (e.g., 14:00)',
              labelStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB0B0B0)),
              prefixIcon: const Icon(Icons.access_time, color: Color(0xFF39FF14)),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF39FF14), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createDonation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: const Color(0xFF1A3C34),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                shadowColor: isWebLayout ? const Color(0xFF39FF14).withOpacity(0.3) : Colors.transparent,
              ),
              child: Text(
                'Create Donation',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isWebLayout ? 18 : 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Active Donations',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFF9F7F3)),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('donations')
                .where('establishmentId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('status', isEqualTo: 'Available')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text(
                  'No active donations.',
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFB0B0B0)),
                );
              }
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  return Card(
                    color: const Color(0xFF2D2D2D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(
                        '${doc['quantity']} meals',
                        style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFF9F7F3)),
                      ),
                      subtitle: Text(
                        'Pickup: ${doc['pickupTime']}',
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFB0B0B0)),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImpactSection({required bool isWebLayout}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2D2D2D), const Color(0xFF1A3C34).withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(4, 4)),
          BoxShadow(color: const Color(0xFFF9F7F3).withOpacity(0.03), blurRadius: 8, offset: const Offset(-4, -4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Impact',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFF9F7F3)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildImpactCard('Meals Donated', '150', Icons.food_bank, isWebLayout),
              _buildImpactCard('Waste Reduced', '50 kg', Icons.recycling, isWebLayout),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(String title, String value, IconData icon, bool isWebLayout) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF39FF14)),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFFF9F7F3)),
            ),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFB0B0B0)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection({required bool isWebLayout}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2D2D2D), const Color(0xFF1A3C34).withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(4, 4)),
          BoxShadow(color: const Color(0xFFF9F7F3).withOpacity(0.03), blurRadius: 8, offset: const Offset(-4, -4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFFF9F7F3)),
          ),
          const SizedBox(height: 16),
          Text(
            'Name: ${_establishmentName ?? 'Loading...'}',
            style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFF9F7F3)),
          ),
          const SizedBox(height: 8),
          Text(
            'Type: Restaurant',
            style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFFF9F7F3)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _showSuccessSnackBar('Profile update coming soon!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: const Color(0xFF1A3C34),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                shadowColor: isWebLayout ? const Color(0xFF39FF14).withOpacity(0.3) : Colors.transparent,
              ),
              child: Text(
                'Edit Profile',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isWebLayout ? 18 : 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton({required bool isWebLayout}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4A4A),
          foregroundColor: const Color(0xFFF9F7F3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
          'Logout',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: isWebLayout ? 18 : 16),
        ),
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
                colors: [const Color(0xFF1A3C34).withOpacity(0.95), const Color(0xFF2D2D2D).withOpacity(0.85)],
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14)))
              : isWebLayout
                  ? _buildWebLayout()
                  : _buildMobileLayout(),
        ],
      ),
    );
  }
}