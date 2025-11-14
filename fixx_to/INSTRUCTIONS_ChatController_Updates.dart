// ✅ ADD THIS TO THE EXISTING ChatController in chat/controller.dart

// 🔥 Add these imports at the top:
import 'package:sakoa/common/services/blocking_service.dart';
import 'package:sakoa/common/services/chat_security_service.dart';

// 🔥 Add these properties to ChatController class:
  // Blocking state
  final isBlocked = false.obs;
  final blockStatus = Rx<BlockStatus?>(null);
  StreamSubscription? _blockListener;

// 🔥 Replace the existing _verifyContactStatus() method with this enhanced version:

  /// Verify contact and block status before allowing chat
  Future<void> _verifyContactStatus() async {
    try {
      print('[ChatController] 🔍 Verifying contact & block status...');

      // 1. Check block status (highest priority)
      final status = await BlockingService.to.getBlockStatus(state.to_token.value);
      blockStatus.value = status;

      if (status.isBlocked) {
        isBlocked.value = true;
        print('[ChatController] 🚫 Chat is BLOCKED');

        // Apply security restrictions
        if (status.iBlocked && status.restrictions != null) {
          await ChatSecurityService.to.applyRestrictions(
            chatDocId: doc_id,
            otherUserToken: state.to_token.value,
          );
        }

        // Show blocked state
        toastInfo(
          msg: status.iBlocked
              ? 'You have blocked this user'
              : 'This user has blocked you',
        );

        return; // Don't navigate back - just disable the chat
      }

      // 2. If not blocked, check contact status (fallback to old logic)
      final contactController = Get.find<ContactController>();

      bool isContact = await contactController.isUserContact(state.to_token.value);
      if (!isContact) {
        toastInfo(msg: "You must be contacts to chat");
        Get.back();
        return;
      }

      print('[ChatController] ✅ Contact verified, chat allowed');
    } catch (e) {
      print('[ChatController] ❌ Error verifying status: $e');
    }
  }

// 🔥 Add this method to start real-time block monitoring:

  /// Start real-time block status monitoring
  void _startBlockMonitoring() {
    _blockListener = BlockingService.to
        .watchBlockStatus(state.to_token.value)
        .listen((status) {
      print('[ChatController] 📡 Block status updated: ${status.isBlocked}');
      
      blockStatus.value = status;
      isBlocked.value = status.isBlocked;

      if (status.isBlocked) {
        // Apply restrictions immediately
        ChatSecurityService.to.applyRestrictions(
          chatDocId: doc_id,
          otherUserToken: state.to_token.value,
        );

        toastInfo(
          msg: status.iBlocked
              ? 'You have blocked this user'
              : 'This user has blocked you',
        );
      } else {
        // Clear restrictions
        ChatSecurityService.to.clearRestrictions();
      }
    });
  }

// 🔥 Add this method for blocking from chat screen:

  /// Block this user from within the chat
  Future<void> blockUserFromChat() async {
    try {
      // Show block settings dialog
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Block ${state.to_name.value}?'),
          content: Text(
            'Are you sure you want to block ${state.to_name.value}? You will no longer be able to send or receive messages from this user.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text(
                'Block',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (result == true) {
        // Import the block settings dialog
        final restrictions = await BlockSettingsDialog.show(
          context: Get.context!,
          userName: state.to_name.value,
        );

        if (restrictions != null) {
          final success = await BlockingService.to.blockUser(
            userToken: state.to_token.value,
            userName: state.to_name.value,
            userAvatar: state.to_avatar.value,
            restrictions: restrictions,
          );

          if (success) {
            toastInfo(msg: '${state.to_name.value} has been blocked');
            isBlocked.value = true;
          }
        }
      }
    } catch (e) {
      print('[ChatController] ❌ Error blocking user: $e');
      toastInfo(msg: 'Failed to block user');
    }
  }

// 🔥 Replace the onInit() method with this enhanced version:

  @override
  void onInit() {
    super.onInit();
    print("onInit------------");
    var data = Get.parameters;
    print(data);
    doc_id = data["doc_id"];
    state.to_token.value = data["to_token"] ?? "";
    state.to_name.value = data["to_name"] ?? "";
    state.to_avatar.value = data["to_avatar"] ?? "";
    state.to_online.value = data["to_online"] ?? "1";

    // 🔥 ENHANCED: Check both contact AND block status
    _verifyContactStatus();
    
    // 🔥 NEW: Start real-time block monitoring
    _startBlockMonitoring();

    clear_msg_num(doc_id);
  }

// 🔥 Update the dispose() method to include cleanup:

  @override
  void dispose() {
    listener.cancel();
    _blockListener?.cancel(); // 🔥 NEW: Cancel block listener
    ChatSecurityService.to.clearRestrictions(); // 🔥 NEW: Clear security
    myinputController.dispose();
    inputScrollController.dispose();
    print("dispose-------");
    super.dispose();
  }

// 🔥 Add import for BlockSettingsDialog at the top:
import 'package:sakoa/common/widgets/block_settings_dialog.dart';
