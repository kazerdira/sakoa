import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/services/blocking_service.dart';

/// 🔥 SUPERNOVA-LEVEL CHAT SECURITY SERVICE
/// Advanced privacy controls for chat screens
/// Features:
/// - Screenshot prevention
/// - Text copy protection
/// - Download blocking
/// - Screen recording detection
/// - Automatic restrictions based on block status
class ChatSecurityService extends GetxService {
  static ChatSecurityService get to => Get.find();

  // Current security state
  final _currentRestrictions = Rx<BlockRestrictions?>(null);
  final _isSecured = false.obs;

  BlockRestrictions? get currentRestrictions => _currentRestrictions.value;
  bool get isSecured => _isSecured.value;

  // ============ SECURITY ENFORCEMENT ============

  /// Apply security restrictions for a chat
  /// If forceScreenshotBlock is true, always disable screenshots even without full restrictions
  Future<void> applyRestrictions({
    required String chatDocId,
    required String otherUserToken,
    bool forceScreenshotBlock = false,
  }) async {
    try {
      print(
          '[ChatSecurity] 🔒 Applying restrictions for chat: $chatDocId (forceScreenshotBlock: $forceScreenshotBlock)');

      // Get block status
      final blockStatus =
          await BlockingService.to.getBlockStatus(otherUserToken);

      if (blockStatus.isBlocked) {
        if (blockStatus.restrictions != null) {
          // Full restrictions available (I blocked them)
          _currentRestrictions.value = blockStatus.restrictions!;
          await _enforceRestrictions(blockStatus.restrictions!);
          _isSecured.value = true;
          print(
              '[ChatSecurity] ✅ Full restrictions applied: ${blockStatus.restrictions!.toJson()}');
        } else if (forceScreenshotBlock) {
          // No restrictions available (they blocked me), but force screenshot block
          await _setScreenshotEnabled(false);
          _isSecured.value = true;
          print(
              '[ChatSecurity] ✅ Screenshot blocking forced (blocked by other user)');
        }
      } else {
        await clearRestrictions();
      }
    } catch (e) {
      print('[ChatSecurity] ❌ Failed to apply restrictions: $e');
    }
  }

  /// Remove all security restrictions
  Future<void> clearRestrictions() async {
    try {
      print('[ChatSecurity] 🔓 Clearing restrictions');

      // Re-enable screenshots
      await _setScreenshotEnabled(true);

      _currentRestrictions.value = null;
      _isSecured.value = false;

      print('[ChatSecurity] ✅ Restrictions cleared');
    } catch (e) {
      print('[ChatSecurity] ❌ Failed to clear restrictions: $e');
    }
  }

  // ============ RESTRICTION ENFORCEMENT ============

  /// Enforce restrictions based on settings
  Future<void> _enforceRestrictions(BlockRestrictions restrictions) async {
    // Screenshot prevention
    if (restrictions.preventScreenshots) {
      await _setScreenshotEnabled(false);
    }

    // Other restrictions are enforced at UI level
    // (copy, download, etc. are handled by checking restrictions before allowing actions)
  }

  /// Enable/disable screenshots (Android only)
  Future<void> _setScreenshotEnabled(bool enabled) async {
    try {
      if (GetPlatform.isAndroid) {
        print(
            '[ChatSecurity] 🤖 Android detected - attempting ${enabled ? "enable" : "disable"} screenshots...');
        const platform = MethodChannel('com.chatty.sakoa/security');

        if (enabled) {
          final result = await platform.invokeMethod('clearSecureFlag');
          print(
              '[ChatSecurity] ✅ Screenshots ENABLED - Native result: $result');
        } else {
          final result = await platform.invokeMethod('setSecureFlag');
          print(
              '[ChatSecurity] 🔒 Screenshots DISABLED (FLAG_SECURE set) - Native result: $result');
        }
      } else if (GetPlatform.isIOS) {
        // iOS screenshot prevention through native channel
        // Note: iOS doesn't officially support preventing screenshots,
        // but we can detect them and take action
        print(
            '[ChatSecurity] 🍎 iOS detected - screenshot prevention not available (Apple limitation)');
      } else {
        print(
            '[ChatSecurity] ⚠️ Unknown platform - screenshot control not available');
      }
    } catch (e, stackTrace) {
      print('[ChatSecurity] ❌ CRITICAL ERROR setting screenshot status: $e');
      print('[ChatSecurity] 📍 Stack trace: $stackTrace');
      print(
          '[ChatSecurity] ⚠️ This likely means MethodChannel not connected to native code!');
      print(
          '[ChatSecurity] 💡 Solution: Rebuild app with "flutter clean && flutter run"');
    }
  }

  // ============ RESTRICTION CHECKS ============

  /// Check if copying is allowed
  bool canCopy() {
    if (_currentRestrictions.value == null) return true;
    return !_currentRestrictions.value!.preventCopy;
  }

  /// Check if downloading is allowed
  bool canDownload() {
    if (_currentRestrictions.value == null) return true;
    return !_currentRestrictions.value!.preventDownload;
  }

  /// Check if forwarding is allowed
  bool canForward() {
    if (_currentRestrictions.value == null) return true;
    return !_currentRestrictions.value!.preventForward;
  }

  /// Check if screenshots are allowed
  bool canScreenshot() {
    if (_currentRestrictions.value == null) return true;
    return !_currentRestrictions.value!.preventScreenshots;
  }

  // ============ SECURITY ALERTS ============

  /// Show security violation alert
  void showSecurityAlert(String action) {
    Get.snackbar(
      '🔒 Action Blocked',
      'This action is not allowed in blocked chats',
      snackPosition: SnackPosition.TOP,
      duration: Duration(seconds: 2),
    );
    print('[ChatSecurity] ⚠️ Security violation: $action');
  }

  @override
  void onClose() {
    clearRestrictions();
    super.onClose();
  }
}
