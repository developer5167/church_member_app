import 'package:church_member_app/screens/qr_scan_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final otpController = TextEditingController();
  bool loading = false;

  void verifyOtp() async {
    setState(() => loading = true);

    final token =
    await ApiService.verifyOtp(widget.phone, otpController.text);
    await Storage.saveToken(token);

    setState(() => loading = false);

    // NEXT SCREEN WILL BE QR SCAN
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : verifyOtp,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
