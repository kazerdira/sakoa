import 'dart:io';
import 'package:sakoa/common/apis/apis.dart';
import 'package:sakoa/common/services/services.dart';
import 'package:flutter/material.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/store/store.dart';
import 'package:sakoa/common/widgets/toast.dart';
import 'package:image_picker/image_picker.dart';
import 'index.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileController extends GetxController {
  final state = ProfileState();
  TextEditingController? NameEditingController = TextEditingController();
  TextEditingController? DescriptionEditingController = TextEditingController();
  File? _photo;
  final ImagePicker _picker = ImagePicker();
  ProfileController();

  goSave() async {
    if (state.profile_detail.value.name == null ||
        state.profile_detail.value.name!.isEmpty) {
      toastInfo(msg: "name not empty!");
      return;
    }
    if (state.profile_detail.value.description == null ||
        state.profile_detail.value.description!.isEmpty) {
      toastInfo(msg: "description not empty!");
      return;
    }
    if (state.profile_detail.value.avatar == null ||
        state.profile_detail.value.avatar!.isEmpty) {
      toastInfo(msg: "avatar not empty!");
      return;
    }

    LoginRequestEntity updateProfileRequestEntity = new LoginRequestEntity();
    var userItem = state.profile_detail.value;
    updateProfileRequestEntity.avatar = userItem.avatar;
    updateProfileRequestEntity.name = userItem.name;
    updateProfileRequestEntity.description = userItem.description;
    updateProfileRequestEntity.online = userItem.online;

    var result =
        await UserAPI.UpdateProfile(params: updateProfileRequestEntity);
    print(result.code);
    print(result.msg);
    if (result.code == 0) {
      UserItem userItem = state.profile_detail.value;
      await UserStore.to.saveProfile(userItem);
      Get.back(result: "finish");
    }
  }

  goLogout() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    await UserStore.to.onLogout();
  }

  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _photo = File(pickedFile.path);
      uploadFile();
    } else {
      print('No image selected.');
    }
  }

  Future imgFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _photo = File(pickedFile.path);
      uploadFile();
    } else {
      print('No image selected.');
    }
  }

  Future uploadFile() async {
    // if (_photo == null) return;
    // print(_photo);
    var result = await ChatAPI.upload_img(file: _photo);
    print(result.data);
    if (result.code == 0) {
      state.profile_detail.value.avatar = result.data;
      state.profile_detail.refresh();
    } else {
      toastInfo(msg: "image error");
    }
  }

  asyncLoadAllData() async {
    // await
  }

  @override
  void onInit() {
    super.onInit();
    var userItem = Get.arguments;
    if (userItem != null) {
      state.profile_detail.value = userItem;
      if (state.profile_detail.value.name != null) {
        NameEditingController?.text = state.profile_detail.value.name!;
      }
      if (state.profile_detail.value.description != null) {
        DescriptionEditingController?.text =
            state.profile_detail.value.description!;
      }
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
