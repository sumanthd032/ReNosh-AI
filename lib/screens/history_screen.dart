import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Please log in to view donation history.',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF9F7F3),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

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
                    'Donation History',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF9F7F3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your past donations',
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
                            .where('establishmentId', isEqualTo: user.uid)
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
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4A4A).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
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
                                  'Failed to load donation history. Tap to retry.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFF9F7F3),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Color(0xFF39FF14),
                                ),
                                onPressed: () {
                                  (context as Element).markNeedsBuild();
                                },
                              ),
                            ],
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        debugPrint('No donations found for user: ${user.uid}');
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
                                  'No donation history found.',
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

                      debugPrint(
                        'Found ${snapshot.data!.docs.length} donations',
                      );
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final itemName = data['item_name'] as String;
                          final quantity = data['quantity'] as int;
                          final timestamp =
                              (data['createdAt'] as Timestamp).toDate();
                          final formattedDate = DateFormat(
                            'MMM dd, yyyy – HH:mm',
                          ).format(timestamp);
                          final pickupTime = data['pickupTime'] as String;
                          final status = (data['status'] as String);
                          final acceptorId =
                              data.containsKey('acceptorId')
                                  ? data['acceptorId']
                                  : null;

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              // Add details view if needed
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2D2D2D,
                                ).withOpacity(0.85),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                  BoxShadow(
                                    color: const Color(
                                      0xFF39FF14,
                                    ).withOpacity(0.05),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(
                                    0xFF39FF14,
                                  ).withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF39FF14,
                                      ).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.volunteer_activism,
                                      color: Color(0xFF39FF14),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itemName,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFF9F7F3),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Quantity: $quantity ${quantity == 1 ? 'item' : 'items'}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFFB0B0B0),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Date: $formattedDate',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFFB0B0B0),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Pickup Time: $pickupTime',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFFB0B0B0),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Status: $status',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color:
                                                status == 'Available'
                                                    ? const Color(0xFF39FF14)
                                                    : const Color(0xFFB0B0B0),
                                          ),
                                        ),
                                        if (acceptorId != null) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            'Claimed by: Acceptor',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xFFB0B0B0),
                                            ),
                                          ),
                                        ],
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
            ),
          ),
        ),
      ],
    );
  }
}
