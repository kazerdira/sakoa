import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/widgets/toast.dart';
import 'package:sakoa/common/repositories/auth/auth_repository.dart';
import 'package:sakoa/common/exceptions/auth_exceptions.dart';
import 'index.dart';

class RegisterController extends GetxController {
  final state = RegisterState();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  TextEditingController? UserNameEditingController = TextEditingController();
  TextEditingController? EmailEditingController = TextEditingController();
  TextEditingController? PasswordEditingController = TextEditingController();
  RegisterController();

  /// Handle email/password registration using AuthRepository
  Future<void> handleEmailRegister() async {
    String userName = state.username.value;
    String emailAddress = state.email.value;
    String password = state.password.value;

    // Validate input
    if (userName.isEmpty) {
      toastInfo(msg: "Username cannot be empty!");
      return;
    }
    if (emailAddress.isEmpty) {
      toastInfo(msg: "Email cannot be empty!");
      return;
    }
    if (password.isEmpty) {
      toastInfo(msg: "Password cannot be empty!");
      return;
    }

    // Dismiss keyboard
    Get.focusScope?.unfocus();

    try {
      // Sign up using AuthRepository
      await _authRepository.signUpWithEmail(
        email: emailAddress,
        password: password,
        displayName: userName,
      );

      // Registration successful - show success message
      toastInfo(
        msg: "An email has been sent to your registered email. "
            "To activate your account, please open the link from the email.",
      );

      // Navigate back to sign-in page
      Get.back();
    } on SignUpException catch (e) {
      toastInfo(msg: e.getUserMessage());
      print('[Register] ❌ Sign-up error: ${e.message}');
    } on AuthException catch (e) {
      toastInfo(msg: e.getUserMessage());
      print('[Register] ❌ Auth error: ${e.message}');
    } catch (e) {
      toastInfo(msg: 'Registration failed. Please try again.');
      print('[Register] ❌ Unexpected error: $e');
    }
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
