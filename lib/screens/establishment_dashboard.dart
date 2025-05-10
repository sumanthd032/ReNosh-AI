import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:renosh_app/screens/auth_screen/login_screen.dart';
import 'package:renosh_app/screens/food_track_screen.dart';
import 'package:renosh_app/screens/history_screen.dart';
import 'package:renosh_app/screens/profile_screen.dart';
import 'package:renosh_app/screens/surplus_details_screen.dart';

class EstablishmentDashboard extends StatefulWidget {
  const EstablishmentDashboard({super.key});

  @override
  State<EstablishmentDashboard> createState() => _EstablishmentDashboardState();
}

class _EstablishmentDashboardState extends State<EstablishmentDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String? _establishmentName;
  bool _isLoading = true;
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    _setGreeting();
    _fetchUserData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (doc.exists && doc.data()!['role'] == 'Food Establishment') {
          setState(() {
            _establishmentName = doc.data()!['name'];
            _isLoading = false;
          });
        } else {
          _showErrorSnackBar('Invalid role or user data.');
          await FirebaseAuth.instance.signOut();
          if (mounted)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
        }
      } else {
        _showErrorSnackBar('User not authenticated.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load user data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: const Color(0xFFF9F7F3),
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFFFF4A4A),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: const Color(0xFF1A3C34),
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF39FF14),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildAIInsightsCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showSuccessSnackBar('AI Insights tapped! Coming soon.');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2D2D2D),
              const Color(0xFF1A3C34).withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
            BoxShadow(
              color: const Color(0xFFF9F7F3).withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(-4, -4),
            ),
            BoxShadow(
              color: const Color(0xFF39FF14).withOpacity(0.2),
              blurRadius: 12,
            ),
          ],
          border: Border.all(color: const Color(0xFF39FF14).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: Color(0xFF39FF14), size: 24),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF9F7F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Optimize surplus by donating 20% more this week to reduce waste by 5kg.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Powered by ReNosh AI (Gemini + AutoML)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFB0B0B0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSustainabilityCharts() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D2D2D),
            const Color(0xFF1A3C34).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: const Color(0xFFF9F7F3).withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sustainability Tracking',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF9F7F3),
            ),
          ),
          const SizedBox(height: 16),
          CarouselSlider(
            options: CarouselOptions(
              height: 200,
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 2.0,
              viewportFraction: 0.8,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              enableInfiniteScroll: true,
            ),
            items: [
              _buildChartCard(
                title: 'Meals Donated',
                chart: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: 50,
                            color: const Color(0xFF39FF14),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: 70,
                            color: const Color(0xFF39FF14),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: 60,
                            color: const Color(0xFF39FF14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _buildChartCard(
                title: 'Food Saved (kg)',
                chart: LineChart(
                  LineChartData(
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 10),
                          FlSpot(1, 15),
                          FlSpot(2, 12),
                          FlSpot(3, 20),
                        ],
                        isCurved: true,
                        color: const Color(0xFF39FF14),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              _buildChartCard(
                title: 'AI Impact',
                chart: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: 40,
                        color: const Color(0xFF39FF14),
                        title: 'Optimized',
                      ),
                      PieChartSectionData(
                        value: 60,
                        color: const Color(0xFFB0B0B0),
                        title: 'Standard',
                      ),
                    ],
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget chart}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF9F7F3),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(height: 110, child: chart),
        ],
      ),
    );
  }

  Widget _buildSurplusItems() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D).withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFB0B0B0), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Please log in to view surplus items.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFB0B0B0),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D2D2D),
            const Color(0xFF1A3C34).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: const Color(0xFFF9F7F3).withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Surplus Items',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF9F7F3),
            ),
          ),
          // Reduced the SizedBox height here, or you can remove it entirely if needed.
          const SizedBox(height: 4), // Set this to the smallest value
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('food_tracking')
                    .where('establishmentId', isEqualTo: user.uid)
                    .where('quantity_surplus', isGreaterThan: 0)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: Color(0xFF39FF14),
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                debugPrint('Surplus query error: ${snapshot.error}');
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4A4A).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFF4A4A).withOpacity(0.4),
                    ),
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
                          'Failed to load surplus items. Check logs for details.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFF9F7F3),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                debugPrint('No surplus items found for user: ${user.uid}');
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFB0B0B0),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No surplus items found. Try adding some in Food Track.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFB0B0B0),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              debugPrint('Found ${snapshot.data!.docs.length} surplus items');
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final item = doc['item_name'] as String;
                  final quantity = doc['quantity_surplus'] as int;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SurplusDetailsScreen(
                                itemName: item,
                                quantity: quantity,
                                docId: doc.id,
                              ), // Replace with your new screen
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: const Color(0xFF39FF14).withOpacity(0.05),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF39FF14).withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF39FF14).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.restaurant_menu,
                              color: Color(0xFF39FF14),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFF9F7F3),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Surplus: $quantity ${quantity == 1 ? 'item' : 'items'}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
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
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
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
            'Home',
            Icons.home,
            true,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EstablishmentDashboard()),
            ),
          ),
          _buildNavItem(
            'Food Track',
            Icons.inventory,
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FoodTrackScreen()),
            ),
          ),
          _buildNavItem(
            'History',
            Icons.history,
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            ),
          ),
          _buildNavItem(
            'Profile',
            Icons.person,
            false,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    String title,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
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
          color:
              isActive
                  ? const Color(0xFF39FF14).withOpacity(0.2)
                  : Colors.transparent,
          boxShadow:
              isActive
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
              color:
                  isActive ? const Color(0xFF39FF14) : const Color(0xFFB0B0B0),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isActive
                        ? const Color(0xFF39FF14)
                        : const Color(0xFFB0B0B0),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                colors: [
                  const Color(0xFF1A3C34).withOpacity(0.95),
                  const Color(0xFF2D2D2D).withOpacity(0.85),
                ],
              ),
            ),
          ),
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF39FF14)),
              )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Image.asset(
                                  'assets/logo.jpg',
                                  width: 80,
                                  height: 80,
                                  semanticLabel: 'ReNosh Logo',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              '$_greeting, ${_establishmentName ?? 'Loading...'}!',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF9F7F3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your surplus and track sustainability',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFFB0B0B0),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildAIInsightsCard(),
                          const SizedBox(height: 24),
                          _buildSustainabilityCharts(),
                          const SizedBox(height: 24),
                          _buildSurplusItems(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomNavBar(),
                ],
              ),
        ],
      ),
    );
  }
}
