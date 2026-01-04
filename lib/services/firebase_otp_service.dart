import 'package:firebase_auth/firebase_auth.dart';

class FirebaseOtpService {
  static String? _verificationId;

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> sendOtp(String phone) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto verification (Android only)
        await _auth.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        throw Exception(e.message ?? 'OTP verification failed');
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  static Future<String> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      throw Exception('OTP session expired. Please resend OTP.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );

    final userCredential =
    await _auth.signInWithCredential(credential);

    // Use Firebase UID as session token
    return userCredential.user!.uid;
  }
}
