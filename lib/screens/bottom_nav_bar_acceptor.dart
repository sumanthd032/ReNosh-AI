import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' show Platform;

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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
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
              context,
            ),
            _buildNavItem(
              'History',
              Icons.history,
              isActiveIndex == 1,
              () => onNavTap(1),
              context,
            ),
            _buildNavItem(
              'Profile',
              Icons.person,
              isActiveIndex == 2,
              () => onNavTap(2),
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String title,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return Semantics(
      label: title,
      selected: isActive,
      child: GestureDetector(
        key: Key('nav_$title'),
        onTap: () {
          if (Platform.isAndroid || Platform.isIOS) {
            HapticFeedback.lightImpact();
          }
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Colors.transparent,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      blurRadius: 6,
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
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}