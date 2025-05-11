import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AcceptorSettingsScreen extends StatefulWidget {
  const AcceptorSettingsScreen({super.key});

  @override
  _AcceptorSettingsScreenState createState() => _AcceptorSettingsScreenState();
}

class _AcceptorSettingsScreenState extends State<AcceptorSettingsScreen> {
  double _maxDistanceKm = 50;
  final TextEditingController _addressController = TextEditingController();
  LatLng? _selectedLocation;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _maxDistanceKm = (data['maxDistanceKm'] as num?)?.toDouble() ?? 50;
          if (data.containsKey('location')) {
            _selectedLocation = LatLng(
              (data['location']['latitude'] as num).toDouble(),
              (data['location']['longitude'] as num).toDouble(),
            );
            _getAddressFromLatLng(_selectedLocation!);
          }
        });
        debugPrint(
          'Loaded settings: maxDistanceKm=$_maxDistanceKm, location=$_selectedLocation',
        );
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address =
            '${placemark.street}, ${placemark.locality}, '
            '${placemark.administrativeArea} ${placemark.postalCode}';
        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
  }

  Future<void> _setLocationFromAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _selectedLocation = LatLng(location.latitude, location.longitude);
        });
        debugPrint('Location set: $_selectedLocation');
      } else {
        setState(() {
          _errorMessage = 'Could not find location for the provided address';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error finding location: $e';
      });
      debugPrint('Error geocoding address: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_selectedLocation == null) {
      setState(() {
        _errorMessage = 'Please set your location';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'maxDistanceKm': _maxDistanceKm,
          'location': {
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          },
        },
      );
      debugPrint(
        'Saved settings: maxDistanceKm=$_maxDistanceKm, location=$_selectedLocation',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Settings saved successfully!',
            style: GoogleFonts.inter(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF39FF14),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving settings: $e';
      });
      debugPrint('Error saving settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFFF9F7F3),
                            size: 28,
                          ),
                          onPressed: () {
                            debugPrint(
                              'Back button pressed on AcceptorSettingsScreen',
                            );
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Settings',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF9F7F3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your Location',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF9F7F3),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your address to set your location',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFB0B0B0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _addressController,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFFF9F7F3),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your address',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFFB0B0B0),
                          ),
                          prefixIcon: const Icon(
                            Icons.location_on,
                            color: Color(0xFF39FF14),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _setLocationFromAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF39FF14),
                          foregroundColor: const Color(0xFF1A3C34),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1A3C34),
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  'Set Location',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                        'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFB0B0B0),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Maximum Distance Range',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF9F7F3),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set the maximum distance for viewing sellers (1–500 km)',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFB0B0B0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbColor: const Color(0xFF39FF14),
                        activeTrackColor: const Color(0xFF39FF14),
                        inactiveTrackColor: const Color(
                          0xFFB0B0B0,
                        ).withOpacity(0.3),
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 16,
                        ),
                        valueIndicatorColor: const Color(0xFF39FF14),
                        valueIndicatorTextStyle: GoogleFonts.inter(
                          color: const Color(0xFF1A3C34),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Slider(
                        value: _maxDistanceKm,
                        min: 1,
                        max: 500,
                        divisions: 999,
                        label: '${_maxDistanceKm.round()} km',
                        onChanged: (value) {
                          setState(() {
                            _maxDistanceKm = value;
                          });
                          debugPrint('Distance slider changed to: $value km');
                        },
                      ),
                    ),
                    Text(
                      'Current range: ${_maxDistanceKm.round()} km',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF9F7F3),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4A4A).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF4A4A),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _errorMessage,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFF9F7F3),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF39FF14),
                          foregroundColor: const Color(0xFF1A3C34),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1A3C34),
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  'Save Settings',
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
        ],
      ),
    );
  }
}
