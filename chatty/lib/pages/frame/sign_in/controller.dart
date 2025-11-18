import 'package:flutter/material.dart';
import 'package:sakoa/common/routes/routes.dart';
import 'package:sakoa/common/widgets/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/repositories/auth/auth_repository.dart';
import 'package:sakoa/common/exceptions/auth_exceptions.dart';
import 'index.dart';

class SignInController extends GetxController {
  final state = SignInState();
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  SignInController();

  /// Handle sign-in for different providers
  /// Uses AuthRepository to handle all authentication logic
  Future<void> handleSignIn(String type) async {
    // type: "email", "phone", "google", "facebook", "apple"
    try {
      // Navigate to specific login pages for email and phone
      if (type == "email") {
        Get.toNamed(AppRoutes.EmailLogin);
        return;
      } else if (type == "phone") {
        Get.toNamed(AppRoutes.Phone);
        return;
      }

      // Show loading indicator for social sign-in
      EasyLoading.show(
        indicator: CircularProgressIndicator(),
        maskType: EasyLoadingMaskType.clear,
        dismissOnTap: false,
      );

      // Call appropriate repository method based on provider
      if (type == "google") {
        await _authRepository.signInWithGoogle();
      } else if (type == "facebook") {
        await _authRepository.signInWithFacebook();
      } else if (type == "apple") {
        await _authRepository.signInWithApple();
      } else {
        EasyLoading.dismiss();
        toastInfo(msg: 'Unknown sign-in type');
        return;
      }

      // Sign-in successful - navigate to main screen
      EasyLoading.dismiss();
      Get.offAllNamed(AppRoutes.Message);
    } on SignInException catch (e) {
      EasyLoading.dismiss();
      toastInfo(msg: e.getUserMessage());
      print('[SignIn] ❌ Sign-in error: ${e.message}');
    } on AuthException catch (e) {
      EasyLoading.dismiss();
      toastInfo(msg: e.getUserMessage());
      print('[SignIn] ❌ Auth error: ${e.message}');
    } catch (e) {
      EasyLoading.dismiss();
      toastInfo(msg: 'Sign-in failed. Please try again.');
      print('[SignIn] ❌ Unexpected error: $e');
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
