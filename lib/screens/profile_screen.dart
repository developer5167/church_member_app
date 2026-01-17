import 'dart:async';
import 'package:church_member_app/flavor/flavor_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';
import '../models/volunteer_models.dart';
import 'department_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;

  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
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

  bool hasRequest = false;
  String? baptismStatus; // pending | completed
  bool requestingBaptism = false;

  // Volunteer state
  bool hasVolunteerRequest = false;
  VolunteerStatus? volunteerStatus;
  bool loadingVolunteerStatus = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

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

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    await Future.wait([
      _loadProfile(),
      _fetchBaptismStatus(),
      _fetchVolunteerStatus(),
    ]);
    if (mounted) {
      setState(() => loading = false);
      _animationController.forward();
    }
  }

  Future<void> _fetchBaptismStatus() async {
    try {
      final token = await Storage.getToken();
      if (token != null) {
        final status = await ApiService.getBaptismRequestStatus(token);
        setState(() {
          hasRequest = status['hasRequest'];
          baptismStatus = status['status'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching baptism status: $e');
    }
  }

  Future<void> _fetchVolunteerStatus() async {
    try {
      final token = await Storage.getToken();
      if (token != null) {
        final response = await ApiService.getVolunteerRequestStatus(token);
        setState(() {
          volunteerStatus = VolunteerStatus.fromJson(response);
          // User has sent a request if there's either an active request OR a completed request
          hasVolunteerRequest =
              volunteerStatus!.hasActiveRequest ||
              volunteerStatus!.lastCompletedRequest != null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching volunteer status: $e');
    }
  }

  Future<void> _launchUrl(
    BuildContext context,
    String url,
    String platformName,
  ) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $platformName')));
    }
  }

  Future<void> _pickBaptisedYear() async {
    final currentYear = DateTime.now().year;
    final initialYear = baptisedYearCtrl.text.isNotEmpty
        ? int.tryParse(baptisedYearCtrl.text) ?? currentYear
        : currentYear;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedYear = initialYear;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
    final initialYear = yearCtrl.text.isNotEmpty
        ? int.tryParse(yearCtrl.text) ?? currentYear
        : currentYear;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedYear = initialYear;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
      debugPrint('Error loading profile: $e');
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
      _showErrorDialog(
        'Please enter a valid year between 1900 and $currentYear',
      );
      return;
    }

    if (emailCtrl.text.isEmpty) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please enter your email address');
      return;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(emailCtrl.text)) {
      HapticFeedback.lightImpact();
      _showErrorDialog('Please enter a valid email address');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => saving = true);

    try {
      await ApiService.saveProfile(
        nameCtrl.text,
        fromCtrl.text,
        year,
        memberType,
        attendingWith,
        emailCtrl.text,
        gender,
        baptised,
        baptisedYearCtrl.text.isNotEmpty ? baptisedYearCtrl.text : null,
      );

      HapticFeedback.selectionClick();
      _showSuccessDialog('Profile saved successfully!', () {
        setState(() => isEditing = false);
        if (!widget.embedded) Navigator.pop(context);
      });
    } catch (e) {
      HapticFeedback.heavyImpact();
      final errorMessage = e.toString().replaceFirst("Exception: ", "");
      _showErrorDialog('Failed to save profile: $errorMessage');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _handleBaptismRequest() async {
    HapticFeedback.mediumImpact();
    setState(() => requestingBaptism = true);

    try {
      final token = await Storage.getToken();
      await ApiService.requestBaptism(token!);

      await _fetchBaptismStatus();
      HapticFeedback.selectionClick();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Baptism request submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
      final errorMessage = e.toString().replaceFirst("Exception: ", "");
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) setState(() => requestingBaptism = false);
    }
  }

  Future<void> _navigateToDepartmentSelection() async {
    HapticFeedback.selectionClick();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DepartmentSelectionScreen(),
      ),
    );

    // If request was successfully submitted, refresh volunteer status
    if (result == true) {
      await _fetchVolunteerStatus();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Error',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message, VoidCallback onOk) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Success!',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onOk();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FlavorConfig.instance.values.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
    final primaryColor = FlavorConfig.instance.values.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: widget.embedded
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (!loading)
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => isEditing = !isEditing);
              },
              icon: Icon(
                isEditing ? Icons.close : Icons.edit_note,
                color: primaryColor,
                size: 28,
              ),
            ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileHeader(primaryColor),
                        const SizedBox(height: 24),

                        // Baptism Request Section
                        if (!baptised) ...[
                          if (!hasRequest)
                            _buildBaptismRequestCard(primaryColor)
                          else if (baptismStatus == 'pending')
                            _buildPendingRequestInfo()
                          else if (baptismStatus == 'completed')
                            _buildCompletedRequestInfo(),
                          const SizedBox(height: 16),
                        ],

                        // Volunteer Request Section
                        if (!hasVolunteerRequest)
                          _buildVolunteerRequestCard(primaryColor)
                        else if (volunteerStatus != null &&
                            volunteerStatus!.hasActiveRequest &&
                            volunteerStatus!.request != null)
                          _buildVolunteerStatusInfo(volunteerStatus!),
                        const SizedBox(height: 16),

                        _buildSectionTitle('Personal Information'),
                        const SizedBox(height: 16),
                        _buildCard([
                          _buildInputField(
                            nameCtrl,
                            'Full Name',
                            Icons.person_outline,
                            isEditing,
                          ),
                          _buildInputField(
                            emailCtrl,
                            'Email Address',
                            Icons.email_outlined,
                            isEditing,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _buildGenderSelector(isEditing),
                        ]),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Church Connection'),
                        const SizedBox(height: 16),
                        _buildCard([
                          _buildInputField(
                            fromCtrl,
                            'Coming From',
                            Icons.location_on_outlined,
                            isEditing,
                          ),
                          _buildYearPickerField(
                            yearCtrl,
                            'Since Which Year',
                            Icons.calendar_month_outlined,
                            isEditing,
                            _pickComingFromYear,
                          ),
                          _buildDropdown(
                            'Member Type',
                            memberType,
                            _memberTypeItems(),
                            (v) => setState(() => memberType = v!),
                            isEditing,
                          ),
                          _buildDropdown(
                            'Attending With',
                            attendingWith,
                            _attendingWithItems(),
                            (v) => setState(() => attendingWith = v!),
                            isEditing,
                          ),
                        ]),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Faith Journey'),
                        const SizedBox(height: 16),
                        _buildCard([
                          _buildBaptisedSelector(isEditing),
                          if (baptised)
                            _buildYearPickerField(
                              baptisedYearCtrl,
                              'Baptised Year',
                              Icons.waves_outlined,
                              isEditing,
                              _pickBaptisedYear,
                            ),
                        ]),
                        const SizedBox(height: 32),
                        if (isEditing)
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: saving ? null : saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              child: saving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        const SizedBox(height: 40),
                        _buildSocialSection(),
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            'The Lords Church India © ${DateTime.now().year}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(Icons.person, size: 40, color: primaryColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Welcome',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PlayfairDisplay',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  memberType.toUpperCase(),
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaptismRequestCard(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.waves_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Step of Faith',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Are you ready to take the next step in your spiritual journey through water baptism?',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: requestingBaptism ? null : _handleBaptismRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: requestingBaptism
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: primaryColor,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Request Baptism',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your baptism request is currently being processed. Our team will contact you soon.',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedRequestInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Colors.green,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your baptism request has been completed. Praise the Lord!',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children:
            children.expand((w) => [w, const SizedBox(height: 16)]).toList()
              ..removeLast(),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool enabled, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          enabled: enabled,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black45, size: 22),
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildYearPickerField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool enabled,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: AbsorbPointer(
            child: TextField(
              controller: ctrl,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.black45, size: 22),
                suffixIcon: const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.black38,
                ),
                filled: true,
                fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> onChanged,
    bool enabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _genderOption('male', Icons.male, Colors.blue, enabled),
            const SizedBox(width: 12),
            _genderOption('female', Icons.female, Colors.pink, enabled),
            const SizedBox(width: 12),
            _genderOption('others', Icons.person, Colors.purple, enabled),
          ],
        ),
      ],
    );
  }

  Widget _genderOption(String val, IconData icon, Color color, bool enabled) {
    bool isSelected = gender == val;
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? () => setState(() => gender = val) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.black38, size: 20),
              const SizedBox(height: 4),
              Text(
                val[0].toUpperCase() + val.substring(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBaptisedSelector(bool enabled) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Have you been baptised?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        Switch.adaptive(
          value: baptised,
          onChanged: enabled ? (v) => setState(() => baptised = v) : null,
          activeColor: FlavorConfig.instance.values.primaryColor,
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> _memberTypeItems() => [
    const DropdownMenuItem(value: 'guest', child: Text('Guest')),
    const DropdownMenuItem(value: 'regular', child: Text('Regular Member')),
    const DropdownMenuItem(
      value: 'online viewer',
      child: Text('Online Viewer'),
    ),
  ];

  List<DropdownMenuItem<String>> _attendingWithItems() => [
    const DropdownMenuItem(value: 'alone', child: Text('Alone')),
    const DropdownMenuItem(value: 'family', child: Text('With Family')),
    const DropdownMenuItem(value: 'friends', child: Text('With Friends')),
  ];

  Widget _buildSocialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connect With Us',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _socialItem(
                FontAwesomeIcons.facebook,
                const Color(0xFF1877F2),
                'Facebook',
                'Raj Prakash Paul',
                'https://www.facebook.com/rajprakashpaul',
              ),
              _socialItem(
                FontAwesomeIcons.youtube,
                const Color(0xFFFF0000),
                'YouTube',
                'Lords Church',
                'https://www.youtube.com/@TheLordsChurchIndia',
              ),
              _socialItem(
                FontAwesomeIcons.instagram,
                const Color(0xFFE4405F),
                'Instagram',
                'Jessy Paul',
                'https://www.instagram.com/jessypauln',
              ),
              _socialItem(
                FontAwesomeIcons.whatsapp,
                const Color(0xFF25D366),
                'WhatsApp',
                'Church Updates',
                'https://whatsapp.com/channel/0029ValI9TD9cDDT6ArJVJ30',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialItem(
    IconData icon,
    Color color,
    String platform,
    String name,
    String url,
  ) {
    return GestureDetector(
      onTap: () => _launchUrl(context, url, platform),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              platform,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              name,
              style: const TextStyle(fontSize: 10, color: Colors.black45),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerRequestCard(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.9),
            primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.volunteer_activism, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Join Our Ministry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Are you ready to serve and make a difference? Join our volunteer team and use your gifts to serve the church community.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _navigateToDepartmentSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Become a Volunteer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerStatusInfo(VolunteerStatus status) {
    final request = status.request!;
    final isPending = request.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending
            ? Colors.amber.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? Colors.amber.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPending
                    ? Icons.info_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: isPending ? Colors.amber : Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPending
                          ? 'Volunteer Request Pending'
                          : 'Volunteer Request Completed',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.message,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (request.departments.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Selected Departments:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: request.departments.map((dept) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: isPending ? Colors.amber : Colors.green,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dept.departmentName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
