import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavBarAcceptor extends StatelessWidget {
  final int isActiveIndex;
  final Function(int) onNavTap;

  const BottomNavBarAcceptor({
    super.key,
    required this.isActiveIndex,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D).withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            'Dashboard',
            Icons.dashboard,
            isActiveIndex == 0,
            () => onNavTap(0),
          ),
          _buildNavItem(
            'History',
            Icons.history,
            isActiveIndex == 1,
            () => onNavTap(1),
          ),
          _buildNavItem(
            'Profile',
            Icons.person,
            isActiveIndex == 2,
            () => onNavTap(2),
          ),
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
                  BoxShadow(
                    color: const Color(0xFF39FF14).withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? const Color(0xFF39FF14) : const Color(0xFFB0B0B0),
            ),
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