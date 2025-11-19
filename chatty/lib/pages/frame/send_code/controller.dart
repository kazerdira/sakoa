import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/widgets/toast.dart';
import 'package:sakoa/common/repositories/auth/auth_repository.dart';
import 'package:sakoa/common/exceptions/auth_exceptions.dart';
import 'index.dart';

class SendCodeController extends GetxController {
  final state = SendCodeState();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  TextEditingController? EmailEditingController = TextEditingController();
  SendCodeController();
  String verificationId = "";

  void submitOTP() async {
    // get the `smsCode` from the user
    String smsCode = state.verifycode.value;
    if (smsCode.isEmpty) {
      toastInfo(msg: "SMS code cannot be empty!");
      return;
    }
    Get.focusScope?.unfocus();

    try {
      EasyLoading.show(
          indicator: CircularProgressIndicator(),
          maskType: EasyLoadingMaskType.clear,
          dismissOnTap: false);

      // Use AuthRepository to sign in with phone (verificationId + smsCode)
      await _authRepository.signInWithPhone(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // On success, repository already handles backend login/profile saving
      EasyLoading.dismiss();
      Get.offAllNamed(AppRoutes.Message);
    } on PhoneAuthException catch (e) {
      EasyLoading.dismiss();
      toastInfo(msg: e.getUserMessage());
      print('[SendCode] ❌ Phone auth error: ${e.message}');
    } on AuthException catch (e) {
      EasyLoading.dismiss();
      toastInfo(msg: e.getUserMessage());
      print('[SendCode] ❌ Auth error: ${e.message}');
    } catch (e) {
      EasyLoading.dismiss();
      toastInfo(msg: 'Sign-in failed. Please try again.');
      print('[SendCode] ❌ Unexpected error: $e');
    }
  }

  @override
  void onReady() {
    super.onReady();
    var data = Get.parameters;
    print(data);
    verificationId = data["verificationId"] ?? "";
  }

  @override
  void dispose() {
    super.dispose();
  }
}
