import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:church_member_app/flavor/flavor_config.dart';
import 'package:church_member_app/screens/profile_screen.dart';
import 'package:church_member_app/screens/qr_scan_screen.dart';
import 'package:church_member_app/services/api_service.dart';
import 'package:church_member_app/utils/storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 1;
  bool _loadingSow = false;
  String? _sowPaymentLink;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ---------- Navigation ----------
  void _switchTo(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  // ---------- Sow Logic ----------
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
    } catch (e) {
      _showMessage('Failed to fetch payment link: ${e.toString()}');
      setState(() => _sowPaymentLink = null);
    } finally {
      if (mounted) setState(() => _loadingSow = false);
    }
  }

  Future<void> _refreshSowLink() async {
    if (!_loadingSow) {
      await _fetchSowLink();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final primaryColor = FlavorConfig.instance.values.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: WillPopScope(
        onWillPop: () async {
          final shouldClose = await _showExitDialog();
          if (shouldClose) SystemNavigator.pop();
          return false;
        },
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildSowScreen(primaryColor),
            const QrScanScreen(embedded: true),
            const ProfileScreen(embedded: true),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(primaryColor),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: FloatingActionButton(
            onPressed: () => _switchTo(1),
            backgroundColor: primaryColor,
            elevation: 0,
            highlightElevation: 0,
            shape: const CircleBorder(),
            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Exit App', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to exit the application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ---------- Sow Screen ----------
  Widget _buildSowScreen(Color primaryColor) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
        ),
      ),
      child: SafeArea(
        child: _loadingSow
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : RefreshIndicator(
                onRefresh: _refreshSowLink,
                color: primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _sowPaymentLink != null 
                          ? _buildPaymentQrView(primaryColor)
                          : _buildSowEmptyState(primaryColor),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPaymentQrView(Color primaryColor) {
    return Column(
      children: [
        const Text(
          'Generous Giving',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'PlayfairDisplay'),
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
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: QrImageView(
            data: _sowPaymentLink!,
            size: MediaQuery.of(context).size.width * 0.7,
            padding: EdgeInsets.zero,
            eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: primaryColor),
            dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: primaryColor),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _fetchSowLink,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh Payment QR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              elevation: 0,
              side: BorderSide(color: primaryColor.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSowEmptyState(Color primaryColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        ClipOval(
          child: Image.asset(
            FlavorConfig.instance.values.logoAsset,
            width: 140,
            height: 140,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          'Faithful Steward',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'PlayfairDisplay'),
        ),
        const SizedBox(height: 16),
        const Text(
          '“Each of you should give what you have decided in your heart to give, not reluctantly or under compulsion, for God loves a cheerful giver.”',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.black54, fontStyle: FontStyle.italic, height: 1.5),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: _fetchSowLink,
            icon: const Icon(Icons.volunteer_activism_rounded),
            label: const Text('Proceed to Sow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: primaryColor.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Bottom Bar ----------
  Widget _buildBottomBar(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: BottomAppBar(
        height: 80,
        color: Colors.white,
        elevation: 0,
        notchMargin: 5,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.volunteer_activism_rounded, 'Sow', primaryColor),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(2, Icons.person_rounded, 'Profile', primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color primaryColor) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _switchTo(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
