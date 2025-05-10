import 'package:flutter/material.dart';
import 'package:renosh_app/screens/bottom_nav_bar_acceptor.dart';

class MainScreenAcceptor extends StatefulWidget {
  const MainScreenAcceptor({super.key});

  @override
  _MainScreenAcceptorState createState() => _MainScreenAcceptorState();
}

class _MainScreenAcceptorState extends State<MainScreenAcceptor> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    // const AcceptorDashboard(),
    // const AcceptorHistory(),
    // const AcceptorProfile(),
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
      bottomNavigationBar: BottomNavBarAcceptor(
        isActiveIndex: _currentIndex,
        onNavTap: _onNavTap,
      ),
    );
  }
}