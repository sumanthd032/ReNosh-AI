import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';

class DonorLocationScreen extends StatefulWidget {
  final String address;

  const DonorLocationScreen({super.key, required this.address});

  @override
  _DonorLocationScreenState createState() => _DonorLocationScreenState();
}

class _DonorLocationScreenState extends State<DonorLocationScreen> {
  GoogleMapController? _controller;
  LatLng? _markerPosition;
  bool _isLoading = true;
  String _errorMessage = '';
  static const LatLng _fallbackPosition = LatLng(
    12.9716,
    77.5946,
  ); // Central Bangalore

  @override
  void initState() {
    super.initState();
    debugPrint(
      'Initializing DonorLocationScreen for address: ${widget.address}',
    );
    _geocodeAddress();
  }

  Future<void> _geocodeAddress() async {
    try {
      debugPrint('Attempting to geocode address: ${widget.address}');
      List<Location> locations = await locationFromAddress(widget.address);
      if (locations.isNotEmpty) {
        setState(() {
          _markerPosition = LatLng(
            locations.first.latitude,
            locations.first.longitude,
          );
          _isLoading = false;
        });
        debugPrint(
          'Successfully geocoded to: ${_markerPosition!.latitude}, ${_markerPosition!.longitude}',
        );
      } else {
        setState(() {
          _markerPosition = _fallbackPosition;
          _errorMessage =
              'Could not find location for the address. Showing default location.';
          _isLoading = false;
        });
        debugPrint(
          'No locations found for address: ${widget.address}. Using fallback: $_fallbackPosition',
        );
      }
    } catch (e) {
      setState(() {
        _markerPosition = _fallbackPosition;
        _errorMessage =
            'Error geocoding address: $e. Showing default location.';
        _isLoading = false;
      });
      debugPrint('Geocoding error: $e. Using fallback: $_fallbackPosition');
    }
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFFF9F7F3),
                          size: 28,
                        ),
                        onPressed: () {
                          debugPrint(
                            'Back button pressed on DonorLocationScreen',
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Donor Location',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF9F7F3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _isLoading
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF39FF14),
                            ),
                          )
                          : _markerPosition == null
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Failed to load location.',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: const Color(0xFFF9F7F3),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                      _errorMessage = '';
                                    });
                                    _geocodeAddress();
                                    debugPrint(
                                      'Retry geocoding address: ${widget.address}',
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF39FF14),
                                    foregroundColor: const Color(0xFF1A3C34),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Retry',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: _markerPosition!,
                                  zoom: 15,
                                ),
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('donor_location'),
                                    position: _markerPosition!,
                                    infoWindow: InfoWindow(
                                      title: widget.address,
                                    ),
                                  ),
                                },
                                onMapCreated: (controller) {
                                  _controller = controller;
                                  debugPrint(
                                    'Google Map created for address: ${widget.address}',
                                  );
                                },
                              ),
                              if (_errorMessage.isNotEmpty)
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFF4A4A,
                                      ).withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _errorMessage,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: const Color(0xFFF9F7F3),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.refresh,
                                            color: Color(0xFFF9F7F3),
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isLoading = true;
                                              _errorMessage = '';
                                            });
                                            _geocodeAddress();
                                            debugPrint(
                                              'Retry geocoding address: ${widget.address}',
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('Disposing DonorLocationScreen');
    _controller?.dispose();
    super.dispose();
  }
}
