import 'dart:convert';

import 'package:sakoa/common/apis/apis.dart';
import 'package:sakoa/common/routes/names.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'state.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sakoa/common/store/store.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MessageController extends GetxController with WidgetsBindingObserver {
  MessageController();

  final MessageState state = MessageState();
  final token = UserStore.to.profile.token;
  final db = FirebaseFirestore.instance;

  goProfile() async {
    var result = await Get.toNamed(AppRoutes.Profile,
        arguments: state.head_detail.value);
    if (result == "finish") {
      getProfile();
    }
  }

  goTabStatus() async {
    EasyLoading.show(
        indicator: CircularProgressIndicator(),
        maskType: EasyLoadingMaskType.clear,
        dismissOnTap: true);
    state.tabStatus.value = !state.tabStatus.value;
    if (state.tabStatus.value) {
      asyncLoadMsgData();
    } else {
      asyncLoadCallData();
    }
    EasyLoading.dismiss();
  }

  asyncLoadMsgData() async {
    print("-----------state.msgList");
    print(state.msgList);
    var token = UserStore.to.profile.token;

    var from_messages = await db
        .collection("message")
        .withConverter(
          fromFirestore: Msg.fromFirestore,
          toFirestore: (Msg msg, options) => msg.toFirestore(),
        )
        .where("from_token", isEqualTo: token)
        .get();
    print(from_messages.docs.length);

    var to_messages = await db
        .collection("message")
        .withConverter(
          fromFirestore: Msg.fromFirestore,
          toFirestore: (Msg msg, options) => msg.toFirestore(),
        )
        .where("to_token", isEqualTo: token)
        .get();
    print("to_messages.docs.length------------");
    print(to_messages.docs.length);
    state.msgList.clear();

    if (from_messages.docs.isNotEmpty) {
      await addMessage(from_messages.docs);
    }
    if (to_messages.docs.isNotEmpty) {
      await addMessage(to_messages.docs);
    }
    // sort
    state.msgList.sort((a, b) {
      if (b.last_time == null) {
        return 0;
      }
      if (a.last_time == null) {
        return 0;
      }
      return b.last_time!.compareTo(a.last_time!);
    });
  }

  addMessage(List<QueryDocumentSnapshot<Msg>> data) async {
    data.forEach((element) {
      var item = element.data();
      Message message = new Message();
      message.doc_id = element.id;
      message.last_time = item.last_time;
      message.msg_num = item.msg_num;
      message.last_msg = item.last_msg;
      if (item.from_token == token) {
        message.name = item.to_name;
        message.avatar = item.to_avatar;
        message.token = item.to_token;
        message.online = item.to_online;
        message.msg_num = item.to_msg_num ?? 0;
      } else {
        message.name = item.from_name;
        message.avatar = item.from_avatar;
        message.token = item.from_token;
        message.online = item.from_online;
        message.msg_num = item.from_msg_num ?? 0;
      }
      state.msgList.add(message);
    });
  }

  _snapshots() async {
    var token = UserStore.to.profile.token;
    print("token--------");
    print(token);

    final toMessageRef = db
        .collection("message")
        .withConverter(
          fromFirestore: Msg.fromFirestore,
          toFirestore: (Msg msg, options) => msg.toFirestore(),
        )
        .where("to_token", isEqualTo: token);
    final fromMessageRef = db
        .collection("message")
        .withConverter(
          fromFirestore: Msg.fromFirestore,
          toFirestore: (Msg msg, options) => msg.toFirestore(),
        )
        .where("from_token", isEqualTo: token);
    toMessageRef.snapshots().listen(
      (event) async {
        print("snapshotslisten-----------");
        print(event.metadata.isFromCache);
        await asyncLoadMsgData();
        // if(!event.metadata.isFromCache){
        //
        // }
        print("snapshotslisten-----------");
      },
      onError: (error) => print("Listen failed: $error"),
    );
    fromMessageRef.snapshots().listen(
      (event) async {
        print("snapshotslisten-----------");
        print(event.metadata.isFromCache);
        await asyncLoadMsgData();
        print("snapshotslisten-----------");
      },
      onError: (error) => print("Listen failed: $error"),
    );
  }

  asyncLoadCallData() async {
    state.callList.clear();
    var token = UserStore.to.profile.token;

    var from_chatcall = await db
        .collection("chatcall")
        .withConverter(
          fromFirestore: ChatCall.fromFirestore,
          toFirestore: (ChatCall msg, options) => msg.toFirestore(),
        )
        .where("from_token", isEqualTo: token)
        .limit(30)
        .get();
    var to_chatcall = await db
        .collection("chatcall")
        .withConverter(
          fromFirestore: ChatCall.fromFirestore,
          toFirestore: (ChatCall msg, options) => msg.toFirestore(),
        )
        .where("to_token", isEqualTo: token)
        .limit(30)
        .get();

    if (from_chatcall.docs.isNotEmpty) {
      await addCall(from_chatcall.docs);
    }
    if (to_chatcall.docs.isNotEmpty) {
      await addCall(to_chatcall.docs);
    }
    // sort
    state.callList.sort((a, b) {
      if (b.last_time == null) {
        return 0;
      }
      if (a.last_time == null) {
        return 0;
      }
      return b.last_time!.compareTo(a.last_time!);
    });
  }

  addCall(List<QueryDocumentSnapshot<ChatCall>> data) async {
    data.forEach((element) {
      var item = element.data();
      CallMessage message = new CallMessage();
      message.doc_id = element.id;
      message.last_time = item.last_time;
      message.call_time = item.call_time;
      message.type = item.type;
      if (item.from_token == token) {
        message.name = item.to_name;
        message.avatar = item.to_avatar;
        message.token = item.to_token;
      } else {
        message.name = item.from_name;
        message.avatar = item.from_avatar;
        message.token = item.from_token;
      }
      state.callList.add(message);
    });
  }

  getProfile() async {
    var Profile = await UserStore.to.profile;
    print(Profile);
    state.head_detail.value = Profile;
    state.head_detail.refresh();
  }

  fireMessage() async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    print(fcmToken);
    if (fcmToken != null) {
      BindFcmTokenRequestEntity bindFcmTokenRequestEntity =
          new BindFcmTokenRequestEntity();
      bindFcmTokenRequestEntity.fcmtoken = fcmToken;
      await ChatAPI.bind_fcmtoken(params: bindFcmTokenRequestEntity);
    }
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print("\n notification on onMessageOpenedApp function \n");
      print(message.data);
      if (message.data["call_type"] != null) {
        //  ////1. voice 2. video 3. text, 4.cancel
        if (message.data["call_type"] == "text") {
          //  FirebaseMassagingHandler.flutterLocalNotificationsPlugin.cancelAll();
          var data = message.data;
          var to_token = data["token"];
          var to_name = data["name"];
          var to_avatar = data["avatar"];
          //  var doc_id = data["doc_id"];
          if (to_token != null && to_name != null && to_avatar != null) {
            var item = state.msgList
                .where((element) => element.token == to_token)
                .first;
            print(item);
            if (Get.currentRoute.contains(AppRoutes.Message)) {
              Get.toNamed("/chat", parameters: {
                "doc_id": item.doc_id!,
                "to_token": item.token!,
                "to_name": item.name!,
                "to_avatar": item.avatar!,
                "to_online": item.online.toString()
              });
            }
          }
        }
      }
    });
  }

  sendNotifications(String call_type, String to_token, String to_avatar,
      String to_name, String doc_id) async {
    CallRequestEntity callRequestEntity = new CallRequestEntity();
    callRequestEntity.call_type = call_type;
    callRequestEntity.to_token = to_token;
    callRequestEntity.to_avatar = to_avatar;
    callRequestEntity.doc_id = doc_id;
    callRequestEntity.to_name = to_name;
    var res = await ChatAPI.call_notifications(params: callRequestEntity);
    print("sendNotifications");
    print(res);
    if (res.code == 0) {
      print("sendNotifications success");
    } else {
      // Get.snackbar("Tips", "Notification error!");
      // Get.offAllNamed(AppRoutes.Message);
    }
  }

  /// 初始
  @override
  void onInit() {
    super.onInit();
    getProfile();
    _snapshots();
  }

  @override
  void onReady() async {
    super.onReady();
    fireMessage();
    WidgetsBinding.instance.addObserver(this);
    await CallVocieOrVideo();
  }

  @override
  void onClose() {
    super.onClose();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print("-didChangeAppLifecycleState-" + state.toString());
    switch (state) {
      case AppLifecycleState.inactive: // 处于这种状态的应用程序应该假设它们可能在任何时候暂停。
        print("AppLifecycleState.inactive-----");
        break;
      case AppLifecycleState.resumed: //从后台切换前台，界面可见
        print("AppLifecycleState.resumed------");
        await CallVocieOrVideo();
        break;
      case AppLifecycleState.paused: // 界面不可见，后台
        print("AppLifecycleState.paused-----");
        break;
      case AppLifecycleState.detached: // APP结束时调用
        print("AppLifecycleState.detached------");
        break;
      case AppLifecycleState.hidden: // 新增的状态
        print("AppLifecycleState.hidden------");
        break;
    }
  }

  CallVocieOrVideo() async {
    var _prefs = await SharedPreferences.getInstance();
    await _prefs.reload();
    var res = await _prefs.getString("CallVocieOrVideo") ?? "";
    print("goProfile------");
    print(res);
    if (res.isNotEmpty) {
      var data = jsonDecode(res);
      await _prefs.setString("CallVocieOrVideo", "");
      print(data);
      // "call_role":"audience",
      String to_token = data["to_token"];
      String to_name = data["to_name"];
      String to_avatar = data["to_avatar"];
      String call_type = data["call_type"];
      String doc_id = data["doc_id"] ?? "";
      DateTime expire_time = DateTime.parse(data["expire_time"]);
      DateTime nowtime = DateTime.now();
      var Seconds = nowtime.difference(expire_time).inSeconds;
      print("Seconds------");
      print(Seconds);

      if (Seconds < 30) {
        String title = "";
        String appRoute = "";
        if (call_type == "voice") {
          title = "Voice call";
          appRoute = AppRoutes.VoiceCall;
        } else {
          title = "Video call";
          appRoute = AppRoutes.VideoCall;
        }

        Get.snackbar(
            icon: Container(
              width: 40.w,
              height: 40.w,
              padding: EdgeInsets.all(0.w),
              decoration: BoxDecoration(
                image: DecorationImage(
                    fit: BoxFit.fill, image: NetworkImage(to_avatar)),
                borderRadius: BorderRadius.all(Radius.circular(20.w)),
              ),
            ),
            "${to_name}",
            "${title}",
            duration: Duration(seconds: 30),
            isDismissible: false,
            mainButton: TextButton(
                onPressed: () {},
                child: Container(
                    width: 90.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (Get.isSnackbarOpen) {
                              Get.closeAllSnackbars();
                            }
                            sendNotifications(
                                "cancel", to_token, to_avatar, to_name, doc_id);
                          },
                          child: Container(
                            width: 40.w,
                            height: 40.w,
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: AppColors.primaryElementBg,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30.w)),
                            ),
                            child: Image.asset("assets/icons/a_phone.png"),
                          ),
                        ),
                        GestureDetector(
                            onTap: () {
                              if (Get.isSnackbarOpen) {
                                Get.closeAllSnackbars();
                              }
                              Get.toNamed(appRoute, parameters: {
                                "to_token": to_token,
                                "to_name": to_name,
                                "to_avatar": to_avatar,
                                "doc_id": doc_id,
                                "call_role": "audience"
                              });
                            },
                            child: Container(
                              width: 40.w,
                              height: 40.w,
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: AppColors.primaryElementStatus,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(30.w)),
                              ),
                              child:
                                  Image.asset("assets/icons/a_telephone.png"),
                            ))
                      ],
                    ))));
      }
    }
  }
}
