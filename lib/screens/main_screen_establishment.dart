import 'package:flutter/material.dart';
import 'package:renosh_app/screens/bottom_nav_bar_establishment.dart';
import 'package:renosh_app/screens/establishment_dashboard.dart';
import 'package:renosh_app/screens/food_track_screen.dart';
import 'package:renosh_app/screens/history_screen.dart';
import 'package:renosh_app/screens/profile_screen.dart';

class MainScreenEstablishment extends StatefulWidget {
  const MainScreenEstablishment({super.key});

  @override
  _MainScreenEstablishmentState createState() => _MainScreenEstablishmentState();
}

class _MainScreenEstablishmentState extends State<MainScreenEstablishment> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const EstablishmentDashboard(),
    const FoodTrackScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBarEstablishment(
        isActiveIndex: _currentIndex,
        onNavTap: _onNavTap,
      ),
    );
  }
}