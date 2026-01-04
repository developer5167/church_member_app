import 'package:church_member_app/firebase_options.dart';
import 'package:church_member_app/screens/qr_scan_screen.dart';
import 'package:church_member_app/screens/home_screen.dart';
import 'package:church_member_app/utils/storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'flavor/app_flavor.dart';
import 'flavor/flavor_config.dart';
import 'flavor/flavor_platform.dart';
import 'flavor/flavor_values.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final flavor = await FlavorPlatform.getFlavor();
  late AppFlavor appFlavor;
  late FlavorValues values;
  switch (flavor) {
    case 'lordsChurch':
      appFlavor = AppFlavor.lordsChurch;
      values = const FlavorValues(
        churchId: "11111111-1111-1111-1111-111111111111",
        appName: "Lords Church",
        logoAsset: "assets/images/lordsChurch.jpg",
        primaryColor: Colors.black,
        fontFamily: 'Roboto',
      );
      break;
    default:
      appFlavor = AppFlavor.lordsChurch;
      values = const FlavorValues(
        churchId: "11111111-1111-1111-1111-111111111111",
        appName: "Lords Church",
        logoAsset: "assets/images/lordsChurch.jpg",
        primaryColor: Colors.black,
        fontFamily: 'Roboto',
      );
  }
  FlavorConfig.init(flavor: appFlavor, values: values);
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
          if (!snapshot.hasData || snapshot.data == null) {
            return const LoginScreen();
          }
          return const HomeScreen();
        },
      ),
    );
  }
}
