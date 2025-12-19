import 'package:church_member_app/screens/qr_scan_screen.dart';
import 'package:church_member_app/utils/storage.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Church Attendance',
      home: FutureBuilder(
        future: Storage.getToken(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoginScreen();
          }
          return const QrScanScreen();
        },
      ),
    );
  }
}
