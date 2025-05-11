import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ClaimUtils {
  static Future<void> acceptClaim(
    String docId,
    String itemName,
    BuildContext context,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Accept Claim for $itemName',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            content: Text(
              'Accepting this claim will share your name, phone number, and address with the acceptor. Proceed?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFB0B0B0),
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
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  foregroundColor: const Color(0xFF1A3C34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Accept',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        debugPrint('Attempting to accept claim for donation $docId');
        await FirebaseFirestore.instance
            .collection('donations')
            .doc(docId)
            .update({'claimStatus': 'accepted'});
        debugPrint('Successfully accepted claim for donation $docId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Accepted claim for $itemName',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1A3C34),
              ),
            ),
            backgroundColor: const Color(0xFF39FF14),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      } catch (e) {
        debugPrint('Error accepting claim for donation $docId: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to accept claim: $e',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            backgroundColor: const Color(0xFFFF4A4A),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
    }
  }

  static Future<void> rejectClaim(
    String docId,
    String itemName,
    BuildContext context,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Reject Claim for $itemName',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            content: Text(
              'Rejecting this claim will make the donation available again. Proceed?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFB0B0B0),
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
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4A4A),
                  foregroundColor: const Color(0xFFF9F7F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Reject',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        debugPrint('Attempting to reject claim for donation $docId');
        await FirebaseFirestore.instance
            .collection('donations')
            .doc(docId)
            .update({
              'status': 'Available',
              'acceptorId': null,
              'claimedAt': null,
              'claimStatus': 'rejected',
            });
        debugPrint('Successfully rejected claim for donation $docId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rejected claim for $itemName',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1A3C34),
              ),
            ),
            backgroundColor: const Color(0xFF39FF14),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      } catch (e) {
        debugPrint('Error rejecting claim for donation $docId: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to reject claim: $e',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFF9F7F3),
              ),
            ),
            backgroundColor: const Color(0xFFFF4A4A),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
      }
    }
  }
}
