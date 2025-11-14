// ✅ UPDATE THE ContactController blockUser() method in contact/controller.dart

// 🔥 Replace the existing blockUser() method with this enhanced version:

  /// Block user with advanced restrictions dialog
  Future<void> blockUser(
      String contactToken, String contactName, String contactAvatar) async {
    try {
      // 🔥 ENHANCED: Show block settings dialog first
      final restrictions = await BlockSettingsDialog.show(
        context: Get.context!,
        userName: contactName,
      );

      // User cancelled
      if (restrictions == null) {
        return;
      }

      // Block with selected restrictions
      EasyLoading.show(status: 'Blocking user...');

      final success = await BlockingService.to.blockUser(
        userToken: contactToken,
        userName: contactName,
        userAvatar: contactAvatar,
        restrictions: restrictions,
      );

      EasyLoading.dismiss();

      if (success) {
        // Remove from accepted contacts list immediately (smooth deletion)
        state.acceptedContacts
            .removeWhere((contact) => contact.contact_token == contactToken);

        // Update relationship map
        state.relationshipStatus[contactToken] = 'blocked';

        // Add to blocked list
        await loadBlockedUsers();

        toastInfo(msg: "$contactName has been blocked");
      } else {
        toastInfo(msg: "Failed to block user");
      }
    } catch (e) {
      EasyLoading.dismiss();
      print("[ContactController] Error blocking user: $e");
      toastInfo(msg: "Failed to block user");
    }
  }

// 🔥 ENHANCED: Update loadBlockedUsers() to use BlockingService

  /// Load blocked users from BlockingService
  Future<void> loadBlockedUsers() async {
    try {
      print("[ContactController] Loading blocked users");

      final blockedUsers = await BlockingService.to.getBlockedUsers();

      state.blockedList.clear();

      for (var user in blockedUsers) {
        var contact = ContactEntity(
          id: user.docId,
          user_token: token,
          contact_token: user.blockedToken,
          contact_name: user.blockedName,
          contact_avatar: user.blockedAvatar,
          status: 'blocked',
          blocked_at: user.blockedAt,
        );
        state.blockedList.add(contact);
      }

      print("[ContactController] Loaded ${state.blockedList.length} blocked users");
    } catch (e) {
      print("[ContactController] Error loading blocked users: $e");
    }
  }

// 🔥 ENHANCED: Update unblockUser() to use BlockingService

  /// Unblock user using BlockingService
  Future<void> unblockUser(ContactEntity contact) async {
    try {
      EasyLoading.show(status: 'Unblocking...');

      final success =
          await BlockingService.to.unblockUser(contact.contact_token ?? "");

      EasyLoading.dismiss();

      if (success) {
        toastInfo(msg: "${contact.contact_name} has been unblocked");
        await loadBlockedUsers();
      } else {
        toastInfo(msg: "Failed to unblock user");
      }
    } catch (e) {
      EasyLoading.dismiss();
      print("[ContactController] Error unblocking user: $e");
      toastInfo(msg: "Failed to unblock user");
    }
  }

// 🔥 Add these imports at the top of contact/controller.dart:
import 'package:sakoa/common/services/blocking_service.dart';
import 'package:sakoa/common/widgets/block_settings_dialog.dart';
