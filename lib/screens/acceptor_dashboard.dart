import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import 'package:renosh_app/screens/acceptors_settings_screen.dart';

double calculateDistance(LatLng point1, LatLng point2) {
  const double earthRadius = 6371; // km
  double lat1 = point1.latitude * pi / 180;
  double lat2 = point2.latitude * pi / 180;
  double deltaLat = (point2.latitude - point1.latitude) * pi / 180;
  double deltaLon = (point2.longitude - point1.longitude) * pi / 180;

  double a =
      sin(deltaLat / 2) * sin(deltaLat / 2) +
      cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  double distance = earthRadius * c; // Distance in km
  debugPrint(
    'Haversine: lat1=$lat1, lat2=$lat2, deltaLat=$deltaLat, deltaLon=$deltaLon, a=$a, c=$c, distance=$distance km',
  );
  return distance;
}

class AcceptorDashboard extends StatefulWidget {
  const AcceptorDashboard({super.key});

  @override
  _AcceptorDashboardState createState() => _AcceptorDashboardState();
}

class _AcceptorDashboardState extends State<AcceptorDashboard> {
  String _getGreeting() {
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
            'claimStatus': 'pending',
          });
      debugPrint(
        'Claim requested for donation $docId by user ${user.uid}: status=Claimed, claimStatus=pending',
      );
      _showSnackBar('Claim requested for $itemName. Awaiting seller approval.');
    } catch (e) {
      debugPrint('Error claiming donation: $e');
      _showSnackBar('Failed to request claim: $e', isError: true);
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
    final user = FirebaseAuth.instance.currentUser;

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
              debugPrint('Refreshing AcceptorDashboard');
              await Future.delayed(const Duration(milliseconds: 500));
              setState(() {});
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child:
                            user == null
                                ? Text(
                                  '${_getGreeting()}!',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFF9F7F3),
                                  ),
                                )
                                : StreamBuilder<DocumentSnapshot>(
                                  stream:
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .snapshots(),
                                  builder: (context, snapshot) {
                                    String organizationName = 'Organization';
                                    if (snapshot.hasError) {
                                      debugPrint(
                                        'Error fetching user data: ${snapshot.error}',
                                      );
                                      return Text(
                                        '${_getGreeting()}, $organizationName!',
                                        style: GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFF9F7F3),
                                        ),
                                      );
                                    }
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text(
                                        '${_getGreeting()}...',
                                        style: GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFF9F7F3),
                                        ),
                                      );
                                    }
                                    if (snapshot.hasData &&
                                        snapshot.data!.exists) {
                                      final data =
                                          snapshot.data!.data()
                                              as Map<String, dynamic>;
                                      organizationName =
                                          data['org_name'] as String? ??
                                          'Organization';
                                      debugPrint(
                                        'Fetched user ${user.uid}: org_name=$organizationName',
                                      );
                                    } else {
                                      debugPrint(
                                        'User document ${user.uid} not found',
                                      );
                                    }
                                    return Text(
                                      '${_getGreeting()}, $organizationName!',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFF9F7F3),
                                      ),
                                    );
                                  },
                                ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.settings,
                          color: Color(0xFFF9F7F3),
                          size: 28,
                        ),
                        onPressed: () {
                          debugPrint('Navigating to AcceptorSettingsScreen');
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => const AcceptorSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
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
                  StreamBuilder<DocumentSnapshot>(
                    stream:
                        user != null
                            ? FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .snapshots()
                            : null,
                    builder: (context, userSnapshot) {
                      if (user == null) {
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
                                'Please log in to view donations.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFFF9F7F3),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF39FF14),
                          ),
                        );
                      }
                      if (userSnapshot.hasError ||
                          !userSnapshot.hasData ||
                          !userSnapshot.data!.exists) {
                        debugPrint(
                          'Error fetching user data: ${userSnapshot.error}',
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
                                'Error loading user data.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFFF9F7F3),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      final acceptorLocation =
                          userData.containsKey('location')
                              ? LatLng(
                                (userData['location']['latitude'] as num?)
                                        ?.toDouble() ??
                                    0.0,
                                (userData['location']['longitude'] as num?)
                                        ?.toDouble() ??
                                    0.0,
                              )
                              : null;
                      final maxDistanceKm =
                          (userData['maxDistanceKm'] as num?)?.toDouble() ??
                          1000.0;

                      debugPrint(
                        'Acceptor location: $acceptorLocation (lat: ${acceptorLocation?.latitude}, lng: ${acceptorLocation?.longitude}), maxDistanceKm: $maxDistanceKm',
                      );

                      if (acceptorLocation == null ||
                          acceptorLocation.latitude == 0.0 ||
                          acceptorLocation.longitude == 0.0) {
                        debugPrint(
                          'Invalid or missing acceptor location for user: ${user.uid}',
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
                                'Please set your location in settings.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFFF9F7F3),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('donations')
                                .where('status', isEqualTo: 'Available')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
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
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            debugPrint('No available donations found');
                            return Column(
                              children: [
                                _buildAvailableDonationsCard(0),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2D2D2D,
                                    ).withOpacity(0.7),
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

                          final donationDocs = snapshot.data!.docs;
                          debugPrint(
                            'Fetched ${donationDocs.length} available donations',
                          );

                          return FutureBuilder<List<Map<String, dynamic>>>(
                            future: Future.wait(
                              donationDocs.map((doc) async {
                                final data = doc.data() as Map<String, dynamic>;
                                final establishmentId =
                                    data['establishmentId'] as String?;
                                double distance = double.infinity;
                                if (establishmentId == null) {
                                  debugPrint(
                                    'No establishmentId for donation: ${doc.id}, data: $data',
                                  );
                                  return {'doc': doc, 'distance': distance};
                                }
                                final donorDoc =
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(establishmentId)
                                        .get();
                                if (!donorDoc.exists) {
                                  debugPrint(
                                    'Donor document not found for establishmentId: $establishmentId',
                                  );
                                  return {'doc': doc, 'distance': distance};
                                }
                                final donorData = donorDoc.data()!;
                                if (!donorData.containsKey('location')) {
                                  debugPrint(
                                    'No location field in donor document: $establishmentId, data: $donorData',
                                  );
                                  return {'doc': doc, 'distance': distance};
                                }
                                final locationData =
                                    donorData['location']
                                        as Map<String, dynamic>?;
                                if (locationData == null ||
                                    !locationData.containsKey('latitude') ||
                                    !locationData.containsKey('longitude')) {
                                  debugPrint(
                                    'Invalid location format for donor: $establishmentId, location: $locationData',
                                  );
                                  return {'doc': doc, 'distance': distance};
                                }
                                final latitude = locationData['latitude'];
                                final longitude = locationData['longitude'];
                                if (latitude is! num || longitude is! num) {
                                  debugPrint(
                                    'Non-numeric coordinates for donor: $establishmentId, latitude: $latitude, longitude: $longitude',
                                  );
                                  return {'doc': doc, 'distance': distance};
                                }
                                if (latitude.abs() > 90 ||
                                    longitude.abs() > 180) {
                                  debugPrint(
                                    'Invalid coordinates for donor: $establishmentId, latitude: $latitude, longitude: $longitude',
                                  );
                                  return {'doc': doc, 'distance': distance};
                                }
                                final donorLocation = LatLng(
                                  latitude.toDouble(),
                                  longitude.toDouble(),
                                );
                                distance = calculateDistance(
                                  acceptorLocation,
                                  donorLocation,
                                );
                                debugPrint(
                                  'Donation ${doc.id}: Donor $establishmentId at $donorLocation (lat: ${donorLocation.latitude}, lng: ${donorLocation.longitude}), distance: $distance km',
                                );
                                if (distance < 0) {
                                  debugPrint(
                                    'Negative distance detected for donation ${doc.id}: $distance km',
                                  );
                                }
                                return {'doc': doc, 'distance': distance};
                              }),
                            ),
                            builder: (context, futureSnapshot) {
                              if (futureSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF39FF14),
                                  ),
                                );
                              }
                              if (futureSnapshot.hasError) {
                                debugPrint(
                                  'Error processing distances: ${futureSnapshot.error}',
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
                                        'Error processing donations.',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: const Color(0xFFF9F7F3),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              final donationItems = futureSnapshot.data!;
                              // Filter donations within maxDistanceKm
                              final filteredDonations =
                                  donationItems
                                      .where(
                                        (item) =>
                                            item['distance'].isFinite &&
                                            item['distance'] <= maxDistanceKm,
                                      )
                                      .toList();
                              final invalidDistances =
                                  donationItems
                                      .where(
                                        (item) => !item['distance'].isFinite,
                                      )
                                      .length;

                              debugPrint(
                                'Filtered ${filteredDonations.length} donations within $maxDistanceKm km',
                              );
                              debugPrint(
                                'Excluded $invalidDistances donations with invalid distances',
                              );

                              if (filteredDonations.isEmpty) {
                                debugPrint(
                                  'No donations within range; maxDistanceKm: $maxDistanceKm',
                                );
                                return Column(
                                  children: [
                                    _buildAvailableDonationsCard(0),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF2D2D2D,
                                        ).withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'No donations available within ${maxDistanceKm.round()} km. Adjust your range in settings.',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: const Color(0xFFB0B0B0),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                children: [
                                  _buildAvailableDonationsCard(
                                    filteredDonations.length,
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: filteredDonations.length,
                                    itemBuilder: (context, index) {
                                      final item = filteredDonations[index];
                                      final doc =
                                          item['doc'] as DocumentSnapshot;
                                      final data =
                                          doc.data() as Map<String, dynamic>;
                                      final docId = doc.id;
                                      final timestamp =
                                          (data['createdAt'] as Timestamp)
                                              .toDate();
                                      final pickupTime =
                                          data['pickupTime'] as String;
                                      final distance =
                                          item['distance'] as double;
                                      debugPrint(
                                        'Displaying donation ${doc.id}: Distance=${distance.toStringAsFixed(1)} km',
                                      );
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2D2D2D),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
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
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                        0xFFF9F7F3,
                                                      ),
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Quantity: ${data['quantity']}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      color: const Color(
                                                        0xFFB0B0B0,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Posted: ${DateFormat('MMM dd, yyyy – HH:mm').format(timestamp)}',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: const Color(
                                                        0xFFB0B0B0,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Pickup Time: $pickupTime',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: const Color(
                                                        0xFFB0B0B0,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    distance.isFinite
                                                        ? 'Distance: ${distance.toStringAsFixed(1)} km'
                                                        : 'Distance: Unknown',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: const Color(
                                                        0xFF39FF14,
                                                      ),
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
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                              ),
                                              child: Text(
                                                'Request Claim',
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
