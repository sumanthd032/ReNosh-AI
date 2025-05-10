import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AcceptorDashboard extends StatefulWidget {
  const AcceptorDashboard({super.key});

  @override
  _AcceptorDashboardState createState() => _AcceptorDashboardState();
}

class _AcceptorDashboardState extends State<AcceptorDashboard> {
  String _getGreeting() {
    // Use local time adjusted for UTC+5:30
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final hour = now.hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: isError ? const Color(0xFFF9F7F3) : const Color(0xFF1A3C34),
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor:
            isError ? const Color(0xFFFF4A4A) : const Color(0xFF39FF14),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Future<void> _claimDonation(String docId, String itemName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('Please log in to claim donations', isError: true);
        return;
      }
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(docId)
          .update({
            'status': 'Claimed',
            'acceptorId': user.uid,
            'claimedAt': Timestamp.now(),
          });
      _showSnackBar('Successfully claimed $itemName');
    } catch (e) {
      debugPrint('Error claiming donation: $e');
      _showSnackBar('Failed to claim donation', isError: true);
    }
  }

  Widget _buildAvailableDonationsCard(int availableCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
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
            'Available Donations',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF9F7F3),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$availableCount item${availableCount == 1 ? '' : 's'} available to claim',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF39FF14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
          child: RefreshIndicator(
            color: const Color(0xFF39FF14),
            backgroundColor: const Color(0xFF2D2D2D),
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()}, Acceptor!',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF9F7F3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore available food donations',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFB0B0B0),
                    ),
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('donations')
                            .where('status', isEqualTo: 'Available')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF39FF14),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        debugPrint(
                          'Error in donations query: ${snapshot.error}',
                        );
                        return Column(
                          children: [
                            _buildAvailableDonationsCard(0),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFF4A4A,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Failed to load donations. Pull to refresh.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFFF9F7F3),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        debugPrint('No available donations found');
                        return Column(
                          children: [
                            _buildAvailableDonationsCard(0),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D2D).withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'No available donations at the moment.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFFB0B0B0),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      final docs = snapshot.data!.docs;
                      debugPrint('Found ${docs.length} available donations');
                      return Column(
                        children: [
                          _buildAvailableDonationsCard(docs.length),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;
                              final docId = docs[index].id;
                              final timestamp =
                                  (data['createdAt'] as Timestamp).toDate();
                              final pickupTime = data['pickupTime'] as String;
                              return Container(
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
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['item_name'],
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFFF9F7F3),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Quantity: ${data['quantity']}',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: const Color(0xFFB0B0B0),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Posted: ${DateFormat('MMM dd, yyyy – HH:mm').format(timestamp)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: const Color(0xFFB0B0B0),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pickup Time: $pickupTime',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: const Color(0xFFB0B0B0),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => _claimDonation(
                                            docId,
                                            data['item_name'],
                                          ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF39FF14,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF1A3C34,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: Text(
                                        'Claim',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
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
        ),
      ],
    );
  }
}
