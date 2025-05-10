import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SurplusDetailsScreen extends StatefulWidget {
  final String itemName;
  final int quantity;
  final String docId;

  const SurplusDetailsScreen({
    super.key,
    required this.itemName,
    required this.quantity,
    required this.docId,
  });

  @override
  State<SurplusDetailsScreen> createState() => _SurplusDetailsScreenState();
}

class _SurplusDetailsScreenState extends State<SurplusDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;
  bool _isDonated = false;
  final _quantityController = TextEditingController(text: '1');
  String? _quantityError;

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
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    _checkDonationStatus();
  }

  @override
  void dispose() {
    _animController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _checkDonationStatus() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('food_tracking')
              .doc(widget.docId)
              .get();
      if (doc.exists) {
        setState(() {
          _isDonated =
              doc.data()!['isDonated'] == true ||
              doc.data()!['quantity_surplus'] == 0;
          if (!_isDonated) {
            _quantityController.text =
                (doc.data()!['quantity_surplus'] as int).toString();
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to check donation status: $e');
    }
  }

  Future<void> _donateItem() async {
    final selectedQuantity = int.tryParse(_quantityController.text);
    if (selectedQuantity == null ||
        selectedQuantity <= 0 ||
        selectedQuantity > widget.quantity) {
      setState(() {
        _quantityError = 'Enter a number between 1 and ${widget.quantity}';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _quantityError = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Please log in to donate.');
        setState(() => _isLoading = false);
        return;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final foodDocRef = FirebaseFirestore.instance
            .collection('food_tracking')
            .doc(widget.docId);

        final foodDoc = await transaction.get(foodDocRef);
        if (!foodDoc.exists) {
          throw Exception('Item does not exist.');
        }
        final currentSurplus = foodDoc.data()!['quantity_surplus'] as int;
        if (currentSurplus < selectedQuantity) {
          throw Exception('Not enough surplus items available.');
        }
        if (foodDoc.data()!['isDonated'] == true || currentSurplus == 0) {
          throw Exception('Item already donated.');
        }

        final newSurplus = currentSurplus - selectedQuantity;
        transaction.update(foodDocRef, {
          'quantity_surplus': newSurplus,
          'isDonated': newSurplus == 0,
        });

        await FirebaseFirestore.instance.collection('donations').add({
          'establishmentId': user.uid,
          'item_name': widget.itemName,
          'quantity': selectedQuantity,
          'pickupTime': DateFormat(
            'HH:mm',
          ).format(DateTime.now().add(const Duration(hours: 2))),
          'status': 'Available',
          'createdAt': Timestamp.now(),
        });
      });

      setState(() {
        _isDonated = selectedQuantity == widget.quantity;
        _isLoading = false;
        if (!_isDonated) {
          _quantityController.text =
              (widget.quantity - selectedQuantity).toString();
        }
      });
      _showSuccessSnackBar('Donated $selectedQuantity item(s) successfully!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to donate item: $e');
    }
  }

  void _incrementQuantity() {
    final current = int.tryParse(_quantityController.text) ?? 1;
    if (current < widget.quantity) {
      setState(() {
        _quantityController.text = (current + 1).toString();
        _quantityError = null;
      });
    }
  }

  void _decrementQuantity() {
    final current = int.tryParse(_quantityController.text) ?? 1;
    if (current > 1) {
      setState(() {
        _quantityController.text = (current - 1).toString();
        _quantityError = null;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFFF9F7F3),
          ),
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
            fontSize: 12,
            color: const Color(0xFF1A3C34),
          ),
        ),
        backgroundColor: const Color(0xFF39FF14),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D).withOpacity(0.7),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF39FF14),
                            size: 24,
                          ),
                        ),
                      ),
                      Text(
                        'Surplus Details',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF9F7F3),
                        ),
                      ),
                      const SizedBox(width: 40), // Spacer for symmetry
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: AnimationLimiter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 600),
                          childAnimationBuilder:
                              (widget) => FadeTransition(
                                opacity: _fadeAnimation,
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: widget,
                                ),
                              ),
                          children: [
                            // Item Details Card
                            Container(
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
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 6,
                                    offset: const Offset(2, 2),
                                  ),
                                  BoxShadow(
                                    color: const Color(
                                      0xFF39FF14,
                                    ).withOpacity(0.08),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(
                                    0xFF39FF14,
                                  ).withOpacity(0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            center: Alignment.center,
                                            radius: 0.8,
                                            colors: [
                                              const Color(
                                                0xFF39FF14,
                                              ).withOpacity(0.3),
                                              const Color(
                                                0xFF2D2D2D,
                                              ).withOpacity(0.5),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.restaurant_menu,
                                          color: Color(0xFF39FF14),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          widget.itemName,
                                          style: GoogleFonts.inter(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFF9F7F3),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Surplus Quantity: ${widget.quantity} ${widget.quantity == 1 ? 'item' : 'items'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFFB0B0B0),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Status: ${_isDonated ? 'Donated' : 'Available'}',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          _isDonated
                                              ? const Color(0xFF39FF14)
                                              : const Color(0xFFF9F7F3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Quantity Selector
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D2D).withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(
                                    0xFF39FF14,
                                  ).withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Quantity to Donate',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFF9F7F3),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap:
                                            _isDonated || _isLoading
                                                ? null
                                                : _decrementQuantity,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color:
                                                _isDonated || _isLoading
                                                    ? const Color(
                                                      0xFFB0B0B0,
                                                    ).withOpacity(0.3)
                                                    : const Color(
                                                      0xFF39FF14,
                                                    ).withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.remove,
                                            color: Color(0xFFF9F7F3),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: _quantityController,
                                          enabled: !_isDonated && !_isLoading,
                                          keyboardType: TextInputType.number,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: const Color(0xFFF9F7F3),
                                          ),
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 8,
                                                  horizontal: 12,
                                                ),
                                            filled: true,
                                            fillColor: const Color(
                                              0xFF1A3C34,
                                            ).withOpacity(0.5),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: const Color(
                                                  0xFF39FF14,
                                                ).withOpacity(0.2),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: const Color(
                                                  0xFF39FF14,
                                                ).withOpacity(0.2),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: Color(0xFF39FF14),
                                                width: 1.5,
                                              ),
                                            ),
                                            errorText: _quantityError,
                                            errorStyle: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: const Color(0xFFFF4A4A),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap:
                                            _isDonated || _isLoading
                                                ? null
                                                : _incrementQuantity,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color:
                                                _isDonated || _isLoading
                                                    ? const Color(
                                                      0xFFB0B0B0,
                                                    ).withOpacity(0.3)
                                                    : const Color(
                                                      0xFF39FF14,
                                                    ).withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Color(0xFFF9F7F3),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Donate Button
                            Center(
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF39FF14),
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : GestureDetector(
                                        onTap: _isDonated ? null : _donateItem,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                _isDonated
                                                    ? const Color(
                                                      0xFFB0B0B0,
                                                    ).withOpacity(0.5)
                                                    : const Color(0xFF39FF14),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF39FF14,
                                                ).withOpacity(
                                                  _isDonated ? 0.0 : 0.3,
                                                ),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            'Donate',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  _isDonated
                                                      ? const Color(0xFF2D2D2D)
                                                      : const Color(0xFF1A3C34),
                                            ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
