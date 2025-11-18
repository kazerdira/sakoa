import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/widgets/toast.dart';
import 'package:sakoa/common/repositories/auth/auth_repository.dart';
import 'package:sakoa/common/exceptions/auth_exceptions.dart';
import 'index.dart';

class ForgotController extends GetxController {
  final state = ForgotState();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  TextEditingController? EmailEditingController = TextEditingController();
  ForgotController();

  /// Handle password reset using AuthRepository
  Future<void> handleEmailForgot() async {
    String emailAddress = state.email.value;

    // Validate input
    if (emailAddress.isEmpty) {
      toastInfo(msg: "Email cannot be empty!");
      return;
    }

    // Dismiss keyboard
    Get.focusScope?.unfocus();

    try {
      // Send password reset email using AuthRepository
      await _authRepository.sendPasswordReset(email: emailAddress);

      // Success - show confirmation message
      toastInfo(
        msg: "A password reset email has been sent to your registered email. "
            "Please open the link from the email to reset your password.",
      );
    } on PasswordResetException catch (e) {
      toastInfo(msg: e.getUserMessage());
      print('[Forgot] ❌ Password reset error: ${e.message}');
    } on AuthException catch (e) {
      toastInfo(msg: e.getUserMessage());
      print('[Forgot] ❌ Auth error: ${e.message}');
    } catch (e) {
      toastInfo(msg: 'Password reset failed. Please try again.');
      print('[Forgot] ❌ Unexpected error: $e');
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Listen to auth state changes using AuthRepository
    _authRepository.authStateChanges.listen((user) {
      print(
          '[Forgot] Auth state changed: ${user != null ? 'signed in' : 'signed out'}');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
