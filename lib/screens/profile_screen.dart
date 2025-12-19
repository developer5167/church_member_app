import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameCtrl = TextEditingController();
  final fromCtrl = TextEditingController();
  final yearCtrl = TextEditingController();

  String memberType = 'regular';
  String attendingWith = 'alone';

  void saveProfile() async {
    await ApiService.saveProfile(
      nameCtrl.text,
      fromCtrl.text,
      int.parse(yearCtrl.text),
      memberType,
      attendingWith,
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: 'Coming From')),
            TextField(controller: yearCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Since Which Year')),

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

            const SizedBox(height: 20),
            ElevatedButton(onPressed: saveProfile, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
