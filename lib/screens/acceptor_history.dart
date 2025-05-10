import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AcceptorHistory extends StatelessWidget {
  const AcceptorHistory({super.key});

  void _showDonorDetailsDialog(
    BuildContext context, {
    required String donorName,
    required String phoneNumber,
    required String address,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF1A3C34).withOpacity(0.95),
                    const Color(0xFF2D2D2D).withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donor Details',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF39FF14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Donor: $donorName',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFF9F7F3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Phone: $phoneNumber',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFF9F7F3),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Address: $address',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFF9F7F3),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF1A3C34),
                        child: IconButton(
                          icon: const Icon(
                            Icons.location_on,
                            color: Color(0xFF39FF14),
                            size: 28,
                          ),
                          onPressed: () {
                            debugPrint(
                              'Location icon tapped for address: $address',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        debugPrint('Closed donor details dialog');
                        Navigator.of(context).pop();
                      },
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
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

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
                    'Please log in to view your claim history.',
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
              debugPrint('Refreshing AcceptorHistory');
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Claim History',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF9F7F3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your claimed donations',
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
                            .where('acceptorId', isEqualTo: user.uid)
                            .where(
                              'claimStatus',
                              whereIn: ['pending', 'accepted', 'rejected'],
                            )
                            .orderBy('claimedAt', descending: true)
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
                          'Error in claim history query: ${snapshot.error}',
                        );
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4A4A).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Failed to load claim history. Pull to refresh.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFFF9F7F3),
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        debugPrint(
                          'No claimed donations found for user: ${user.uid}',
                        );
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'No claimed donations found.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFFB0B0B0),
                            ),
                          ),
                        );
                      }

                      debugPrint(
                        'Found ${snapshot.data!.docs.length} claimed donations for user: ${user.uid}',
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
                          final pickupTime = data['pickupTime'] as String;
                          final claimStatus =
                              data['claimStatus'] as String? ?? 'Unknown';
                          final establishmentId =
                              data['establishmentId'] as String;

                          debugPrint(
                            'Donation ${doc.id}: item=$itemName, claimStatus=$claimStatus, establishmentId=$establishmentId',
                          );

                          return FutureBuilder<DocumentSnapshot>(
                            future:
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(establishmentId)
                                    .get(),
                            builder: (context, userSnapshot) {
                              String donorName = 'Unknown';
                              String phoneNumber = 'N/A';
                              String address = 'N/A';
                              if (userSnapshot.hasData &&
                                  userSnapshot.data!.exists) {
                                final userData =
                                    userSnapshot.data!.data()
                                        as Map<String, dynamic>;
                                donorName =
                                    userData['name'] as String? ?? 'Unknown';
                                phoneNumber =
                                    userData['contact'] as String? ?? 'N/A';
                                address =
                                    userData['address'] as String? ?? 'N/A';
                                debugPrint(
                                  'Fetched user $establishmentId: name=$donorName, contact=$phoneNumber, address=$address',
                                );
                              } else {
                                debugPrint(
                                  'User $establishmentId not found or error: ${userSnapshot.error}',
                                );
                              }

                              return GestureDetector(
                                onTap: () {
                                  debugPrint(
                                    'Tapped donation ${doc.id}: claimStatus=$claimStatus',
                                  );
                                  if (claimStatus == 'accepted') {
                                    _showDonorDetailsDialog(
                                      context,
                                      donorName: donorName,
                                      phoneNumber: phoneNumber,
                                      address: address,
                                    );
                                  }
                                },
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        itemName,
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFF9F7F3),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Quantity: $quantity',
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
                                      const SizedBox(height: 4),
                                      Text(
                                        'Claim Status: ${claimStatus[0].toUpperCase()}${claimStatus.substring(1)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              claimStatus == 'accepted'
                                                  ? const Color(0xFF39FF14)
                                                  : claimStatus == 'rejected'
                                                  ? const Color(0xFFFF4A4A)
                                                  : const Color(0xFFB0B0B0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
