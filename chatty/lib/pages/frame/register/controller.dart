import 'package:flutter/material.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/routes/routes.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/store/store.dart';
import 'package:sakoa/common/utils/security.dart';
import 'package:sakoa/common/values/server.dart';
import 'package:sakoa/common/widgets/toast.dart';
import 'index.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';


class RegisterController extends GetxController {
  final state = RegisterState();
  FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController? UserNameEditingController = TextEditingController();
  TextEditingController? EmailEditingController = TextEditingController();
  TextEditingController? PasswordEditingController = TextEditingController();
  RegisterController();

  handleEmailRegister() async{
    String UserName = state.username.value;
    String emailAddress = state.email.value;
    String password = state.password.value;

    if(UserName.isEmpty){
      toastInfo(msg: "UserName not empty!");
      return;
    }
    if(emailAddress.isEmpty){
      toastInfo(msg: "Email not empty!");
      return;
    }
    if(password.isEmpty){
      toastInfo(msg: "Password not empty!");
      return;
    }
    Get.focusScope?.unfocus();
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
      print(credential);
      if(credential!=null){
        await credential.user?.sendEmailVerification();
        await credential.user?.updateDisplayName(UserName);
        String photoURL = "${SERVER_API_URL}uploads/default.png";
        await credential.user?.updatePhotoURL(photoURL);
        toastInfo(msg: "An email has been sent to your registered email. To activate your account, please open the link from the email.");
        Get.back();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        toastInfo(msg: "The password provided is too weak.");
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        toastInfo(msg: "The account already exists for that email.");
      }
    } catch (e) {
      print(e);
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
