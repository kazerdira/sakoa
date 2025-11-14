// ✅ UPDATE global.dart to initialize blocking services

// 🔥 Add these imports at the top:
import 'package:sakoa/common/services/blocking_service.dart';
import 'package:sakoa/common/services/chat_security_service.dart';

// 🔥 Update the init() method in the Global class:

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

  // 🔥 NEW: Initialize BlockingService
  print('[Global] 🚀 Initializing BlockingService...');
  await Get.putAsync(() => BlockingService().init());

  // 🔥 NEW: Initialize ChatSecurityService
  print('[Global] 🚀 Initializing ChatSecurityService...');
  Get.put(ChatSecurityService());

  print('[Global] ✅ All services initialized');
}
