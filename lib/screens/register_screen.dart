import 'package:church_member_app/screens/profile_screen.dart';
import 'package:church_member_app/screens/qr_scan_screen.dart';
import 'package:church_member_app/screens/success_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/storage.dart';

class RegisterScreen extends StatefulWidget {
  final String token;
  const RegisterScreen({super.key, required this.token});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  bool showPrayer = false;
  bool submitting = false;

  final prayerCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final fromCtrl = TextEditingController();
  final yearCtrl = TextEditingController();

  String memberType = 'regular';
  String attendingWith = 'alone';

  @override
  void initState() {
    super.initState();
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
      final profile = await ApiService.getProfile(authToken);

      final isProfileComplete = profile['full_name'] != null;

      if (!isProfileComplete) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      } else {
        setState(() {
          nameCtrl.text = profile['full_name'];
          fromCtrl.text = profile['coming_from'];
          yearCtrl.text = profile['since_year'].toString();
          memberType = profile['member_type'];
          attendingWith = profile['attending_with'];
        });
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().startsWith("Exception: ")
          ? e.toString().substring(11)
          : e.toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => QrScanScreen()),
      );
    }
  }

  void submit() async {
    if (submitting) return;
    setState(() => submitting = true);
    final authToken = await Storage.getToken();
    try {
      await ApiService.saveProfile(
        nameCtrl.text,
        fromCtrl.text,
        int.parse(yearCtrl.text),
        memberType,
        attendingWith,
      );

      await ApiService.submitAttendance(
        data!['serviceId'],
        authToken!,
        prayerCtrl.text,
      );

      setState(() => submitting = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuccessScreen()),
      );
    } catch (e) {
      final errorMessage = e.toString().startsWith("Exception: ")
          ? e.toString().substring(11)
          : e.toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Event: ${data!['eventName']}'),
            Text('Date: ${data!['eventDate']}'),
            Text('Time: ${data!['serviceTime']}'),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: fromCtrl,
              decoration: const InputDecoration(labelText: 'Coming From'),
            ),
            TextField(
              controller: yearCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Since Which Year'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField(
              value: memberType,
              items: const [
                DropdownMenuItem(value: 'guest', child: Text('Guest')),
                DropdownMenuItem(value: 'regular', child: Text('Regular')),
              ],
              onChanged: (v) => setState(() => memberType = v!),
              decoration: const InputDecoration(labelText: 'Member Type'),
            ),
            DropdownButtonFormField(
              value: attendingWith,
              items: const [
                DropdownMenuItem(value: 'alone', child: Text('Alone')),
                DropdownMenuItem(value: 'family', child: Text('Family')),
                DropdownMenuItem(value: 'friends', child: Text('Friends')),
              ],
              onChanged: (v) => setState(() => attendingWith = v!),
              decoration: const InputDecoration(labelText: 'Attending With'),
            ),
            TextButton(
              onPressed: () => setState(() => showPrayer = !showPrayer),
              child: const Text('Add prayer request'),
            ),
            if (showPrayer)
              TextField(
                controller: prayerCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Prayer Request (optional)',
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: submit, child: const Text('Submit')),
          ],
        ),
      ),
    );
  }
}
