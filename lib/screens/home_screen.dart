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

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1;
  bool _loadingSow = false;
  String? _sowPaymentLink;

  // ---------- Navigation ----------
  void _switchTo(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  // ---------- Sow Logic ----------
  Future<void> _fetchSowLink() async {
    HapticFeedback.selectionClick();
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
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Sow';
      case 1:
        return 'Scan QR';
      case 2:
        return 'Profile';
      default:
        return 'Home';
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,

        surfaceTintColor: Colors.transparent,
        title: Text(_getTitleForIndex(_currentIndex),style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[900]),),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: WillPopScope(
        onWillPop: () async {
          final shouldClose =
              await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Exit App'),
                  content: const Text('Are you sure you want to exit?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              ) ??
              false;

          if (shouldClose) SystemNavigator.pop();
          return false;
        },
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildSowScreen(),
            const QrScanScreen(embedded: true),
            const ProfileScreen(embedded: true),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _switchTo(1),
        backgroundColor: FlavorConfig.instance.values.primaryColor,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),
    );
  }

  // ---------- Sow Screen ----------
  Widget _buildSowScreen() {
    if (_loadingSow) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sowPaymentLink != null) {
      return RefreshIndicator(
        onRefresh: _refreshSowLink,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Scan this QR to make a payment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Center(
              child: QrImageView(
                data: _sowPaymentLink!,
                size: MediaQuery.of(context).size.width * 0.9,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black87,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black87,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton.icon(
                  onPressed: _fetchSowLink,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generate New QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default/empty state
    return RefreshIndicator(
      onRefresh: _refreshSowLink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    FlavorConfig.instance.values.logoAsset,
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Sow',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Generate a QR code to receive payments',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _fetchSowLink,
                    icon: const Icon(Icons.qr_code, size: 24),
                    label: const Text(
                      'Generate Payment QR',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          FlavorConfig.instance.values.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Optional: Add info dialog about the payment process
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('About Sow Payments'),
                          content: const Text(
                            'This generates a unique QR code for receiving payments. '
                            'Each QR is valid for a single transaction and expires after 24 hours.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      'How does this work?',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Bottom Bar ----------
  Widget _buildBottomBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: kBottomNavigationBarHeight + 12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _switchTo(0),
                customBorder: const CircleBorder(),
                splashColor: FlavorConfig.instance.values.primaryColor
                    .withOpacity(0.2),
                highlightColor: FlavorConfig.instance.values.primaryColor
                    .withOpacity(0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      color: _currentIndex == 0
                          ? FlavorConfig.instance.values.primaryColor
                          : Colors.grey[600],
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sow',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _currentIndex == 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _currentIndex == 0
                            ? FlavorConfig.instance.values.primaryColor
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 80), // Space for FAB
            Expanded(
              child: InkWell(
                onTap: () => _switchTo(2),
                customBorder: const CircleBorder(),
                splashColor: FlavorConfig.instance.values.primaryColor
                    .withOpacity(0.2),
                highlightColor: FlavorConfig.instance.values.primaryColor
                    .withOpacity(0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: _currentIndex == 2
                          ? FlavorConfig.instance.values.primaryColor
                          : Colors.grey[600],
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _currentIndex == 2
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _currentIndex == 2
                            ? FlavorConfig.instance.values.primaryColor
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
