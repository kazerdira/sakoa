import 'dart:convert';

import 'package:sakoa/common/apis/apis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/store/store.dart';
import 'index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactController extends GetxController {
  ContactController();
  final ContactState state = ContactState();
  final db = FirebaseFirestore.instance;
  final token = UserStore.to.profile.token;


  goChat(ContactItem contactItem) async{

    var from_messages = await db.collection("message").withConverter(
      fromFirestore: Msg.fromFirestore,
      toFirestore: (Msg msg, options) => msg.toFirestore(),
    ).where("from_token", isEqualTo: token).where("to_token", isEqualTo: contactItem.token).get();
    var to_messages = await db.collection("message").withConverter(
      fromFirestore: Msg.fromFirestore,
      toFirestore: (Msg msg, options) => msg.toFirestore(),
    ).where("from_token", isEqualTo: contactItem.token).where("to_token", isEqualTo: token).get();

    if(from_messages.docs.isEmpty && to_messages.docs.isEmpty){
      print("----from_messages--to_messages--empty--");
       var profile = UserStore.to.profile;
       var msgdata = new Msg(
        from_token:profile.token,
        to_token:contactItem.token,
        from_name:profile.name,
        to_name:contactItem.name,
        from_avatar:profile.avatar,
        to_avatar:contactItem.avatar,
        from_online:profile.online,
        to_online:contactItem.online,
        last_msg:"",
        last_time:Timestamp.now(),
        msg_num:0,
      );
      var doc_id = await db.collection("message").withConverter(
        fromFirestore: Msg.fromFirestore,
        toFirestore: (Msg msg, options) => msg.toFirestore(),
      ).add(msgdata);
      Get.offAndToNamed("/chat", parameters: {"doc_id": doc_id.id,"to_token":contactItem.token??"","to_name":contactItem.name??"","to_avatar":contactItem.avatar??"","to_online":contactItem.online.toString()});
    }else{
      if(!from_messages.docs.isEmpty){
        print("---from_messages");
        print(from_messages.docs.first.id);
        Get.offAndToNamed("/chat", parameters: {"doc_id": from_messages.docs.first.id,"to_token":contactItem.token??"","to_name":contactItem.name??"","to_avatar":contactItem.avatar??"","to_online":contactItem.online.toString()});
      }
      if(!to_messages.docs.isEmpty){
        print("---to_messages");
        print(to_messages.docs.first.id);
        Get.offAndToNamed("/chat", parameters: {"doc_id": to_messages.docs.first.id,"to_token":contactItem.token??"","to_name":contactItem.name??"","to_avatar":contactItem.avatar??"","to_online":contactItem.online.toString()});
      }

    }

  }
  
  // 拉取数据
  asyncLoadAllData() async {
    EasyLoading.show(
        indicator: CircularProgressIndicator(),
        maskType: EasyLoadingMaskType.clear,
        dismissOnTap: true);
    state.contactList.clear();
    var result = await ContactAPI.post_contact();
    print(result.data!);
    if(result.code==0){
      state.contactList.addAll(result.data!);
    }
    EasyLoading.dismiss();
  }
  /// 初始
  @override
  void onInit() {
    super.onInit();

  }
  @override
  void onReady() {
    super.onReady();
   asyncLoadAllData();
  }
  @override
  void onClose() {
    super.onClose();
  }
  @override
  void dispose() {
    super.dispose();

  }
}
