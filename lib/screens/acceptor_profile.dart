import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AcceptorProfile extends StatelessWidget {
  const AcceptorProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3C34),
      appBar: AppBar(
        title: Text(
          'Acceptor Profile',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFF9F7F3)),
        ),
        backgroundColor: const Color(0xFF2D2D2D),
      ),
      body: Center(
        child: Text(
          'Acceptor Profile Placeholder\nTo show acceptor details and settings',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 18,
            color: const Color(0xFFF9F7F3),
          ),
        ),
      ),
    );
  }
}