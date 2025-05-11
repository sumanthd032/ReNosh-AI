import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show HttpException, Platform, SocketException;
import 'package:flutter/foundation.dart' show compute;

class Constants {
  static const String apiBaseUrl = 'https://renosh-api.onrender.com';
  static const Map<String, int> defaultPredictions = {
    'Butter Chicken': 120,
    'Paneer Tikka': 150,
    'Dal Makhani': 100,
    'Naan': 200,
  };
  static const Color primaryColor = Color(0xFF39FF14);
  static const Color backgroundColor = Color(0xFF1A3C34);
  static const Color errorColor = Color(0xFFFF4A4A);
  static const Color textColor = Color(0xFFF9F7F3);
  static const Color secondaryTextColor = Color(0xFFB0B0B0);
}

class EstablishmentDashboard extends StatefulWidget {
  const EstablishmentDashboard({super.key});

  @override
  State<EstablishmentDashboard> createState() => _EstablishmentDashboardState();
}

class _EstablishmentDashboardState extends State<EstablishmentDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  String? _establishmentName;
  bool _isLoading = true;
  String _greeting = '';
  bool _isPredictionsLoading = false;
  Map<String, int>? _predictions;
  Map<String, int>? _yesterdayPredictions;
  String? _predictionsError;
  Map<String, int>? _lastSuccessfulPredictions;
  bool _isOffline = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  List<String> _aiInsights = [];
  bool _isFetchingInsights = false;
  List<Map<String, dynamic>> _sustainabilityData = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.4).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _glowController.repeat(reverse: true);
      }
    });
    _setGreeting();
    _fetchUserData();
    _fetchPredictions();
    _clearOldCache();
    _fetchSustainabilityData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _clearOldCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final now = DateTime.now();
    for (final key in keys) {
      if (key.startsWith('predictions_date_') ||
          key.startsWith('predictions_data_') ||
          key.startsWith('last_server_update_')) {
        final dateStr = key.split('_').last;
        try {
          final date = DateTime.parse(dateStr);
          if (now.difference(date).inDays > 7) {
            await prefs.remove(key);
          }
        } catch (e) {
          debugPrint('Failed to parse date in cache key $key: $e');
        }
      }
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Please log in to continue.');
        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()!['role'] == 'Food Establishment') {
        setState(() {
          _establishmentName = doc.data()!['name'];
          _isLoading = false;
        });
        _fetchAIInsights();
      } else {
        _showErrorSnackBar('Invalid account type. Please contact support.');
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar('Authentication error: ${e.message}');
      setState(() => _isLoading = false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on FirebaseException catch (e) {
      _showErrorSnackBar('Database error: ${e.message}');
      setState(() => _isLoading = false);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred. Please try again.');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSustainabilityData() async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: 7));
      final querySnapshot = await FirebaseFirestore.instance
          .collection('sustainability_metrics')
          .where('date',
              isGreaterThanOrEqualTo: startDate.toIso8601String().split('T')[0])
          .where('date',
              isLessThanOrEqualTo: now.toIso8601String().split('T')[0])
          .orderBy('date', descending: false)
          .get();

      List<Map<String, dynamic>> data = [];
      for (var doc in querySnapshot.docs) {
        data.add({
          'date': doc['date'],
          'meals_donated': doc['meals_donated']?.toDouble() ?? 0.0,
          'food_saved_kg': doc['food_saved_kg']?.toDouble() ?? 0.0,
          'waste_reduced_kg': doc['waste_reduced_kg']?.toDouble() ?? 0.0,
          'ai_optimized_waste_reduced_kg':
              doc['ai_optimized_waste_reduced_kg']?.toDouble() ?? 0.0,
        });
      }

      // Simulated data for demonstration if Firestore data is unavailable
      if (data.isEmpty) {
        data = [
          {'date': '2025-05-05', 'meals_donated': 40.0, 'food_saved_kg': 8.0, 'waste_reduced_kg': 5.0, 'ai_optimized_waste_reduced_kg': 2.0},
          {'date': '2025-05-06', 'meals_donated': 45.0, 'food_saved_kg': 9.0, 'waste_reduced_kg': 6.0, 'ai_optimized_waste_reduced_kg': 2.5},
          {'date': '2025-05-07', 'meals_donated': 50.0, 'food_saved_kg': 10.0, 'waste_reduced_kg': 5.5, 'ai_optimized_waste_reduced_kg': 2.2},
          {'date': '2025-05-08', 'meals_donated': 55.0, 'food_saved_kg': 11.0, 'waste_reduced_kg': 6.5, 'ai_optimized_waste_reduced_kg': 3.0},
          {'date': '2025-05-09', 'meals_donated': 60.0, 'food_saved_kg': 12.0, 'waste_reduced_kg': 7.0, 'ai_optimized_waste_reduced_kg': 3.5},
          {'date': '2025-05-10', 'meals_donated': 65.0, 'food_saved_kg': 13.0, 'waste_reduced_kg': 6.8, 'ai_optimized_waste_reduced_kg': 3.2},
          {'date': '2025-05-11', 'meals_donated': 70.0, 'food_saved_kg': 14.0, 'waste_reduced_kg': 7.2, 'ai_optimized_waste_reduced_kg': 3.8},
        ];
      }

      setState(() {
        _sustainabilityData = data;
      });
    } catch (e) {
      debugPrint('Error fetching sustainability data: $e');
      setState(() {
        _sustainabilityData = [
          {'date': '2025-05-05', 'meals_donated': 40.0, 'food_saved_kg': 8.0, 'waste_reduced_kg': 5.0, 'ai_optimized_waste_reduced_kg': 2.0},
          {'date': '2025-05-06', 'meals_donated': 45.0, 'food_saved_kg': 9.0, 'waste_reduced_kg': 6.0, 'ai_optimized_waste_reduced_kg': 2.5},
          {'date': '2025-05-07', 'meals_donated': 50.0, 'food_saved_kg': 10.0, 'waste_reduced_kg': 5.5, 'ai_optimized_waste_reduced_kg': 2.2},
          {'date': '2025-05-08', 'meals_donated': 55.0, 'food_saved_kg': 11.0, 'waste_reduced_kg': 6.5, 'ai_optimized_waste_reduced_kg': 3.0},
          {'date': '2025-05-09', 'meals_donated': 60.0, 'food_saved_kg': 12.0, 'waste_reduced_kg': 7.0, 'ai_optimized_waste_reduced_kg': 3.5},
          {'date': '2025-05-10', 'meals_donated': 65.0, 'food_saved_kg': 13.0, 'waste_reduced_kg': 6.8, 'ai_optimized_waste_reduced_kg': 3.2},
          {'date': '2025-05-11', 'meals_donated': 70.0, 'food_saved_kg': 14.0, 'waste_reduced_kg': 7.2, 'ai_optimized_waste_reduced_kg': 3.8},
        ];
      });
    }
  }

  Future<void> _fetchAIInsights() async {
    setState(() {
      _isFetchingInsights = true;
    });

    try {
      // Simulate fetching surplus items count
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final surplusSnapshot = await FirebaseFirestore.instance
          .collection('food_tracking')
          .where('establishmentId', isEqualTo: user.uid)
          .where('quantity_surplus', isGreaterThan: 0)
          .get();
      final surplusCount = surplusSnapshot.docs.length;

      // Prepare prompt data
      final promptData = {
        'today_date': 'May 11, 2025 (Sunday)',
        'today_predictions': _predictions ?? Constants.defaultPredictions,
        'yesterday_predictions': _yesterdayPredictions ?? Constants.defaultPredictions,
        'surplus_items_count': surplusCount,
      };

      // Simulated Gemini API call
      // In a real scenario, you would make an HTTP request to the Gemini API endpoint
      // For now, we use the simulated response based on the prompt
      List<String> insights = [
        'Increase Butter Chicken preparation by 10% (130 to 143) to meet Sunday demand spike.',
        'Donate 5 extra Paneer Tikka portions today, as surplus risk is high with only 1 surplus item.',
        'Reduce Dal Makhani preparation by 5% (110 to 105) to avoid waste, based on yesterday’s trend.',
        'Promote Naan with a combo offer; demand rose 10% from yesterday to 220.',
      ];

      setState(() {
        _aiInsights = insights;
        _isFetchingInsights = false;
      });
    } catch (e) {
      debugPrint('Error fetching AI insights: $e');
      setState(() {
        _aiInsights = [
          'Optimize inventory based on recent trends.',
          'Consider donating surplus to reduce waste.',
          'Adjust preparation for high-demand items.',
        ];
        _isFetchingInsights = false;
      });
    }
  }

  static Future<Map<String, dynamic>> _fetchPredictionsIsolate(String date) async {
    try {
      final urlCheck = Uri.parse('${Constants.apiBaseUrl}/last-update');
      final checkResponse = await http
          .get(urlCheck)
          .timeout(const Duration(seconds: 15));
      String serverLastUpdate = checkResponse.statusCode == 200
          ? jsonDecode(checkResponse.body)['lastUpdate']
          : 'unknown';

      final url = Uri.parse('${Constants.apiBaseUrl}/predict');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'date': date}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'predictions': data.map((key, value) => MapEntry(key, value as int)),
          'error': null,
          'isOffline': false,
          'serverLastUpdate': serverLastUpdate,
        };
      } else {
        throw HttpException('API returned status code ${response.statusCode}');
      }
    } on TimeoutException {
      return _handleFallback('API timed out', date);
    } on SocketException {
      return _handleFallback('No internet connection', date);
    } on HttpException catch (e) {
      return _handleFallback('Server error: $e', date);
    } catch (e) {
      return _handleFallback('Unexpected error: $e', date);
    }
  }

  static Future<Map<String, dynamic>> _handleFallback(String error, String date) async {
    return {
      'predictions': Constants.defaultPredictions,
      'error': error,
      'isOffline': true,
      'serverLastUpdate': 'unknown',
    };
  }

  Future<void> _fetchPredictions({String? date}) async {
    if (_retryCount >= _maxRetries) {
      setState(() {
        _predictionsError = 'Max retries reached. Using cached or fallback data.';
        _isPredictionsLoading = false;
        _isOffline = true;
      });
      return;
    }

    setState(() {
      _isPredictionsLoading = true;
      _predictionsError = null;
    });

    final targetDate = date ?? DateTime.now().toIso8601String().split('T')[0];
    final yesterday = DateTime.now().subtract(Duration(days: 1)).toIso8601String().split('T')[0];
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString('predictions_date_$targetDate');
    final cachedPredictions = prefs.getString('predictions_data_$targetDate');
    final lastUpdate = prefs.getString('last_server_update_$targetDate');

    if (cachedDate == targetDate && cachedPredictions != null) {
      try {
        final checkResponse = await http
            .get(Uri.parse('${Constants.apiBaseUrl}/last-update'))
            .timeout(const Duration(seconds: 15));
        final serverLastUpdate = checkResponse.statusCode == 200
            ? jsonDecode(checkResponse.body)['lastUpdate']
            : 'unknown';
        if (lastUpdate == serverLastUpdate) {
          setState(() {
            _predictions = Map<String, int>.from(jsonDecode(cachedPredictions));
            _isPredictionsLoading = false;
            _isOffline = false;
            _retryCount = 0;
          });
          _fetchAIInsights(); // Refresh insights after predictions update
          return;
        }
      } catch (e) {
        debugPrint('Failed to check server update: $e');
      }
    }

    final startTime = DateTime.now();
    try {
      final result = await compute(_fetchPredictionsIsolate, targetDate);
      final duration = DateTime.now().difference(startTime).inSeconds;
      debugPrint('API response for $targetDate took $duration seconds');

      if (result['error'] == null) {
        await prefs.setString('predictions_date_$targetDate', targetDate);
        await prefs.setString('predictions_data_$targetDate', jsonEncode(result['predictions']));
        await prefs.setString('last_successful_predictions', jsonEncode(result['predictions']));
        await prefs.setString('last_server_update_$targetDate', result['serverLastUpdate']);
      }

      setState(() {
        _predictions = result['predictions'];
        _predictionsError = result['error'];
        _lastSuccessfulPredictions = result['error'] == null ? result['predictions'] : _lastSuccessfulPredictions;
        _isOffline = result['isOffline'];
        _isPredictionsLoading = false;
        _retryCount = 0;
      });
      _fetchAIInsights(); // Refresh insights after predictions update

      if (date == null) {
        final yesterdayResult = await compute(_fetchPredictionsIsolate, yesterday);
        if (yesterdayResult['error'] == null) {
          await prefs.setString('predictions_date_$yesterday', yesterday);
          await prefs.setString('predictions_data_$yesterday', jsonEncode(yesterdayResult['predictions']));
          await prefs.setString('last_server_update_$yesterday', yesterdayResult['serverLastUpdate']);
        }
        setState(() {
          _yesterdayPredictions = yesterdayResult['predictions'];
        });
        _fetchAIInsights(); // Refresh insights after yesterday's predictions update

        final lastPreload = prefs.getString('last_preload_time');
        final now = DateTime.now();
        if (lastPreload == null || now.difference(DateTime.parse(lastPreload)).inHours >= 24) {
          final nextDay = DateTime.now().add(Duration(days: 1)).toIso8601String().split('T')[0];
          compute(_fetchPredictionsIsolate, nextDay).then((result) {
            debugPrint('Preloaded predictions for $nextDay');
            if (result['error'] == null) {
              prefs.setString('predictions_date_$nextDay', nextDay);
              prefs.setString('predictions_data_$nextDay', jsonEncode(result['predictions']));
              prefs.setString('last_server_update_$nextDay', result['serverLastUpdate']);
            }
            prefs.setString('last_preload_time', now.toIso8601String());
          });
        }
      }
    } catch (e) {
      setState(() {
        _predictionsError = 'Failed to fetch predictions: $e';
        _isPredictionsLoading = false;
        _isOffline = true;
        _retryCount++;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Constants.textColor,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Constants.errorColor,
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
            color: Constants.textColor,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Constants.primaryColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showPredictionsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2D2D2D),
                    Constants.backgroundColor.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(4, 4),
                  ),
                  BoxShadow(
                    color: Constants.textColor.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(-4, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Constants.primaryColor.withOpacity(0.3),
                          Constants.backgroundColor.withOpacity(0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Today\'s AI Predictions',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Constants.textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            if (_isOffline)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(
                                  Icons.cloud_off,
                                  color: Constants.secondaryTextColor,
                                  size: 24,
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: Constants.primaryColor,
                                size: 24,
                              ),
                              onPressed: _isPredictionsLoading
                                  ? null
                                  : () {
                                      _fetchPredictions();
                                    },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Constants.textColor,
                                size: 24,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isPredictionsLoading)
                    Column(
                      children: [
                        Center(
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              color: Constants.primaryColor,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fetching predictions... This may take up to 30 seconds.',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Constants.secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else if (_predictionsError != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Constants.errorColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Constants.errorColor.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Constants.errorColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _predictionsError!,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Constants.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'The API may take up to 30 seconds to respond due to server startup.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Constants.secondaryTextColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else if (_predictions == null || _predictions!.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Constants.secondaryTextColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No predictions available for today.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Constants.secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _predictions!.length,
                        itemBuilder: (context, index) {
                          final dish = _predictions!.keys.elementAt(index);
                          final quantity = _predictions![dish]!;
                          final yesterdayQuantity = _yesterdayPredictions != null &&
                                  _yesterdayPredictions!.containsKey(dish)
                              ? _yesterdayPredictions![dish]!
                              : null;
                          IconData? trendIcon;
                          Color? trendColor;
                          if (yesterdayQuantity != null) {
                            if (quantity > yesterdayQuantity) {
                              trendIcon = Icons.trending_up;
                              trendColor = Constants.primaryColor;
                            } else if (quantity < yesterdayQuantity) {
                              trendIcon = Icons.trending_down;
                              trendColor = Constants.errorColor;
                            } else {
                              trendIcon = Icons.trending_flat;
                              trendColor = Constants.secondaryTextColor;
                            }
                          }

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF2D2D2D).withOpacity(0.9),
                                  Constants.backgroundColor.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                                BoxShadow(
                                  color: Constants.primaryColor.withOpacity(0.05),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                              border: Border.all(
                                color: Constants.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Constants.primaryColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.restaurant_menu,
                                    color: Constants.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              dish,
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Constants.textColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (trendIcon != null)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: Icon(
                                                trendIcon,
                                                color: trendColor,
                                                size: 20,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Predicted: $quantity ${quantity == 1 ? 'item' : 'items'}',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: Constants.secondaryTextColor,
                                        ),
                                      ),
                                      if (yesterdayQuantity != null)
                                        Text(
                                          'Yesterday: $yesterdayQuantity ${yesterdayQuantity == 1 ? 'item' : 'items'}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Constants.secondaryTextColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(seconds: 5),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 2,
                      colors: [
                        Constants.primaryColor.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsightsCard() {
    return GestureDetector(
      onTap: () {
        if (Platform.isAndroid || Platform.isIOS) {
          HapticFeedback.lightImpact();
        }
        _showSuccessSnackBar('AI Insights refreshed!');
        _fetchAIInsights();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2D2D2D),
              Constants.backgroundColor.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
            BoxShadow(
              color: Constants.textColor.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(-4, -4),
            ),
            BoxShadow(
              color: Constants.primaryColor.withOpacity(0.2),
              blurRadius: 12,
            ),
          ],
          border: Border.all(color: Constants.primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Constants.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Constants.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isFetchingInsights)
              Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Constants.primaryColor,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_aiInsights.isEmpty)
              Text(
                'No insights available. Tap to refresh.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Constants.secondaryTextColor,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _aiInsights.map((insight) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Constants.textColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            insight,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Constants.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            Text(
              'Powered by ReNosh AI (Gemini + AutoML)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Constants.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSustainabilityCharts() {
    if (_sustainabilityData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2D2D2D),
              Constants.backgroundColor.withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
            BoxShadow(
              color: Constants.textColor.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(-4, -4),
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              color: Constants.primaryColor,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    // Prepare data for charts
    final mealsDonatedData = _sustainabilityData.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value['meals_donated'],
            color: Constants.primaryColor,
          ),
        ],
      );
    }).toList();

    final foodSavedData = _sustainabilityData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value['food_saved_kg']);
    }).toList();

    final totalWasteReduced = _sustainabilityData.fold<double>(0, (sum, item) => sum + item['waste_reduced_kg']);
    final totalAIWasteReduced = _sustainabilityData.fold<double>(0, (sum, item) => sum + item['ai_optimized_waste_reduced_kg']);
    final standardWasteReduced = totalWasteReduced - totalAIWasteReduced;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D2D2D),
            Constants.backgroundColor.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: Constants.textColor.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sustainability Tracking',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Constants.textColor,
            ),
          ),
          const SizedBox(height: 16),
          CarouselSlider(
            options: CarouselOptions(
              height: 200,
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 2.0,
              viewportFraction: 0.8,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              enableInfiniteScroll: true,
            ),
            items: [
              _buildChartCard(
                title: 'Meals Donated (Last 7 Days)',
                chart: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < _sustainabilityData.length) {
                              final date = _sustainabilityData[index]['date'].split('-').last;
                              return SideTitleWidget(
                                child: Text(
                                  date,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Constants.secondaryTextColor,
                                  ),
                                ),
                                meta: meta,
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles:SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: mealsDonatedData,
                  ),
                ),
              ),
              _buildChartCard(
                title: 'Food Saved (kg, Last 7 Days)',
                chart: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < _sustainabilityData.length) {
                              final date = _sustainabilityData[index]['date'].split('-').last;
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  date,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Constants.secondaryTextColor,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: foodSavedData,
                        isCurved: true,
                        color: Constants.primaryColor,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              _buildChartCard(
                title: 'Waste Reduction Impact',
                chart: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: totalAIWasteReduced,
                        color: Constants.primaryColor,
                        title: 'AI-Optimized',
                        titleStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: Constants.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      PieChartSectionData(
                        value: standardWasteReduced,
                        color: Constants.secondaryTextColor,
                        title: 'Standard',
                        titleStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: Constants.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget chart}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Constants.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SizedBox(height: 120, child: chart),
        ],
      ),
    );
  }

  Widget _buildSurplusItems() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D).withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Constants.secondaryTextColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Please log in to view surplus items.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Constants.secondaryTextColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2D2D2D),
            Constants.backgroundColor.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: Constants.textColor.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Surplus Items',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Constants.textColor,
            ),
          ),
          const SizedBox(height: 4),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('food_tracking')
                .where('establishmentId', isEqualTo: user.uid)
                .where('quantity_surplus', isGreaterThan: 0)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      color: Constants.primaryColor,
                      strokeWidth: 2.5,
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                debugPrint('Surplus query error: ${snapshot.error}');
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Constants.errorColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Constants.errorColor.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Constants.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failed to load surplus items. Please try again later.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Constants.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                debugPrint('No surplus items found for user: ${user.uid}');
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Constants.secondaryTextColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No surplus items found. Try adding some in Food Track.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Constants.secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              debugPrint('Found ${snapshot.data!.docs.length} surplus items');
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final item = doc['item_name'] as String;
                  final quantity = doc['quantity_surplus'] as int;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/surplus_details',
                        arguments: {
                          'itemName': item,
                          'quantity': quantity,
                          'docId': doc.id,
                        },
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                          BoxShadow(
                            color: Constants.primaryColor.withOpacity(0.05),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(
                          color: Constants.primaryColor.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Constants.primaryColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.restaurant_menu,
                              color: Constants.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Constants.textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Surplus: $quantity ${quantity == 1 ? 'item' : 'items'}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Constants.secondaryTextColor,
                                  ),
                                ),
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
    );
  }

  Widget _buildOfflineBanner() {
    if (!_isOffline) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Constants.errorColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Constants.errorColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Constants.errorColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline mode: Using cached data. Please check your connection.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Constants.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? topPrediction;
    int? topQuantity;
    if (_predictions != null && _predictions!.isNotEmpty) {
      final sortedPredictions = _predictions!.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topPrediction = sortedPredictions.first.key;
      topQuantity = sortedPredictions.first.value;
    }

    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Constants.backgroundColor.withOpacity(0.95),
                  const Color(0xFF2D2D2D).withOpacity(0.85),
                ],
              ),
            ),
          ),
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: Constants.primaryColor),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOfflineBanner(),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Image.asset(
                              'assets/logo.jpg',
                              width: 80,
                              height: 80,
                              semanticLabel: 'ReNosh Logo',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          '$_greeting, ${_establishmentName ?? 'Loading...'}!',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Constants.textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your surplus and track sustainability',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Constants.secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildAIInsightsCard(),
                      const SizedBox(height: 24),
                      _buildSustainabilityCharts(),
                      const SizedBox(height: 24),
                      _buildSurplusItems(),
                      const SizedBox(height: 24),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            if (Platform.isAndroid || Platform.isIOS) {
                              HapticFeedback.lightImpact();
                            }
                            _showPredictionsDialog();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Constants.primaryColor.withOpacity(0.9),
                                  Constants.backgroundColor.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Constants.primaryColor.withOpacity(_glowAnimation.value),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Constants.primaryColor.withOpacity(0.5),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.insights,
                                      color: Constants.textColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Predictions of the Day',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Constants.textColor,
                                      ),
                                    ),
                                    if (_isPredictionsLoading) ...[
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Constants.textColor,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (_isPredictionsLoading)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    height: 16,
                                    width: 150,
                                    decoration: BoxDecoration(
                                      color: Constants.secondaryTextColor.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  )
                                else if (topPrediction != null && topQuantity != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Top: $topPrediction ($topQuantity items)',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Constants.secondaryTextColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}