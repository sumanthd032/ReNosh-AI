import 'package:flutter/material.dart';
import 'package:renosh_app/screens/nav_item.dart';

class BottomNavBarEstablishment extends StatelessWidget {
  final int isActiveIndex;
  final Function(int) onNavTap;

  const BottomNavBarEstablishment({
    super.key,
    required this.isActiveIndex,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.04,
        vertical: 8,
      ),
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
          NavItem(
            title: 'Home',
            icon: Icons.home,
            isActive: isActiveIndex == 0,
            onTap: () => onNavTap(0),
          ),
          NavItem(
            title: 'Food Track',
            icon: Icons.inventory,
            isActive: isActiveIndex == 1,
            onTap: () => onNavTap(1),
          ),
          NavItem(
            title: 'History',
            icon: Icons.history,
            isActive: isActiveIndex == 2,
            onTap: () => onNavTap(2),
          ),
          NavItem(
            title: 'Profile',
            icon: Icons.person,
            isActive: isActiveIndex == 3,
            onTap: () => onNavTap(3),
          ),
        ],
      ),
    );
  }
}