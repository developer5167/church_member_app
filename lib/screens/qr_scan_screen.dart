import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'register_screen.dart';

class QrScanScreen extends StatelessWidget {
  const QrScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          final List<Barcode> barcodes = capture.barcodes;

          if (barcodes.isEmpty) return;

          final String? url = barcodes.first.rawValue;
          if (url == null) return;

          final uri = Uri.parse(url);
          final token = uri.queryParameters['token'];

          if (token != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RegisterScreen(token: token),
              ),
            );
          }
        },
      ),
    );
  }
}
