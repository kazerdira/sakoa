import 'dart:convert';

import 'package:sakoa/common/apis/apis.dart';
import 'package:sakoa/common/routes/names.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:sakoa/common/services/chat_manager_service.dart';
import 'package:sakoa/common/services/presence_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sakoa/common/store/store.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sakoa/pages/contact/index.dart';

/// 🔥 INDUSTRIAL-GRADE MESSAGE CONTROLLER
/// Professional state management with:
/// - Smart chat filtering (blocks, non-contacts, empty chats)
/// - Real-time presence updates
/// - Optimistic UI updates
/// - Sophisticated error handling
/// - Performance optimization
class MessageController extends GetxController with WidgetsBindingObserver {
  MessageController();

  final MessageState state = MessageState();
  final token = UserStore.to.profile.token;
  final db = FirebaseFirestore.instance;
  
  // Service dependencies
  late final ChatManagerService _chatManager;
  late final PresenceService _presence;
  
  // Real-time listeners
  var _chatListListener;
  final _presenceListeners = <String, StreamSubscription>{};

  // ============ LIFECYCLE ============
  
  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    getProfile();
  }
  
  @override
  void onReady() async {
    super.onReady();
    fireMessage();
    WidgetsBinding.instance.addObserver(this);
    await CallVocieOrVideo();
    
    // Start loading chats
    await _loadChats();
    _setupRealtimeListeners();
  }
  
  @override
  void onClose() {
    _teardownListeners();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
  
  /// Initialize service dependencies
  void _initializeServices() {
    try {
      _chatManager = Get.find<ChatManagerService>();
      _presence = Get.find<PresenceService>();
    } catch (e) {
      print('[MessageController] ⚠️ Services not found, initializing...');
      Get.put(ChatManagerService());
      Get.put(PresenceService());
      _chatManager = Get.find<ChatManagerService>();
      _presence = Get.find<PresenceService>();
    }
  }
  
  // ============ APP LIFECYCLE MANAGEMENT ============
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) async {
    print("[MessageController] App state: $lifecycleState");
    
    switch (lifecycleState) {
      case AppLifecycleState.resumed:
        // App came to foreground
        await _presence.setOnline();
        await _loadChats();
        await CallVocieOrVideo();
        break;
        
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background/closed
        await _presence.setOffline();
        break;
        
      case AppLifecycleState.inactive:
        // Transitioning state
        break;
    }
  }
  
  // ============ CHAT LOADING ============
  
  /// Load and filter chat list intelligently
  Future<void> _loadChats() async {
    try {
      state.isLoading.value = true;
      
      // Get filtered chats (excludes blocked, non-contacts, empty)
      final chats = await _chatManager.getFilteredChatList();
      
      state.msgList.value = chats;
      
      // Start presence listeners for visible chats
      _startPresenceListenersForChats(chats);
      
      print('[MessageController] ✅ Loaded ${chats.length} chats');
    } catch (e) {
      print('[MessageController] ❌ Failed to load chats: $e');
    } finally {
      state.isLoading.value = false;
    }
  }
  
  /// Setup real-time listeners for chat updates
  void _setupRealtimeListeners() {
    _teardownListeners(); // Clean up old listeners
    
    // Listen to my outgoing chats
    final fromRef = db
        .collection("message")
        .where("from_token", isEqualTo: token);
    
    // Listen to my incoming chats
    final toRef = db
        .collection("message")
        .where("to_token", isEqualTo: token);
    
    _chatListListener = [
      fromRef.snapshots().listen((event) => _handleChatUpdate()),
      toRef.snapshots().listen((event) => _handleChatUpdate()),
    ];
    
    print('[MessageController] ✅ Real-time listeners active');
  }
  
  /// Handle chat list updates
  Future<void> _handleChatUpdate() async {
    print('[MessageController] 🔄 Chat update detected');
    await _loadChats();
  }
  
  /// Teardown all listeners
  void _teardownListeners() {
    if (_chatListListener != null) {
      if (_chatListListener is List) {
        for (var listener in _chatListListener) {
          listener?.cancel();
        }
      } else {
        _chatListListener?.cancel();
      }
      _chatListListener = null;
    }
    
    // Cancel presence listeners
    for (var listener in _presenceListeners.values) {
      listener.cancel();
    }
    _presenceListeners.clear();
  }
  
  // ============ PRESENCE MANAGEMENT ============
  
  /// Start presence listeners for visible chats
  void _startPresenceListenersForChats(List<Message> chats) {
    // Cancel old listeners
    for (var listener in _presenceListeners.values) {
      listener.cancel();
    }
    _presenceListeners.clear();
    
    // Start new listeners
    for (var chat in chats) {
      if (chat.token == null) continue;
      
      final listener = _presence.watchPresence(chat.token!).listen((presence) {
        // Update online status in chat list
        final index = state.msgList.indexWhere((c) => c.token == chat.token);
        if (index != -1) {
          state.msgList[index].online = presence.online;
          state.msgList.refresh();
        }
      });
      
      _presenceListeners[chat.token!] = listener;
    }
    
    print('[MessageController] ✅ Started ${_presenceListeners.length} presence listeners');
  }
  
  // ============ NAVIGATION ============
  
  /// Navigate to profile
  goProfile() async {
    var result = await Get.toNamed(AppRoutes.Profile,
        arguments: state.head_detail.value);
    if (result == "finish") {
      getProfile();
    }
  }
  
  /// Navigate to contact page
  goContact() {
    Get.toNamed(AppRoutes.Contact);
  }
  
  /// Switch between chat and call tabs
  goTabStatus() async {
    EasyLoading.show(
        indicator: CircularProgressIndicator(),
        maskType: EasyLoadingMaskType.clear,
        dismissOnTap: true);
    
    state.tabStatus.value = !state.tabStatus.value;
    
    if (state.tabStatus.value) {
      await _loadChats();
    } else {
      await asyncLoadCallData();
    }
    
    EasyLoading.dismiss();
  }
  
  // ============ CALL DATA (Legacy) ============
  
  asyncLoadCallData() async {
    state.callList.clear();
    
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
    
    // Sort by time
    state.callList.sort((a, b) {
      if (b.last_time == null || a.last_time == null) return 0;
      return b.last_time!.compareTo(a.last_time!);
    });
  }

  addCall(List<QueryDocumentSnapshot<ChatCall>> data) async {
    data.forEach((element) {
      var item = element.data();
      CallMessage message = CallMessage();
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
  
  // ============ PROFILE ============
  
  getProfile() async {
    var profile = await UserStore.to.profile;
    state.head_detail.value = profile;
    state.head_detail.refresh();
  }
  
  // ============ FIREBASE MESSAGING ============
  
  fireMessage() async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    
    if (fcmToken != null) {
      BindFcmTokenRequestEntity bindFcmTokenRequestEntity =
          BindFcmTokenRequestEntity();
      bindFcmTokenRequestEntity.fcmtoken = fcmToken;
      await ChatAPI.bind_fcmtoken(params: bindFcmTokenRequestEntity);
    }
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print("\n 📬 Notification opened app \n");
      
      if (message.data["call_type"] != null) {
        if (message.data["call_type"] == "text") {
          var data = message.data;
          var to_token = data["token"];
          var to_name = data["name"];
          var to_avatar = data["avatar"];
          
          if (to_token != null && to_name != null && to_avatar != null) {
            var item = state.msgList
                .firstWhereOrNull((element) => element.token == to_token);
            
            if (item != null && Get.currentRoute.contains(AppRoutes.Message)) {
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
    CallRequestEntity callRequestEntity = CallRequestEntity();
    callRequestEntity.call_type = call_type;
    callRequestEntity.to_token = to_token;
    callRequestEntity.to_avatar = to_avatar;
    callRequestEntity.doc_id = doc_id;
    callRequestEntity.to_name = to_name;
    
    var res = await ChatAPI.call_notifications(params: callRequestEntity);
    
    if (res.code == 0) {
      print("📬 Notification sent successfully");
    }
  }

  CallVocieOrVideo() async {
    var _prefs = await SharedPreferences.getInstance();
    await _prefs.reload();
    var res = await _prefs.getString("CallVocieOrVideo") ?? "";
    
    if (res.isNotEmpty) {
      var data = jsonDecode(res);
      await _prefs.setString("CallVocieOrVideo", "");
      
      String to_token = data["to_token"];
      String to_name = data["to_name"];
      String to_avatar = data["to_avatar"];
      String call_type = data["call_type"];
      String doc_id = data["doc_id"] ?? "";
      DateTime expire_time = DateTime.parse(data["expire_time"]);
      DateTime nowtime = DateTime.now();
      var seconds = nowtime.difference(expire_time).inSeconds;

      if (seconds < 30) {
        String title = call_type == "voice" ? "Voice call" : "Video call";
        String appRoute = call_type == "voice" ? AppRoutes.VoiceCall : AppRoutes.VideoCall;

        Get.snackbar(
          icon: Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.fill,
                image: NetworkImage(to_avatar)
              ),
              borderRadius: BorderRadius.circular(20.w),
            ),
          ),
          to_name,
          title,
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
                      sendNotifications("cancel", to_token, to_avatar, to_name, doc_id);
                    },
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryElementBg,
                        borderRadius: BorderRadius.circular(30.w),
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
                        borderRadius: BorderRadius.circular(30.w),
                      ),
                      child: Image.asset("assets/icons/a_telephone.png"),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    }
  }
  
  // ============ REFRESH ============
  
  /// Pull-to-refresh
  Future<void> refreshChats() async {
    await _loadChats();
  }
}
