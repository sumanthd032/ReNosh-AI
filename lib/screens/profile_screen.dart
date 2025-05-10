import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          Center(
            child: Text(
              'Profile - Coming Soon!',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFF9F7F3),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D).withOpacity(0.9),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('Home', Icons.home, false, () => Navigator.pushNamed(context, '/establishment_dashboard')),
          _buildNavItem('Food Track', Icons.inventory, false, () => Navigator.pushNamed(context, '/food_track')),
          _buildNavItem('History', Icons.history, false, () => Navigator.pushNamed(context, '/history')),
          _buildNavItem('Profile', Icons.person, true, () {}),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isActive ? const Color(0xFF39FF14).withOpacity(0.2) : Colors.transparent,
          boxShadow: isActive
              ? [
                  BoxShadow(color: const Color(0xFF39FF14).withOpacity(0.3), blurRadius: 8),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: isActive ? const Color(0xFF39FF14) : const Color(0xFFB0B0B0)),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF39FF14) : const Color(0xFFB0B0B0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}