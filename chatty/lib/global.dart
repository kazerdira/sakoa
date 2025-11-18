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
import 'package:sakoa/common/services/voice_cache_manager.dart'; // 🔥 Voice cache manager
import 'package:sakoa/common/services/message_delivery_service.dart'; // 🔥 INDUSTRIAL: Delivery tracking
import 'package:sakoa/common/repositories/chat_repository.dart'; // 🏗️ REPOSITORY: Business logic layer
import 'package:sakoa/common/store/store.dart';
import 'package:sakoa/common/utils/utils.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    // 🔥 SUPERNOVA: Initialize Voice Message Cache Service (Simpler & Better)
    print('[Global] 🚀 Initializing VoiceMessageCacheService...');
    await Get.putAsync(() => VoiceMessageCacheService().init());

    // 🔥 Initialize VoiceCacheManager (needed by voice player)
    print('[Global] 🚀 Initializing VoiceCacheManager...');
    await Get.putAsync(() => VoiceCacheManager().init());

    // 🔥 INDUSTRIAL-GRADE: Initialize Message Delivery Tracking Service
    print('[Global] 🚀 Initializing MessageDeliveryService...');
    await Get.putAsync(() => MessageDeliveryService().init());

    // 🏗️ REPOSITORY LAYER: Initialize ChatRepository (lazy - created when needed)
    print('[Global] 🚀 Registering ChatRepository...');
    Get.lazyPut<ChatRepository>(() => ChatRepository(
          deliveryService: Get.find<MessageDeliveryService>(),
          voiceService: Get.find<VoiceMessageService>(),
          cacheManager: Get.find<VoiceCacheManager>(),
          db: FirebaseFirestore.instance,
        ));

    print(
        '[Global] ✅ All services initialized (Presence, ChatManager, Blocking, Security, VoiceMessage, MessageDelivery, ChatRepository)');
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
