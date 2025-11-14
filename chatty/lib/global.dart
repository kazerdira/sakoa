import 'package:sakoa/common/utils/FirebaseMassagingHandler.dart';
import 'package:sakoa/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sakoa/common/services/services.dart';
import 'package:sakoa/common/services/presence_service.dart';
import 'package:sakoa/common/services/chat_manager_service.dart';
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
