import 'dart:convert';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/routes/names.dart';
import 'package:sakoa/common/services/services.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserStore extends GetxController {
  static UserStore get to => Get.find();

  // 是否登录
  final _isLogin = false.obs;
  // 令牌 token
  String token = '';
  // 用户 profile
  final _profile = UserItem().obs;

  bool get isLogin => _isLogin.value;
  UserItem get profile => _profile.value;
  bool get hasToken => token.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    token = StorageService.to.getString(STORAGE_USER_TOKEN_KEY);
    var profileOffline = StorageService.to.getString(STORAGE_USER_PROFILE_KEY);
    if (profileOffline.isNotEmpty) {
      _isLogin.value = true;
      _profile(UserItem.fromJson(jsonDecode(profileOffline)));
    }
  }

  // 保存 token
  Future<void> setToken(String value) async {
    await StorageService.to.setString(STORAGE_USER_TOKEN_KEY, value);
    token = value;
  }

  // 获取 profile
  Future<String> getProfile() async {
    if (token.isEmpty) return "";
    // var result = await UserAPI.profile();
    // _profile(result);
    // _isLogin.value = true;
    return StorageService.to.getString(STORAGE_USER_PROFILE_KEY);
  }

  // 保存 profile
  Future<void> saveProfile(UserItem profile) async {
    _isLogin.value = true;
    StorageService.to.setString(STORAGE_USER_PROFILE_KEY, jsonEncode(profile));
    _profile(profile);
    // ✅ CORRECT: access_token is for API authentication (Bearer token)
    // profile.access_token = JWT token for HTTP requests (changes on login)
    // profile.token = Firestore permanent user ID (never changes)
    setToken(profile.access_token!);
  }

  // 注销
  Future<void> onLogout() async {
    // if (_isLogin.value) await UserAPI.logout();

    // 🔥 CRITICAL: Stop heartbeat timer and set offline via PresenceService
    try {
      final presenceService = Get.find<PresenceService>();
      presenceService.stopHeartbeat(); // Stop the heartbeat timer
      await presenceService.setOffline(); // Set offline in Firestore
      print('[UserStore] ✅ Stopped heartbeat and set offline on logout');
    } catch (e) {
      print(
          '[UserStore] ⚠️ PresenceService not available, manual fallback: $e');
      // Fallback to manual update if service not found
      try {
        final userToken = profile.token ?? token;
        if (userToken.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection("user_profiles")
              .doc(userToken)
              .update({'online': 0});
          print('[UserStore] ✅ Set online status to 0 on logout (fallback)');
        }
      } catch (e2) {
        print('[UserStore] ⚠️ Failed to update online status on logout: $e2');
      }
    }

    await StorageService.to.remove(STORAGE_USER_TOKEN_KEY);
    await StorageService.to.remove(STORAGE_USER_PROFILE_KEY);
    _isLogin.value = false;
    token = '';
    Get.offAllNamed(AppRoutes.SIGN_IN);
  }
}
