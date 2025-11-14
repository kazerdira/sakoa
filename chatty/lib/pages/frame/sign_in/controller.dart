import 'package:sakoa/common/apis/apis.dart';
import 'package:sakoa/common/services/services.dart';
import 'package:sakoa/common/values/server.dart';
import 'package:flutter/material.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/routes/routes.dart';
import 'package:sakoa/common/store/store.dart';
import 'package:sakoa/common/utils/utils.dart';
import 'package:sakoa/common/widgets/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'index.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInController extends GetxController {
  final state = SignInState();
  SignInController();
  FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Google sign in aborted');
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithFacebook() async {
    // Trigger the sign-in flow
    final LoginResult loginResult = await FacebookAuth.instance.login();

    // Create a credential from the access token
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

    // Once signed in, return the UserCredential
    return FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
  }

  Future<UserCredential> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    return await FirebaseAuth.instance.signInWithProvider(appleProvider);
  }

  handleSignIn(String type) async {
    // type 1:email，2:google,3:facebook,4 apple,5 phone
    try {
      if (type == "email") {
        Get.toNamed(AppRoutes.EmailLogin);
      } else if (type == "phone") {
        Get.toNamed(AppRoutes.Phone);
      } else if (type == "google") {
        // Sign in with Firebase using Google (this is needed for Firestore permissions)
        var credential = await signInWithGoogle();
        print("user------");
        print(credential.user);
        if (credential.user != null) {
          String? displayName = credential.user?.displayName;
          String? email = credential.user?.email;
          String id = credential.user!.uid;
          String photoUrl = credential.user?.photoURL ??
              "${SERVER_API_URL}uploads/default.png";

          LoginRequestEntity loginPageListRequestEntity =
              new LoginRequestEntity();
          loginPageListRequestEntity.avatar = photoUrl;
          loginPageListRequestEntity.name = displayName;
          loginPageListRequestEntity.email = email;
          loginPageListRequestEntity.open_id = id;
          loginPageListRequestEntity.type = 2;
          asyncPostAllData(loginPageListRequestEntity);
        } else {
          toastInfo(msg: 'email login error');
        }

        print("googleAuth--------------------------");
      } else if (type == "facebook") {
        print("facebook--------------------------");
        var user = await signInWithFacebook();
        print(user.user);
        if (user.user != null) {
          String? displayName = user.user?.displayName;
          String? email = user.user?.email;
          String? id = user.user?.uid;
          String? photoUrl = user.user?.photoURL;

          LoginRequestEntity loginPageListRequestEntity =
              new LoginRequestEntity();
          loginPageListRequestEntity.avatar = photoUrl;
          loginPageListRequestEntity.name = displayName;
          loginPageListRequestEntity.email = email;
          loginPageListRequestEntity.open_id = id;
          loginPageListRequestEntity.type = 3;
          asyncPostAllData(loginPageListRequestEntity);
        } else {
          toastInfo(msg: 'facebook login error');
        }
      } else if (type == "apple") {
        print("apple--------------------------");
        var user = await signInWithApple();
        print(user.user);
        if (user.user != null) {
          String displayName = "apple_user";
          String email = "apple@email.com";
          String id = user.user!.uid;
          String photoUrl = "${SERVER_API_URL}uploads/default.png";
          print(photoUrl);
          print("apple uid----");
          print(id);
          LoginRequestEntity loginPageListRequestEntity =
              new LoginRequestEntity();
          loginPageListRequestEntity.avatar = photoUrl;
          loginPageListRequestEntity.name = displayName;
          loginPageListRequestEntity.email = email;
          loginPageListRequestEntity.open_id = id;
          loginPageListRequestEntity.type = 4;
          asyncPostAllData(loginPageListRequestEntity);
        } else {
          toastInfo(msg: 'apple login error');
        }
      }
    } catch (error) {
      toastInfo(msg: 'login error');
      print("signIn--------------------------");
      print(error);
    }
  }

  asyncPostAllData(LoginRequestEntity loginRequestEntity) async {
    EasyLoading.show(
        indicator: CircularProgressIndicator(),
        maskType: EasyLoadingMaskType.clear,
        dismissOnTap: true);
    try {
      var result = await UserAPI.Login(params: loginRequestEntity);
      print('Login result: $result');
      print('Login code: ${result.code}, msg: ${result.msg}');
      if (result.code == 0) {
        await UserStore.to.saveProfile(result.data!);

        // Create/update user profile in Firestore for search functionality
        try {
          var db = FirebaseFirestore.instance;
          String token = result.data!.access_token!;
          String name = result.data!.name ?? '';
          String searchName = name.toLowerCase().trim();

          await db.collection("user_profiles").doc(token).set({
            'token': token,
            'name': name,
            'avatar': result.data!.avatar ?? '',
            'email': loginRequestEntity.email ?? '',
            'online': 1, // Use integer 1 instead of boolean true
            'search_name': searchName,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          print('[SignIn] User profile created/updated in Firestore');
        } catch (firestoreError) {
          print('[SignIn] Firestore profile update error: $firestoreError');
          // Don't block login if Firestore fails
        }

        EasyLoading.dismiss();
        Get.offAllNamed(AppRoutes.Message);
      } else {
        EasyLoading.dismiss();
        // Show actual error message from API
        toastInfo(msg: result.msg ?? 'Login failed');
      }
    } catch (e) {
      EasyLoading.dismiss();
      print('Login error: $e');
      toastInfo(msg: 'Connection error: ${e.toString()}');
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
