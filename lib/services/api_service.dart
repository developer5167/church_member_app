import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://YOUR_SERVER_IP:4000/api';

  static Future<void> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/member/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP');
    }
  }

  static Future<String> verifyOtp(String phone, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/member/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );

    if (response.statusCode != 200) {
      throw Exception('Invalid OTP');
    }

    final data = jsonDecode(response.body);
    return data['token'];
  }
  static Future<Map<String, dynamic>> fetchMetadata(
      String token, String authToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/member/register/metadata?token=$token'),
      headers: {
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Invalid or expired QR');
    }

    return jsonDecode(response.body);
  }

  static Future<void> submitAttendance(
      String serviceId,
      String authToken,
      String? prayerRequest,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/member/register/submit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'serviceId': serviceId,
        'prayerRequest': prayerRequest, // 👈 optional
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Already registered or failed');
    }
  }
  static Future<Map<String, dynamic>> getProfile(String authToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/member/profile'),
      headers: {'Authorization': 'Bearer $authToken'},
    );

    return jsonDecode(response.body);
  }


}
