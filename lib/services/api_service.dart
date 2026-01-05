import 'dart:convert';
import 'package:church_member_app/flavor/flavor_config.dart';
import 'package:church_member_app/utils/storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // static const String baseUrl = 'http://172.20.10.2:4000/api';
  // static const String baseUrl = 'http://192.168.31.196:4000/api'; //home
  static const String baseUrl = 'http://192.168.15.187:4000/api'; //office

  static Future<void> saveProfile(
    String fullName,
    String comingFrom,
    int sinceYear,
    String memberType, // guest | regular
    String attendingWith, // alone | family | friends
  ) async {
    final authToken = await Storage.getToken();
    const apiUrl = '$baseUrl/member/profile';
    print('API URL:$apiUrl');
    final response = await http.post(
      Uri.parse('$baseUrl/member/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'full_name': fullName,
        'coming_from': comingFrom,
        'since_year': sinceYear,
        'member_type': memberType,
        'attending_with': attendingWith,
      }),
    );
    print('${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to save profile');
    }
  }

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
      body: jsonEncode({'phone': phone, 'otp': otp,"churchId":FlavorConfig.instance.values.churchId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Invalid OTP');
    }

    final data = jsonDecode(response.body);
    return data['token'];
  }

  static Future<Map<String, dynamic>> fetchMetadata(
    String token,
    String authToken,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/member/register/metadata?token=$token'),
      headers: {'Authorization': 'Bearer $authToken'},
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
    print('Getting profile');
    final response = await http.get(
      Uri.parse('$baseUrl/member/profile'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    return jsonDecode(response.body);
  }

  static Future<String?> getPaymentLink(String authToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/member/payment-link'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    print('RESPONSE:  ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final data = jsonDecode(response.body);
    return data['paymentLink'];
  }
}
