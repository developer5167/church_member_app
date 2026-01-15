import 'dart:async';
import 'package:church_member_app/flavor/flavor_config.dart';
import 'package:church_member_app/screens/socialMediaCard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final nameCtrl = TextEditingController();
  final fromCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final baptisedYearCtrl = TextEditingController();

  String memberType = 'regular';
  String attendingWith = 'alone';
  String gender = 'male';
  bool baptised = false;
  bool loading = false;
  bool saving = false;
  bool isEditing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _loadProfile();
  }

  Future<void> _launchUrl(BuildContext context, String url, String platformName) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $platformName')));
    }
  }

  Future<void> _pickBaptisedYear() async {
    final currentYear = DateTime.now().year;
    final initialYear = baptisedYearCtrl.text.isNotEmpty ? int.tryParse(baptisedYearCtrl.text) ?? currentYear : currentYear;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedYear = initialYear;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Select Baptised Year'),
          content: SizedBox(
            height: 300,
            width: 300,
            child: YearPicker(
              firstDate: DateTime(1900),
              lastDate: DateTime(currentYear),
              initialDate: DateTime(initialYear),
              selectedDate: DateTime(selectedYear),
              onChanged: (DateTime dateTime) {
                selectedYear = dateTime.year;
                HapticFeedback.selectionClick();
                setState(() {
                  baptisedYearCtrl.text = selectedYear.toString();
                });
                Navigator.pop(context);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickComingFromYear() async {
    final currentYear = DateTime.now().year;
    final initialYear = yearCtrl.text.isNotEmpty ? int.tryParse(yearCtrl.text) ?? currentYear : currentYear;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedYear = initialYear;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Select Coming From Year'),
          content: SizedBox(
            height: 300,
            width: 300,
            child: YearPicker(
              firstDate: DateTime(1900),
              lastDate: DateTime(currentYear),
              initialDate: DateTime(initialYear),
              selectedDate: DateTime(selectedYear),
              onChanged: (DateTime dateTime) {
                selectedYear = dateTime.year;
                HapticFeedback.selectionClick();
                setState(() {
                  yearCtrl.text = selectedYear.toString();
                });
                Navigator.pop(context);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadProfile() async {
    setState(() => loading = true);

    try {
      final token = await Storage.getToken();
      if (token != null) {
        final profile = await ApiService.getProfile(token);

        if (profile.isNotEmpty) {
          setState(() {
            nameCtrl.text = profile['full_name'] ?? '';
            fromCtrl.text = profile['coming_from'] ?? '';
            yearCtrl.text = profile['since_year']?.toString() ?? '';
            memberType = profile['member_type'] ?? 'regular';
            attendingWith = profile['attending_with'] ?? 'alone';
            emailCtrl.text = profile['email'] ?? '';
            gender = profile['gender'] ?? 'male';
            baptised = profile['baptised'] ?? false;
            baptisedYearCtrl.text = profile['baptised_year'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
        _animationController.forward();
      }
    }
  }

  Future<void> saveProfile() async {
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

    final year = int.parse(yearCtrl.text);
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please enter a valid year between 1900 and $currentYear');
      return;
    }

    // Email validation
    if (emailCtrl.text.isEmpty) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please enter your email address');
      return;
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(emailCtrl.text)) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please enter a valid email address');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => saving = true);

    try {
      await ApiService.saveProfile(nameCtrl.text, fromCtrl.text, year, memberType, attendingWith, emailCtrl.text, gender, baptised, baptisedYearCtrl.text.isNotEmpty ? baptisedYearCtrl.text : null);

      HapticFeedback.selectionClick();

      // Show success and pop
      _showSuccessDialog('Profile saved successfully!', () {
        Navigator.pop(context);
      });
    } catch (e) {
      HapticFeedback.heavyImpact();
      final errorMessage = e.toString().startsWith("Exception: ") ? e.toString().substring(11) : e.toString();
      _showErrorDialog('Failed to save profile: $errorMessage');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => ScaleTransition(
        scale: CurvedAnimation(parent: ModalRoute.of(context)!.animation!, curve: Curves.easeOutBack),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text(
            'Validation Error',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FlavorConfig.instance.values.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message, VoidCallback onOk) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScaleTransition(
        scale: CurvedAnimation(parent: ModalRoute.of(context)!.animation!, curve: Curves.easeOutBack),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text(
            'Success!',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onOk();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FlavorConfig.instance.values.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
    nameCtrl.dispose();
    fromCtrl.dispose();
    yearCtrl.dispose();
    emailCtrl.dispose();
    baptisedYearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF8F8F8), Color(0xFFE8E8E8), Color(0xFFF8F8F8)]),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Header with edit action
                        Row(
                          children: [
                            if (!widget.embedded)
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
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1, offset: const Offset(0, 2))],
                                  ),
                                  child: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 24),
                                ),
                              )
                            else
                              const SizedBox(width: 40),
                          ],
                        ),


                        // Profile Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: FlavorConfig.instance.values.primaryColor.withOpacity(0.1),
                                    border: Border.all(color: Colors.grey, width: 1),
                                  ),
                                  child: Icon(Icons.person, size: 20, color: Colors.grey),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  nameCtrl.text.toUpperCase(),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[900], fontFamily: 'PlayfairDisplay', letterSpacing: 1.2),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => isEditing = true);
                              },
                              icon: Icon(Icons.edit, color: Colors.grey, size: 25),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Loading State
                        if (loading)
                          Column(
                            children: [
                              SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 4, color: FlavorConfig.instance.values.primaryColor)),
                              SizedBox(height: 10),
                              Text('Loading your profile...', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            ],
                          ),

                        if (!loading) ...[
                          // Profile Form Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 4))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personal Information',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800], fontFamily: 'PlayfairDisplay'),
                                ),

                                const SizedBox(height: 24),

                                // Full Name Field
                                Text(
                                  'Full Name',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black54, width: 1.5),
                                  ),
                                  child: TextField(
                                    controller: nameCtrl,
                                    enabled: isEditing,
                                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      hintText: 'Enter your full name',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      prefixIcon: Icon(Icons.person_outline, color: Color(0xFF8B0000)),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Coming From Field
                                Text(
                                  'Coming From',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black54, width: 1.5),
                                  ),
                                  child: TextField(
                                    controller: fromCtrl,
                                    enabled: isEditing,
                                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      hintText: 'City or area you are coming from',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      prefixIcon: Icon(Icons.location_on_outlined, color: Color(0xFF8B0000)),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Since Which Year Field
                                Text(
                                  'Since Which Year',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: isEditing ? _pickComingFromYear : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black54, width: 1.5),
                                    ),
                                    child: AbsorbPointer(
                                      child: TextField(
                                        controller: yearCtrl,
                                        enabled: isEditing,
                                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          hintText: 'Select year',
                                          hintStyle: const TextStyle(color: Colors.grey),
                                          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF8B0000)),
                                          suffixIcon: Icon(Icons.arrow_drop_down, color: isEditing ? Colors.black54 : Colors.grey[300]),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),
                                Text('Year you started attending this church', style: TextStyle(fontSize: 12, color: Colors.grey[500])),

                                const SizedBox(height: 24),

                                // Email Field
                                Text(
                                  'Email Address',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black54, width: 1.5),
                                  ),
                                  child: TextField(
                                    controller: emailCtrl,
                                    enabled: isEditing,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      hintText: 'Enter your email address',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF8B0000)),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Gender Dropdown
                                Text(
                                  'Gender',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black54, width: 1.5),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButtonFormField<String>(
                                      value: gender,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'male',
                                          child: Row(
                                            children: [
                                              Icon(Icons.male, color: Colors.blue, size: 20),
                                              SizedBox(width: 12),
                                              Text('Male'),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'female',
                                          child: Row(
                                            children: [
                                              Icon(Icons.female, color: Colors.pink, size: 20),
                                              SizedBox(width: 12),
                                              Text('Female'),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'others',
                                          child: Row(
                                            children: [
                                              Icon(Icons.person, color: Colors.purple, size: 20),
                                              SizedBox(width: 12),
                                              Text('Others'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: isEditing
                                          ? (v) {
                                              HapticFeedback.selectionClick();
                                              setState(() => gender = v!);
                                            }
                                          : null,
                                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Baptised Dropdown
                                Text(
                                  'Baptised',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black54, width: 1.5),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButtonFormField<bool>(
                                      value: baptised,
                                      items: const [
                                        DropdownMenuItem(
                                          value: true,
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.green, size: 20),
                                              SizedBox(width: 12),
                                              Text('Yes'),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: false,
                                          child: Row(
                                            children: [
                                              Icon(Icons.cancel, color: Colors.red, size: 20),
                                              SizedBox(width: 12),
                                              Text('No'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: isEditing
                                          ? (v) {
                                              HapticFeedback.selectionClick();
                                              setState(() => baptised = v!);
                                            }
                                          : null,
                                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Baptised Year Field (Optional)
                                Text(
                                  'Baptised Year (Optional)',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: isEditing ? _pickBaptisedYear : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black54, width: 1.5),
                                    ),
                                    child: AbsorbPointer(
                                      child: TextField(
                                        controller: baptisedYearCtrl,
                                        enabled: false,
                                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          hintText: 'Select baptised year',
                                          hintStyle: const TextStyle(color: Colors.grey),
                                          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF8B0000)),
                                          suffixIcon: Icon(Icons.arrow_drop_down, color: isEditing ? Colors.black54 : Colors.grey[300]),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Member Type Dropdown
                                Text(
                                  'Member Type',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black54, width: 1.5),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButtonFormField<String>(
                                      value: memberType,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'guest',
                                          child: Row(
                                            children: [
                                              Icon(Icons.person_outline, color: Colors.blue, size: 20),
                                              SizedBox(width: 12),
                                              Text('Guest'),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'regular',
                                          child: Row(
                                            children: [
                                              Icon(Icons.person, color: Color(0xFF8B0000), size: 20),
                                              SizedBox(width: 12),
                                              Text('Regular(Lords Church Member)'),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'online viewer',
                                          child: Row(
                                            children: [
                                              Icon(Icons.online_prediction, color: Color(0xFFFF0000), size: 20),
                                              SizedBox(width: 12),
                                              Text('Online Viewer'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        HapticFeedback.selectionClick();
                                        setState(() => memberType = v!);
                                      },
                                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Attending With Dropdown
                                Text(
                                  'Attending With',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black54, width: 1.5),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButtonFormField<String>(
                                      value: attendingWith,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'alone',
                                          child: Row(
                                            children: [
                                              Icon(Icons.person_outline, color: Colors.grey, size: 20),
                                              SizedBox(width: 12),
                                              Text('Alone'),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'family',
                                          child: Row(
                                            children: [
                                              Icon(Icons.family_restroom, color: Colors.green, size: 20),
                                              SizedBox(width: 12),
                                              Text('With Family'),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'friends',
                                          child: Row(
                                            children: [
                                              Icon(Icons.group, color: Colors.orange, size: 20),
                                              SizedBox(width: 12),
                                              Text('With Friends'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        HapticFeedback.selectionClick();
                                        setState(() => attendingWith = v!);
                                      },
                                      decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Save Profile Button (visible only when editing)
                                if (isEditing)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: saving ? null : saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: FlavorConfig.instance.values.primaryColor,
                                        disabledBackgroundColor: Colors.grey[400],
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          AnimatedOpacity(
                                            opacity: saving ? 0 : 1,
                                            duration: const Duration(milliseconds: 200),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.save, color: Colors.white, size: 22),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Update Profile',
                                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (saving) SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white.withOpacity(0.9))),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Information Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B0000).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF8B0000).withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Color(0xFF8B0000), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Why we need this information?',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Your profile information helps us provide better personalized service, track attendance accurately, and understand our church community better.', style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Join our channels
                          // SocialMedia(context),
                          Text(
                            'Follow us on our social media platforms',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 180,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _buildSocialCard(icon: FontAwesomeIcons.facebook, iconColor: const Color(0xFF436BFF), platform: 'Facebook', account: 'Raj Prakash Paul', onTap: () => _launchUrl(context, 'https://www.facebook.com/rajprakashpaul', 'Facebook')),
                                const SizedBox(width: 12),
                                _buildSocialCard(icon: FontAwesomeIcons.whatsapp, iconColor: const Color(0xFF25D366), platform: 'WhatsApp', account: 'Raj Prakash Paul', onTap: () => _launchUrl(context, 'https://whatsapp.com/channel/0029ValI9TD9cDDT6ArJVJ30', 'WhatsApp')),
                                const SizedBox(width: 12),
                                _buildSocialCard(icon: FontAwesomeIcons.whatsapp, iconColor: const Color(0xFF25D366), platform: 'WhatsApp', account: 'Jessy Paul', onTap: () => _launchUrl(context, 'https://whatsapp.com/channel/0029Vb0YkfqDeON0u7PWXY1G', 'WhatsApp')),
                                const SizedBox(width: 12),
                                _buildSocialCard(icon: FontAwesomeIcons.instagram, iconColor: const Color(0xFFE4405F), platform: 'Instagram', account: 'Jessy Paul', onTap: () => _launchUrl(context, 'https://www.instagram.com/jessypauln', 'Instagram')),
                                const SizedBox(width: 12),
                                _buildSocialCard(icon: FontAwesomeIcons.instagram, iconColor: const Color(0xFFE4405F), platform: 'Instagram', account: 'Raj Prakash Paul', onTap: () => _launchUrl(context, 'https://www.instagram.com/rajprakashpaul', 'Instagram')),
                                const SizedBox(width: 12),
                                _buildSocialCard(icon: FontAwesomeIcons.spotify, iconColor: const Color(0xFFE4405F), platform: 'Instagram', account: 'The Lords Church', onTap: () => _launchUrl(context, 'https://www.instagram.com/thelordschurchindia', 'Instagram')),
                                const SizedBox(width: 12),
                                _buildSocialCard(icon: FontAwesomeIcons.spotify, iconColor: const Color(0xFF1DB954), platform: 'Spotify', account: 'Raj Prakash Paul', onTap: () => _launchUrl(context, 'https://open.spotify.com/artist/5pCZk4EhxyQ17HZS5Vom2e', 'Spotify')),
                                const SizedBox(width: 12),
                                _buildSocialCard(icon: FontAwesomeIcons.youtube, iconColor: const Color(0xFFE10303), platform: 'Youtube', account: 'Raj Prakash Paul', onTap: () => _launchUrl(context, 'https://www.youtube.com/channel/UCFyCGU7WW2BFPMO9eBKD8XQ', 'Youtube')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Footer
                          Center(
                            child: Text('The Lords Church India © ${DateTime.now().year}', style: TextStyle(color: Colors.grey[500], fontSize: 12, letterSpacing: 0.5)),
                          ),
                        ],
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
}

Widget _buildSocialCard({required IconData icon, required Color iconColor, required String platform, required String account, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            platform,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          Text(
            account,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Text(
                  'Follow',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: iconColor),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 12, color: iconColor),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
