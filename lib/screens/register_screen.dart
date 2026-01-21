import 'dart:async';
import 'dart:developer';
import 'package:church_member_app/screens/profile_screen.dart';
import 'package:church_member_app/screens/home_screen.dart';
import 'package:church_member_app/screens/success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../flavor/flavor_config.dart' show FlavorConfig;
import '../services/api_service.dart';
import '../utils/storage.dart';

class RegisterScreen extends StatefulWidget {
  final String token;
  const RegisterScreen({super.key, required this.token});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? data;
  bool loading = true;
  bool showPrayer = false;
  bool submitting = false;

  final prayerCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final fromCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final baptisedYearCtrl = TextEditingController();

  String memberType = 'regular';
  String attendingWith = 'alone';
  String gender = 'male';
  bool baptised = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
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
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(Object e) {
    if (!mounted) return;
    final errorMessage = e.toString().replaceFirst("Exception: ", "");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }

  Future<void> _pickBaptisedYear() async {
    final currentYear = DateTime.now().year;
    final initialYear = int.tryParse(baptisedYearCtrl.text) ?? currentYear;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Year'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(1900),
            lastDate: DateTime(currentYear),
            initialDate: DateTime(initialYear),
            selectedDate: DateTime(initialYear),
            onChanged: (dateTime) {
              setState(() => baptisedYearCtrl.text = dateTime.year.toString());
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  void submit() async {
    if (submitting) return;
    if (nameCtrl.text.isEmpty || fromCtrl.text.isEmpty || yearCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
      _showErrorDialog('Please fill in all required fields.');
      return;
    }

    setState(() => submitting = true);
    final authToken = await Storage.getToken();
    try {
      await ApiService.saveProfile(
        nameCtrl.text, fromCtrl.text, int.parse(yearCtrl.text),
        memberType, attendingWith, emailCtrl.text, gender, baptised,
        baptisedYearCtrl.text.isNotEmpty ? baptisedYearCtrl.text : null,
      );
      await ApiService.submitAttendance(data!['serviceId'], authToken!, prayerCtrl.text);
      
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuccessScreen()));
    } catch (e) {
      _showErrorDialog(e.toString().replaceFirst("Exception: ", ""));
      setState(() => submitting = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Failed'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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
    emailCtrl.dispose();
    baptisedYearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final primaryColor = FlavorConfig.instance.values.primaryColor;

    return Scaffold(
      backgroundColor: primaryColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Immersive Header Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Confirm Attendance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Image.asset(
                      FlavorConfig.instance.values.logoAsset,
                      height: 40,
                    ),
                  ],
                ),
              ),
              
              // Expanded Sheet-like Body
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildEventCard(primaryColor),
                            const SizedBox(height: 24),
                            _buildFormSection('Personal Information', [
                              _buildTextField(nameCtrl, 'Full Name', Icons.person),
                              _buildTextField(emailCtrl, 'Email Address', Icons.email, keyboardType: TextInputType.emailAddress),
                              _buildDropdown('Gender', gender, ['male', 'female', 'others'], (v) => setState(() => gender = v!)),
                            ]),
                            const SizedBox(height: 16),
                            _buildFormSection('Church Life', [
                              _buildTextField(fromCtrl, 'Coming From', Icons.location_on),
                              _buildTextField(yearCtrl, 'Attending Since', Icons.calendar_today, keyboardType: TextInputType.number),
                              _buildDropdown('Member Type', memberType, ['guest', 'regular', 'online viewer'], (v) => setState(() => memberType = v!)),
                              _buildDropdown('Attending With', attendingWith, ['alone', 'family', 'friends'], (v) => setState(() => attendingWith = v!)),
                            ]),
                            const SizedBox(height: 16),
                            _buildFormSection('Faith Journey', [
                              _buildSwitch('Are you baptised?', baptised, (v) => setState(() => baptised = v)),
                              if (baptised) 
                                _buildPickerField('Baptism Year', baptisedYearCtrl, _pickBaptisedYear),
                            ]),
                            const SizedBox(height: 16),
                            _buildPrayerSection(primaryColor),
                            const SizedBox(height: 32),
                            _buildSubmitButton(primaryColor),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
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

  Widget _buildEventCard(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            data!['eventName'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEventIcon(Icons.calendar_month, data!['eventDate']),
              _buildEventIcon(Icons.access_time, data!['serviceTime']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 18),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children.expand((w) => [w, const SizedBox(height: 12)]).toList()..removeLast(),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.black45),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1)))).toList(),
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: FlavorConfig.instance.values.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPickerField(String label, TextEditingController ctrl, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: IgnorePointer(
        child: _buildTextField(ctrl, label, Icons.calendar_month),
      ),
    );
  }

  Widget _buildPrayerSection(Color color) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => showPrayer = !showPrayer),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(showPrayer ? Icons.remove_circle_outline : Icons.add_circle_outline, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  showPrayer ? 'Hide Prayer Request' : 'Add Prayer Request',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        if (showPrayer)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(top: 12),
            child: TextField(
              controller: prayerCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Your prayer request...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: color.withOpacity(0.1)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton(Color color) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: submitting ? null : submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: submitting 
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ) 
          : const Text(
              'Confirm Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
      ),
    );
  }
}
