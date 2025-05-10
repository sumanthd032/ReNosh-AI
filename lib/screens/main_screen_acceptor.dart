import 'package:flutter/material.dart';
import 'package:renosh_app/acceptor_profile.dart';
import 'package:renosh_app/screens/acceptor_dashboard.dart';
import 'package:renosh_app/screens/acceptor_history.dart';
import 'package:renosh_app/screens/bottom_nav_bar_acceptor.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreenAcceptor extends StatefulWidget {
  const MainScreenAcceptor({super.key});

  @override
  _MainScreenAcceptorState createState() => _MainScreenAcceptorState();
}

class _MainScreenAcceptorState extends State<MainScreenAcceptor> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AcceptorDashboard(),
    const AcceptorHistory(),
    const AcceptorProfile(),
  ];

  void _onNavTap(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_screens.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: Text(
            'Error: No screens available',
            style: GoogleFonts.inter(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBarAcceptor(
        isActiveIndex: _currentIndex,
        onNavTap: _onNavTap,
      ),
    );
  }
}