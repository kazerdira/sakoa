import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:sakoa/firebase_options.dart';
import 'package:sakoa/common/utils/FirebaseMassagingHandler.dart';
import 'package:sakoa/common/utils/utils.dart';
import 'package:sakoa/common/store/store.dart';

import 'package:sakoa/common/services/services.dart';
import 'package:sakoa/common/services/presence_service.dart';
import 'package:sakoa/common/services/chat_manager_service.dart';
import 'package:sakoa/common/services/blocking_service.dart';
import 'package:sakoa/common/services/chat_security_service.dart';
import 'package:sakoa/common/services/voice_message_service.dart';
import 'package:sakoa/common/services/voice_cache_manager.dart';
import 'package:sakoa/common/services/message_delivery_service.dart';

import 'package:sakoa/common/repositories/chat/voice_message_repository.dart';
import 'package:sakoa/common/repositories/chat/text_message_repository.dart';
import 'package:sakoa/common/repositories/chat/image_message_repository.dart';
import 'package:sakoa/common/repositories/chat/chat_repository.dart';
import 'package:sakoa/common/repositories/contact/contact_repository.dart';
import 'package:sakoa/common/repositories/call/call_repository.dart';
import 'package:sakoa/common/repositories/auth/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    // 🔥 SUPERNOVA: Initialize Voice Message Cache Service
    print('[Global] 🚀 Initializing VoiceMessageCacheService...');
    await Get.putAsync(() => VoiceMessageCacheService().init());

    // 🔥 Initialize VoiceCacheManager
    print('[Global] 🚀 Initializing VoiceCacheManager...');
    await Get.putAsync(() => VoiceCacheManager().init());

    // 🔥 INDUSTRIAL-GRADE: Initialize Message Delivery Tracking Service
    print('[Global] 🚀 Initializing MessageDeliveryService...');
    await Get.putAsync(() => MessageDeliveryService().init());

    // 🏗️ REPOSITORY LAYER: Initialize message repositories
    print('[Global] 🚀 Initializing VoiceMessageRepository...');
    Get.put<VoiceMessageRepository>(VoiceMessageRepository(
      deliveryService: Get.find<MessageDeliveryService>(),
      voiceService: Get.find<VoiceMessageService>(),
      cacheManager: Get.find<VoiceCacheManager>(),
      db: FirebaseFirestore.instance,
    ));

    print('[Global] 🚀 Initializing TextMessageRepository...');
    Get.put<TextMessageRepository>(TextMessageRepository(
      deliveryService: Get.find<MessageDeliveryService>(),
      db: FirebaseFirestore.instance,
    ));

    print('[Global] 🚀 Initializing ImageMessageRepository...');
    Get.put<ImageMessageRepository>(ImageMessageRepository(
      deliveryService: Get.find<MessageDeliveryService>(),
      db: FirebaseFirestore.instance,
    ));

    // � Initialize Chat Repository (general chat operations)
    print('[Global] 🚀 Initializing ChatRepository...');
    Get.put<ChatRepository>(ChatRepository(
      db: FirebaseFirestore.instance,
    ));

    // �👥 Initialize Contact Repository
    print('[Global] 🚀 Initializing ContactRepository...');
    Get.put<ContactRepository>(ContactRepository(
      db: FirebaseFirestore.instance,
      blockingService: Get.find<BlockingService>(),
    ));

    // 📞 Initialize Call Repository
    print('[Global] 🚀 Initializing CallRepository...');
    Get.put<CallRepository>(CallRepository(
      db: FirebaseFirestore.instance,
    ));

    // 🔐 Initialize Auth Repository
    print('[Global] 🚀 Initializing AuthRepository...');
    Get.put<AuthRepository>(AuthRepository(
      firebaseAuth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    ));

    print('[Global] ✅ All services initialized');
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
