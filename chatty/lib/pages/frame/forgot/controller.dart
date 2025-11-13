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


class ForgotController extends GetxController {
  final state = ForgotState();
  FirebaseAuth _auth = FirebaseAuth.instance;
  TextEditingController? EmailEditingController = TextEditingController();
  ForgotController();

  handleEmailForgot() async{
    String emailAddress = state.email.value;
    if(emailAddress.isEmpty){
      toastInfo(msg: "Email not empty!");
      return;
    }
    Get.focusScope?.unfocus();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailAddress);
      toastInfo(msg: "An email has been sent to your registered email. To activate your account, please open the link from the email.");
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
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      print(user);
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
