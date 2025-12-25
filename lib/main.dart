import 'package:church_member_app/screens/qr_scan_screen.dart';
import 'package:church_member_app/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flavor/app_flavor.dart';
import 'flavor/flavor_config.dart';
import 'flavor/flavor_platform.dart';
import 'flavor/flavor_values.dart';
import 'screens/login_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  final flavor = await FlavorPlatform.getFlavor();
  late AppFlavor appFlavor;
  late FlavorValues values;
  switch (flavor) {
    case 'lordsChurch':
      appFlavor = AppFlavor.lordsChurch;
      values = const FlavorValues(
        appName: "Lords Church",
        logoAsset: "assets/images/lordsChurch.jpg",
        primaryColor: Colors.blue,
        fontFamily: 'Roboto',
      );
      break;
    default:
      appFlavor = AppFlavor.lordsChurch;
      values = const FlavorValues(
        appName: "Lords Church",
        logoAsset: "assets/images/lordsChurch.jpg",
        primaryColor: Colors.blue,
        fontFamily: 'Roboto',
      );
  }
  FlavorConfig.init(
    flavor: appFlavor,
    values: values,
  );
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
