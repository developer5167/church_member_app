import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:church_member_app/flavor/flavor_config.dart';
import 'package:church_member_app/screens/department_selection_screen.dart';
import 'package:church_member_app/screens/profile_screen.dart';
import 'package:church_member_app/screens/qr_scan_screen.dart';
import 'package:church_member_app/screens/send_prayer_request_screen.dart';
import 'package:church_member_app/screens/my_prayer_requests_screen.dart';
import 'package:church_member_app/services/api_service.dart';
import 'package:church_member_app/models/volunteer_models.dart';
import 'package:church_member_app/utils/storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loadingSow = false;
  String? _sowPaymentLink;

  // ───── Baptism state ─────
  bool _hasRequest = false;
  String? _baptismStatus;
  bool _requestingBaptism = false;
  bool _baptised = false;

  // ───── Volunteer state ─────
  bool _hasVolunteerRequest = false;
  VolunteerStatus? _volunteerStatus;

  @override
  void initState() {
    super.initState();
    _fetchBaptismStatus();
    _fetchVolunteerStatus();
  }

  // ───── Baptism / Volunteer logic ─────

  Future<void> _fetchBaptismStatus() async {
    try {
      final token = await Storage.getToken();
      if (token != null) {
        final status = await ApiService.getBaptismRequestStatus(token);
        if (mounted) {
          setState(() {
            _hasRequest = status['hasRequest'] ?? false;
            _baptismStatus = status['status'];
            _baptised = status['baptised'] ?? false;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchVolunteerStatus() async {
    try {
      final token = await Storage.getToken();
      if (token != null) {
        final response = await ApiService.getVolunteerRequestStatus(token);
        if (mounted) {
          final vs = VolunteerStatus.fromJson(response);
          setState(() {
            _volunteerStatus = vs;
            _hasVolunteerRequest =
                vs.hasActiveRequest || vs.lastCompletedRequest != null;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _handleBaptismRequest() async {
    HapticFeedback.mediumImpact();
    setState(() => _requestingBaptism = true);
    try {
      final token = await Storage.getToken();
      await ApiService.requestBaptism(token!);
      await _fetchBaptismStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Baptism request submitted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _requestingBaptism = false);
    }
  }

  Future<void> _navigateToDepartmentSelection() async {
    HapticFeedback.selectionClick();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DepartmentSelectionScreen()),
    );
    if (result == true) await _fetchVolunteerStatus();
  }

  // ───── Sow logic ─────

  Future<void> _fetchSowLink() async {
    HapticFeedback.mediumImpact();
    setState(() => _loadingSow = true);

    final token = await Storage.getToken();
    if (token == null) {
      _showMessage('Not authenticated');
      setState(() => _loadingSow = false);
      return;
    }

    try {
      final link = await ApiService.getPaymentLink(token);
      if (!mounted) return;
      setState(() => _sowPaymentLink = link);
      // Push the Sow screen once we have the link
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _SowScreen(
            paymentLink: link.toString(),
            onRefresh: _refreshLinkInBackground,
          ),
        ),
      );
    } catch (e) {
      _showMessage('Failed to fetch payment link: ${e.toString()}');
      if (mounted) setState(() => _sowPaymentLink = null);
    } finally {
      if (mounted) setState(() => _loadingSow = false);
    }
  }

  Future<void> _refreshLinkInBackground() async {
    final token = await Storage.getToken();
    if (token == null) return;
    try {
      final link = await ApiService.getPaymentLink(token);
      if (mounted) setState(() => _sowPaymentLink = link);
    } catch (_) {}
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ───── Exit dialog ─────

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Exit App',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Are you sure you want to exit the application?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ───── Build ─────

  @override
  Widget build(BuildContext context) {
    final primary = FlavorConfig.instance.values.primaryColor;
    final appName = FlavorConfig.instance.values.appName;

    return WillPopScope(
      onWillPop: () async {
        final shouldClose = await _showExitDialog();
        if (shouldClose) SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        // ── AppBar ──
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 70,
          titleSpacing: 24,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primary,
                  fontFamily: 'PlayfairDisplay',
                ),
              ),
              const Text(
                'Welcome back 👋',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(embedded: false),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: primary.withOpacity(0.12),
                  child: Icon(Icons.person_rounded, color: primary, size: 26),
                ),
              ),
            ),
          ],
        ),

        // ── Body ──
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Church logo card
                _buildHeader(primary),

                const SizedBox(height: 28),

                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // 2×2 grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _dashCard(
                      icon: Icons.volunteer_activism_rounded,
                      label: 'Sow',
                      subtitle: 'Give your offering',
                      color: const Color(0xFF6C63FF),
                      isLoading: _loadingSow,
                      onTap: _fetchSowLink,
                    ),
                    _dashCard(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Scan QR',
                      subtitle: 'Mark attendance',
                      color: const Color(0xFF00BFA6),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QrScanScreen(embedded: false),
                          ),
                        );
                      },
                    ),
                    _dashCard(
                      icon: Icons.send_rounded,
                      label: 'Prayer Request',
                      subtitle: 'Send a request',
                      color: const Color(0xFFF06292),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SendPrayerRequestScreen(),
                          ),
                        );
                      },
                    ),
                    _dashCard(
                      icon: Icons.list_alt_rounded,
                      label: 'My Prayers',
                      subtitle: 'View my requests',
                      color: const Color(0xFFFF8F00),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyPrayerRequestsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Get Involved ──
                _buildGetInvolvedSection(),

                const SizedBox(height: 20),

                // Verse card
                _buildVerseCard(),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───── Header ─────

  Widget _buildHeader(Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              FlavorConfig.instance.values.logoAsset,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FlavorConfig.instance.values.appName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PlayfairDisplay',
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  '"God loves a cheerful giver." — 2 Cor 9:7',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───── Dashboard Card ─────

  Widget _dashCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: color,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───── Get Involved Section ─────

  Widget _buildGetInvolvedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Get Involved',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInvolvementChip(
                icon: Icons.water_drop_rounded,
                label: 'Baptism',
                subtitle: _baptised
                    ? 'Completed ✓'
                    : _hasRequest
                    ? (_baptismStatus == 'pending' ? 'Pending…' : 'Completed ✓')
                    : 'Request',
                color: const Color(0xFF1565C0),
                enabled: !_baptised && !_hasRequest && !_requestingBaptism,
                isLoading: _requestingBaptism,
                onTap: (!_baptised && !_hasRequest)
                    ? _handleBaptismRequest
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInvolvementChip(
                icon: Icons.groups_rounded,
                label: 'Join Team',
                subtitle: _hasVolunteerRequest
                    ? (_volunteerStatus?.hasActiveRequest == true
                          ? 'Requested ✓'
                          : 'Active ✓')
                    : 'Apply',
                color: const Color(0xFF2E7D32),
                enabled: !_hasVolunteerRequest,
                onTap: !_hasVolunteerRequest
                    ? _navigateToDepartmentSelection
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvolvementChip({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? color.withOpacity(0.3) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (enabled ? color : Colors.grey).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: color,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(icon, color: enabled ? color : Colors.grey, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: enabled ? color : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled && !isLoading)
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: color.withOpacity(0.6),
              ),
          ],
        ),
      ),
    );
  }

  // ───── Verse Card ─────

  static const List<Map<String, String>> _verses = [
    {
      'text': '"The Lord is my shepherd; I shall not want."',
      'ref': '— Psalm 23:1',
    },
    {
      'text': '"I can do all things through Christ who strengthens me."',
      'ref': '— Philippians 4:13',
    },
    {
      'text':
          '"For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life."',
      'ref': '— John 3:16',
    },
    {
      'text':
          '"Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight."',
      'ref': '— Proverbs 3:5–6',
    },
    {
      'text':
          '"Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go."',
      'ref': '— Joshua 1:9',
    },
    {
      'text':
          '"Come to me, all you who are weary and burdened, and I will give you rest."',
      'ref': '— Matthew 11:28',
    },
    {
      'text':
          '"For I know the plans I have for you," declares the Lord, "plans to prosper you and not to harm you, plans to give you hope and a future."',
      'ref': '— Jeremiah 29:11',
    },
  ];

  Widget _buildVerseCard() {
    final verse = _verses[DateTime.now().day % _verses.length];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            color: Colors.white54,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            verse['text']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.65,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            verse['ref']!,
            style: const TextStyle(
              color: Color(0xFFAAB4FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Sow screen — pushed as a full page after fetching the payment link
// ─────────────────────────────────────────────────────────────────────

class _SowScreen extends StatefulWidget {
  final String paymentLink;
  final Future<void> Function() onRefresh;
  const _SowScreen({required this.paymentLink, required this.onRefresh});

  @override
  State<_SowScreen> createState() => _SowScreenState();
}

class _SowScreenState extends State<_SowScreen> {
  late String _link;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _link = widget.paymentLink;
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await widget.onRefresh();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final primary = FlavorConfig.instance.values.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Sow / Give'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: primary))
            : RefreshIndicator(
                onRefresh: _refresh,
                color: primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Generous Giving',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PlayfairDisplay',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Scan this QR code to make your offering',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _link,
                          size: MediaQuery.of(context).size.width * 0.7,
                          padding: EdgeInsets.zero,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: primary,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text(
                            'Refresh Payment QR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primary,
                            elevation: 0,
                            side: BorderSide(color: primary.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
