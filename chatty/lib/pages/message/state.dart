import 'package:sakoa/common/entities/entities.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageState {
  RxList<Message> msgList = <Message>[].obs;
  RxList<CallMessage> callList = <CallMessage>[].obs;
  RxBool tabStatus = true.obs;
  var head_detail = UserItem().obs;


}
