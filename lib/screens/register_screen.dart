import 'dart:async';
import 'dart:developer';
import 'package:church_member_app/screens/profile_screen.dart';
import 'package:church_member_app/screens/qr_scan_screen.dart';
import 'package:church_member_app/screens/success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';

class RegisterScreen extends StatefulWidget {
  final String token;
  const RegisterScreen({super.key, required this.token});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? data;
  bool loading = true;
  bool showPrayer = false;
  bool submitting = false;

  final prayerCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final fromCtrl = TextEditingController();
  final yearCtrl = TextEditingController();

  String memberType = 'regular';
  String attendingWith = 'alone';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    loadMetadata();
  }

  void loadMetadata() async {
    final authToken = await Storage.getToken();
    try {
      final result = await ApiService.fetchMetadata(widget.token, authToken!);

      setState(() {
        data = result;
        loading = false;
      });
      _animationController.forward();

      final profile = await ApiService.getProfile(authToken);

      final isProfileComplete = profile['full_name'] != null;

      if (!isProfileComplete) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const ProfileScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        setState(() {
          nameCtrl.text = profile['full_name'];
          fromCtrl.text = profile['coming_from'];
          yearCtrl.text = profile['since_year'].toString();
          memberType = profile['member_type'];
          attendingWith = profile['attending_with'];
        });
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().startsWith("Exception: ")
          ? e.toString().substring(11)
          : e.toString();

      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFF8B0000),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const QrScanScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    }
  }

  void submit() async {
    if (submitting) return;

    // Validate required fields
    if (nameCtrl.text.isEmpty) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please enter your full name');
      return;
    }

    if (fromCtrl.text.isEmpty) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please enter where you are coming from');
      return;
    }

    if (yearCtrl.text.isEmpty || int.tryParse(yearCtrl.text) == null) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please enter a valid year');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => submitting = true);
    final authToken = await Storage.getToken();
    try {
      await ApiService.saveProfile(
        nameCtrl.text,
        fromCtrl.text,
        int.parse(yearCtrl.text),
        memberType,
        attendingWith,
      );

      await ApiService.submitAttendance(
        data!['serviceId'],
        authToken!,
        prayerCtrl.text,
      );

      setState(() => submitting = false);
      HapticFeedback.selectionClick();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SuccessScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(position: offsetAnimation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
      final errorMessage = e.toString().startsWith("Exception: ")
          ? e.toString().substring(11)
          : e.toString();
      _showErrorDialog(errorMessage);
      setState(() => submitting = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => ScaleTransition(
        scale: CurvedAnimation(
          parent: ModalRoute.of(context)!.animation!,
          curve: Curves.easeOutBack,
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: const Text(
            'Submission Failed',
            style: TextStyle(
              color: Color(0xFF8B0000),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    prayerCtrl.dispose();
    nameCtrl.dispose();
    fromCtrl.dispose();
    yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F8F8), Color(0xFFE8E8E8), Color(0xFFF8F8F8)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: Color(0xFF8B0000),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Loading Event Details...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // derive a display value for the service code/name with sensible fallbacks
    final String serviceDisplay = (() {
      final d = data!;
      log(">>>>>> $data");

      if (d.containsKey('serviceName') && d['serviceName'] != null) {
        return d['serviceName'].toString();
      }
      if (d.containsKey('service_name') && d['service_name'] != null) {
        return d['service_name'].toString();
      }
      if (d.containsKey('serviceCode') && d['serviceCode'] != null) {
        return d['serviceCode'].toString();
      }
      if (d.containsKey('service_code') && d['service_code'] != null) {
        return d['service_code'].toString();
      }
      if (d['service'] is Map) {
        final s = d['service'] as Map<String, dynamic>;
        if (s.containsKey('name') && s['name'] != null)
          return s['name'].toString();
        if (s.containsKey('code') && s['code'] != null)
          return s['code'].toString();
      }
      return d['serviceId'].toString();
    })();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F8F8), Color(0xFFE8E8E8), Color(0xFFF8F8F8)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.black87,
                                  size: 24,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Image.asset(
                              'assets/images/lordsChurch.jpg',
                              fit: BoxFit.contain,
                              width: 50,
                              height: 50,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Event Details Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                  fontFamily: 'PlayfairDisplay',
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow(
                                Icons.event,
                                'Event',
                                data!['eventName'],
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.calendar_today,
                                'Date',
                                data!['eventDate'],
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.code,
                                'Service Code',
                                serviceDisplay,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                Icons.access_time,
                                'Time',
                                data!['serviceTime'],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Attendance Form Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                  fontFamily: 'PlayfairDisplay',
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Full Name Field
                              Text(
                                'Full Name',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black54,
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: nameCtrl,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    hintText: 'Enter your full name',
                                    hintStyle: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Coming From Field
                              Text(
                                'Coming From',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black54,
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: fromCtrl,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    hintText: 'City or Area',
                                    hintStyle: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Since Which Year Field
                              Text(
                                'Since Which Year',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black54,
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: yearCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    hintText: 'e.g., 2015',
                                    hintStyle: TextStyle(color: Colors.grey),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Member Type Dropdown
                              Text(
                                'Member Types',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black54,
                                    width: 1.5,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    value: memberType,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'guest',
                                        child: Text('Guest'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'regular',
                                        child: Text('Regular Member'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      HapticFeedback.selectionClick();
                                      setState(() => memberType = v!);
                                    },
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Attending With Dropdown
                              Text(
                                'Attending With',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black54,
                                    width: 1.5,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    value: attendingWith,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'alone',
                                        child: Text('Alone'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'family',
                                        child: Text('With Family'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'friends',
                                        child: Text('With Friends'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      HapticFeedback.selectionClick();
                                      setState(() => attendingWith = v!);
                                    },
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Prayer Request Toggle
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => showPrayer = !showPrayer);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_pin_circle_outlined,
                                            color: const Color(0xFF8B0000),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Add Prayer Request',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        transitionBuilder: (child, animation) =>
                                            RotationTransition(
                                              turns: animation,
                                              child: child,
                                            ),
                                        child: Icon(
                                          showPrayer
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: const Color(0xFF8B0000),
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Prayer Request TextField
                              if (showPrayer) ...[
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.black54,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: prayerCtrl,
                                    maxLines: 4,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(16),
                                      hintText:
                                          'Share your prayer request (optional)',
                                      hintStyle: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 32),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: submitting ? null : submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B0000),
                                    disabledBackgroundColor: Colors.grey[400],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AnimatedOpacity(
                                        opacity: submitting ? 0 : 1,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Confirm Attendance',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (submitting)
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Footer
                        Center(
                          child: Text(
                            'The Lords Church India © ${DateTime.now().year}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF8B0000), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
