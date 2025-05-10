import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

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

  Future<void> _donateItem(String item, int quantity) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('donations').add({
        'establishmentId': user!.uid,
        'quantity': '$quantity meals',
        'pickupTime': DateFormat(
          'HH:mm',
        ).format(DateTime.now().add(const Duration(hours: 2))),
        'status': 'Available',
        'createdAt': Timestamp.now(),
      });
      await FirebaseFirestore.instance.collection('history').add({
        'establishmentId': user.uid,
        'action': 'Donate',
        'item': item,
        'quantity': quantity,
        'timestamp': Timestamp.now(),
      });
      _showSuccessSnackBar('Donation created successfully.');
    } catch (e) {
      _showErrorSnackBar('Failed to create donation.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sellItem(String item, int quantity) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('sales').add({
        'establishmentId': user!.uid,
        'item': item,
        'quantity': quantity,
        'price': 0.0, // Placeholder
        'status': 'Sold',
        'createdAt': Timestamp.now(),
      });
      await FirebaseFirestore.instance.collection('history').add({
        'establishmentId': user.uid,
        'action': 'Sell',
        'item': item,
        'quantity': quantity,
        'timestamp': Timestamp.now(),
      });
      _showSuccessSnackBar('Item marked for sale.');
    } catch (e) {
      _showErrorSnackBar('Failed to mark item for sale.');
    } finally {
      setState(() => _isLoading = false);
    }
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
          SizedBox(height: 120, child: chart),
        ],
      ),
    );
  }

  Widget _buildSurplusItems() {
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
            'Surplus Items',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF9F7F3),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('food_tracking')
                    .where(
                      'establishmentId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                    )
                    .where('quantity_surplus', isGreaterThan: 0)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF39FF14)),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text(
                  'No surplus items.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFFB0B0B0),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final item = doc['item_name'];
                  final quantity = doc['quantity_surplus'];
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF9F7F3),
                          ),
                        ),
                        Text(
                          'Surplus: $quantity',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFFB0B0B0),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _donateItem(item, quantity);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF39FF14),
                                foregroundColor: const Color(0xFF1A3C34),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Donate',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _sellItem(item, quantity);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF9F7F3),
                                foregroundColor: const Color(0xFF1A3C34),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Sell',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _showSuccessSnackBar(
                                  'Other actions coming soon!',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB0B0B0),
                                foregroundColor: const Color(0xFF1A3C34),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Other',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
          _buildNavItem('Home', Icons.home, true, () {}),
          _buildNavItem(
            'Food Track',
            Icons.inventory,
            false,
            () => Navigator.pushNamed(context, '/food_track'),
          ),
          _buildNavItem(
            'History',
            Icons.history,
            false,
            () => Navigator.pushNamed(context, '/history'),
          ),
          _buildNavItem(
            'Profile',
            Icons.person,
            false,
            () => Navigator.pushNamed(context, '/profile'),
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
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Image.asset(
                              'assets/logo.jpg',
                              width: 80,
                              height: 80,
                              semanticLabel: 'ReNosh Logo',
                            ),
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
