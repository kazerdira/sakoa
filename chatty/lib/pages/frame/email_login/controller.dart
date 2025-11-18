import 'package:flutter/material.dart';
import 'package:sakoa/common/routes/routes.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/widgets/toast.dart';
import 'package:sakoa/common/repositories/auth/auth_repository.dart';
import 'package:sakoa/common/exceptions/auth_exceptions.dart';
import 'index.dart';

class EmailLoginController extends GetxController {
  final state = EmailLoginState();
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  TextEditingController? EmailEditingController = TextEditingController();
  TextEditingController? PasswordEditingController = TextEditingController();

  EmailLoginController();

  /// Handle email/password sign-in using AuthRepository
  Future<void> handleEmailLogin() async {
    String emailAddress = state.email.value;
    String password = state.password.value;

    // Validate input
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
      // Show loading indicator
      EasyLoading.show(
        indicator: CircularProgressIndicator(),
        maskType: EasyLoadingMaskType.clear,
        dismissOnTap: false,
      );

      // Sign in using AuthRepository
      await _authRepository.signInWithEmail(
        email: emailAddress,
        password: password,
      );

      // Sign-in successful - navigate to main screen
      EasyLoading.dismiss();
      Get.offAllNamed(AppRoutes.Message);
    } on EmailVerificationException catch (e) {
      EasyLoading.dismiss();
      toastInfo(msg: e.getUserMessage());
      print('[EmailLogin] ❌ Email not verified: ${e.message}');
    } on SignInException catch (e) {
      EasyLoading.dismiss();
      toastInfo(msg: e.getUserMessage());
      print('[EmailLogin] ❌ Sign-in error: ${e.message}');
    } on AuthException catch (e) {
      EasyLoading.dismiss();
      toastInfo(msg: e.getUserMessage());
      print('[EmailLogin] ❌ Auth error: ${e.message}');
    } catch (e) {
      EasyLoading.dismiss();
      toastInfo(msg: 'Sign-in failed. Please try again.');
      print('[EmailLogin] ❌ Unexpected error: $e');
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
