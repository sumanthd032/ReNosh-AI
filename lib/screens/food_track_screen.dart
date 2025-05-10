import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FoodTrackScreen extends StatefulWidget {
  const FoodTrackScreen({super.key});

  @override
  State<FoodTrackScreen> createState() => _FoodTrackScreenState();
}

class _FoodTrackScreenState extends State<FoodTrackScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  final _foodItemController = TextEditingController();
  final _quantityMadeController = TextEditingController();
  final _quantitySurplusController = TextEditingController();
  final _quantitySoldController = TextEditingController();
  bool _isLoading = false;
  final _currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _foodItemController.dispose();
    _quantityMadeController.dispose();
    _quantitySurplusController.dispose();
    _quantitySoldController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  bool _validateInputs(int made, int sold, int surplus) {
    if (sold > made) {
      _showErrorSnackBar('Quantity sold cannot exceed quantity made.');
      return false;
    }
    if (surplus > made) {
      _showErrorSnackBar('Quantity surplus cannot exceed quantity made.');
      return false;
    }
    if (sold + surplus > made) {
      _showErrorSnackBar(
        'Sum of sold and surplus cannot exceed quantity made.',
      );
      return false;
    }
    return true;
  }

  Future<void> _addFoodTracking() async {
    if (_foodItemController.text.isEmpty ||
        _quantityMadeController.text.isEmpty ||
        _quantitySurplusController.text.isEmpty ||
        _quantitySoldController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all fields.');
      return;
    }
    final made = int.tryParse(_quantityMadeController.text) ?? 0;
    final sold = int.tryParse(_quantitySoldController.text) ?? 0;
    final surplus = int.tryParse(_quantitySurplusController.text) ?? 0;
    if (!_validateInputs(made, sold, surplus)) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('food_tracking').add({
        'establishmentId': user!.uid,
        'day': DateFormat('EEEE').format(DateTime.now()),
        'date': _currentDate,
        'item_name': _foodItemController.text,
        'quantity_made': made,
        'quantity_surplus': surplus,
        'quantity_sold': sold,
        'timestamp': Timestamp.now(),
      });
      _foodItemController.clear();
      _quantityMadeController.clear();
      _quantitySurplusController.clear();
      _quantitySoldController.clear();
      _showSuccessSnackBar('Food tracking added successfully.');
    } catch (e) {
      _showErrorSnackBar('Failed to add food tracking.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editFoodTracking(
    String docId,
    Map<String, dynamic> data,
  ) async {
    final soldController = TextEditingController(
      text: data['quantity_sold'].toString(),
    );
    final surplusController = TextEditingController(
      text: data['quantity_surplus'].toString(),
    );
    final made = data['quantity_made'] as int;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Edit ${data['item_name']}',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: soldController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFF9F7F3),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Quantity Sold',
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFB0B0B0),
                      ),
                      prefixIcon: const Icon(
                        Icons.sell,
                        color: Color(0xFF39FF14),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF3A3A3A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF39FF14),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: surplusController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFF9F7F3),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Quantity Surplus',
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFB0B0B0),
                      ),
                      prefixIcon: const Icon(
                        Icons.add_chart,
                        color: Color(0xFF39FF14),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF3A3A3A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF39FF14),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFFB0B0B0),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final sold = int.tryParse(soldController.text) ?? 0;
                  final surplus = int.tryParse(surplusController.text) ?? 0;
                  if (!_validateInputs(made, sold, surplus)) return;
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  foregroundColor: const Color(0xFF1A3C34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );

    if (result == true && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('food_tracking')
            .doc(docId)
            .update({
              'quantity_sold': int.parse(soldController.text),
              'quantity_surplus': int.parse(surplusController.text),
              'timestamp': Timestamp.now(),
            });
        _showSuccessSnackBar('Tracking updated successfully.');
      } catch (e) {
        _showErrorSnackBar('Failed to update tracking.');
      }
    }

    soldController.dispose();
    surplusController.dispose();
  }

  String _getSurplusTag(int made, int surplus) {
    if (surplus == 0) {
      return 'All Food Sold';
    }
    double surplusPercentage = (surplus / made) * 100;
    if (surplusPercentage <= 30) {
      return 'Moderate Food Left';
    }
    return 'Excess Food Left';
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'All Food Sold':
        return const Color(0xFF39FF14);
      case 'Moderate Food Left':
        return const Color(0xFFFFD700);
      case 'Excess Food Left':
        return const Color(0xFFFF4A4A);
      default:
        return const Color(0xFFB0B0B0);
    }
  }

  void _showItemDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2D2D2D),
                    const Color(0xFF1A3C34).withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(4, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFFF9F7F3).withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(-4, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: ModalRoute.of(context)!.animation!,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['item_name'],
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFF9F7F3),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        icon: Icons.production_quantity_limits,
                        label: 'Produced',
                        value: '${data['quantity_made']}',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.sell,
                        label: 'Sold',
                        value: '${data['quantity_sold']}',
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.add_chart,
                        label: 'Surplus',
                        value: '${data['quantity_surplus']}',
                      ),
                      const SizedBox(height: 16),
                      _buildStatusChip(
                        status: _getSurplusTag(
                          data['quantity_made'],
                          data['quantity_surplus'],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF39FF14),
                            foregroundColor: const Color(0xFF1A3C34),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            elevation: 0,
                            shadowColor: const Color(
                              0xFF39FF14,
                            ).withOpacity(0.4),
                          ),
                          child: Text(
                            'Close',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF39FF14), size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFB0B0B0),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF9F7F3),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip({required String status}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getTagColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getTagColor(status), width: 1),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _getTagColor(status),
        ),
      ),
    );
  }

  Future<void> _exportData(List<QueryDocumentSnapshot> docs) async {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('Food Tracking Summary for $_currentDate');
    buffer.writeln('================================');
    int totalMade = 0;
    int totalSold = 0;
    int totalSurplus = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      totalMade += data['quantity_made'] as int;
      totalSold += data['quantity_sold'] as int;
      totalSurplus += data['quantity_surplus'] as int;
      buffer.writeln('Item: ${data['item_name']}');
      buffer.writeln('Produced: ${data['quantity_made']}');
      buffer.writeln('Sold: ${data['quantity_sold']}');
      buffer.writeln('Surplus: ${data['quantity_surplus']}');
      buffer.writeln(
        'Status: ${_getSurplusTag(data['quantity_made'], data['quantity_surplus'])}',
      );
      buffer.writeln('----------------');
    }
    buffer.writeln('Total Produced: $totalMade');
    buffer.writeln('Total Sold: $totalSold');
    buffer.writeln('Total Surplus: $totalSurplus');

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      _showSuccessSnackBar('Summary copied to clipboard!');
    }
  }

  Widget _buildSummaryCard(int totalMade, int totalSold, int totalSurplus) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
          // BoxShadow(
          //   color: const Colorrices(0xFFF9F7F3).withOpacity(0.05),
          //   blurRadius: 10,
          //   offset: const Offset(-4, -4),
          // ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Summary',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF9F7F3),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Produced', totalMade),
              _buildSummaryItem('Sold', totalSold),
              _buildSummaryItem('Surplus', totalSurplus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFFB0B0B0),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF9F7F3),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodTrackingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: const Color(0xFFF9F7F3).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track Food Items',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF9F7F3),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _foodItemController,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFFF9F7F3),
            ),
            decoration: InputDecoration(
              labelText: 'Food Item Name',
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFB0B0B0),
              ),
              prefixIcon: const Icon(Icons.food_bank, color: Color(0xFF39FF14)),
              filled: true,
              fillColor: const Color(0xFF3A3A3A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF39FF14),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityMadeController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFFF9F7F3),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Quantity Made',
                    labelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFB0B0B0),
                    ),
                    prefixIcon: const Icon(
                      Icons.production_quantity_limits,
                      color: Color(0xFF39FF14),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF3A3A3A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF39FF14),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _quantitySurplusController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFFF9F7F3),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Quantity Surplus',
                    labelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFB0B0B0),
                    ),
                    prefixIcon: const Icon(
                      Icons.add_chart,
                      color: Color(0xFF39FF14),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF3A3A3A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF39FF14),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantitySoldController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFFF9F7F3),
            ),
            decoration: InputDecoration(
              labelText: 'Quantity Sold',
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFB0B0B0),
              ),
              prefixIcon: const Icon(Icons.sell, color: Color(0xFF39FF14)),
              filled: true,
              fillColor: const Color(0xFF3A3A3A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF39FF14),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        HapticFeedback.lightImpact();
                        _addFoodTracking();
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: const Color(0xFF1A3C34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                shadowColor: const Color(0xFF39FF14).withOpacity(0.3),
              ),
              child: Text(
                'Add Tracking',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3C34),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A3C34),
                const Color(0xFF2D2D2D).withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFF9F7F3)),
          onPressed: () {
            if (mounted) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Food Tracking - $_currentDate',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFF9F7F3),
          ),
        ),
      ),
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
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Track today\'s food production and surplus',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFB0B0B0),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildFoodTrackingSection(),
                  const SizedBox(height: 24),
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('food_tracking')
                            .where(
                              'establishmentId',
                              isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                            )
                            .where('date', isEqualTo: _currentDate)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF39FF14),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Text(
                          'No tracking data for today.',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: const Color(0xFFB0B0B0),
                          ),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      int totalMade = 0;
                      int totalSold = 0;
                      int totalSurplus = 0;
                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        totalMade += data['quantity_made'] as int;
                        totalSold += data['quantity_sold'] as int;
                        totalSurplus += data['quantity_surplus'] as int;
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCard(totalMade, totalSold, totalSurplus),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Today\'s Tracked Items',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF9F7F3),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  color: Color(0xFF39FF14),
                                ),
                                onPressed: () => _exportData(docs),
                                tooltip: 'Export Summary',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;
                              final tag = _getSurplusTag(
                                data['quantity_made'],
                                data['quantity_surplus'],
                              );
                              return ScaleTransition(
                                scale: Tween<double>(
                                  begin: 0.8,
                                  end: 1.0,
                                ).animate(
                                  CurvedAnimation(
                                    parent: _animController,
                                    curve: Interval(
                                      index * 0.1,
                                      1.0,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2D2D2D),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(4, 4),
                                      ),
                                      BoxShadow(
                                        color: const Color(
                                          0xFFF9F7F3,
                                        ).withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(-4, -4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _showItemDetails(data),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['item_name'],
                                                style: GoogleFonts.inter(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFFF9F7F3,
                                                  ),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Surplus: ${data['quantity_surplus']}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: const Color(
                                                    0xFFB0B0B0,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getTagColor(
                                                tag,
                                              ).withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _getTagColor(tag),
                                              ),
                                            ),
                                            child: Text(
                                              tag,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _getTagColor(tag),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Color(0xFF39FF14),
                                              size: 20,
                                            ),
                                            onPressed:
                                                () => _editFoodTracking(
                                                  docs[index].id,
                                                  data,
                                                ),
                                            tooltip: 'Edit Surplus',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
