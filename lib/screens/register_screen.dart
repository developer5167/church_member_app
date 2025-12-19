import 'package:church_member_app/screens/profile_screen.dart';
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
  @override
  void initState() {
    super.initState();
    loadMetadata();

  }

  void loadMetadata() async {
    final authToken = await Storage.getToken();
    final result =
    await ApiService.fetchMetadata(widget.token, authToken!);

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
    }
  }

  void submit() async {
    if (submitting) return;
    setState(() => submitting = true);
    final authToken = await Storage.getToken();
    await ApiService.submitAttendance(
      data!['serviceId'],
      authToken!,
      prayerCtrl.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance marked successfully')),
    );
    setState(() => submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event: ${data!['eventName']}'),
            Text('Date: ${data!['eventDate']}'),
            Text('Time: ${data!['serviceTime']}'),
            TextButton(
              onPressed: () => setState(() => showPrayer = !showPrayer),
              child: const Text('Add prayer request'),
            ),
            if (showPrayer)
              TextField(
                controller: prayerCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Prayer Request (optional)'),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: submit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
