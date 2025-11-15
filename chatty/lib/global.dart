import 'package:sakoa/common/utils/FirebaseMassagingHandler.dart';
import 'package:sakoa/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakoa/common/services/services.dart';
import 'package:sakoa/common/services/presence_service.dart';
import 'package:sakoa/common/services/chat_manager_service.dart';
import 'package:sakoa/common/services/blocking_service.dart';
import 'package:sakoa/common/services/chat_security_service.dart';
import 'package:sakoa/common/services/voice_message_service.dart'; // 🔥 Voice messaging
import 'package:sakoa/common/services/message_delivery_service.dart'; // 🔥 INDUSTRIAL: Delivery tracking
import 'package:sakoa/common/store/store.dart';
import 'package:sakoa/common/utils/utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class Global {
  static Future init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    setSystemUi();
    Loading();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await Get.putAsync<StorageService>(() => StorageService().init());
    Get.put<ConfigStore>(ConfigStore());
    Get.put<UserStore>(UserStore());

    // 🔥 Initialize industrial-grade services
    print('[Global] 🚀 Initializing PresenceService...');
    await Get.putAsync(() => PresenceService().init());

    print('[Global] 🚀 Initializing ChatManagerService...');
    Get.put(ChatManagerService());

    print('[Global] 🚀 Initializing BlockingService...');
    await Get.putAsync(() => BlockingService().init());

    print('[Global] 🚀 Initializing ChatSecurityService...');
    Get.put(ChatSecurityService());

    // 🔥 Initialize Voice Message Service
    print('[Global] 🚀 Initializing VoiceMessageService...');
    await Get.putAsync(() => VoiceMessageService().init());

    // 🔥 INDUSTRIAL-GRADE: Initialize Message Delivery Tracking Service
    print('[Global] 🚀 Initializing MessageDeliveryService...');
    await Get.putAsync(() => MessageDeliveryService().init());

    print(
        '[Global] ✅ All services initialized (Presence, ChatManager, Blocking, Security, VoiceMessage, MessageDelivery)');
  }

  static void setSystemUi() {
    if (GetPlatform.isAndroid) {
      SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      );
      SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);
    }
  }
}
