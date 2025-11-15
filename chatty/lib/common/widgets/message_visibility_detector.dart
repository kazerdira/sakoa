import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/services/message_delivery_service.dart';

/// 🔥 SUPERNOVA-LEVEL MESSAGE VISIBILITY DETECTOR
/// Tracks when messages are actually visible to the user
/// Used for accurate read receipts (WhatsApp/Telegram style)
///
/// Features:
/// - Only marks as "read" when message is 50%+ visible
/// - Requires message to be visible for 1+ second
/// - Handles fast scrolling (won't mark during rapid scroll)
/// - Respects app lifecycle (paused/background = not reading)
class MessageVisibilityDetector extends StatefulWidget {
  final Widget child;
  final String messageId;
  final String chatDocId;
  final bool isMyMessage;
  final Function(String messageId, bool isVisible)? onVisibilityChanged;

  const MessageVisibilityDetector({
    Key? key,
    required this.child,
    required this.messageId,
    required this.chatDocId,
    required this.isMyMessage,
    this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<MessageVisibilityDetector> createState() =>
      _MessageVisibilityDetectorState();
}

class _MessageVisibilityDetectorState extends State<MessageVisibilityDetector>
    with WidgetsBindingObserver {
  bool _isVisible = false;
  DateTime? _becameVisibleAt;
  bool _markedAsRead = false;
  bool _appInForeground = true;

  static const Duration _readThreshold = Duration(seconds: 1);
  static const double _visibilityThreshold = 0.5; // 50% visibility required

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Track if app is in foreground
    _appInForeground = state == AppLifecycleState.resumed;

    if (!_appInForeground) {
      // App backgrounded - reset visibility
      _isVisible = false;
      _becameVisibleAt = null;
    } else if (_appInForeground && mounted) {
      // App resumed - recheck visibility
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) _checkVisibility();
      });
    }
  }

  void _checkVisibility() {
    if (!mounted || widget.isMyMessage || _markedAsRead) return;

    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    final renderBox = renderObject as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    // Get viewport bounds
    final viewportHeight = MediaQuery.of(context).size.height;

    // Calculate visible portion
    final visibleTop = position.dy.clamp(0.0, viewportHeight);
    final visibleBottom =
        (position.dy + size.height).clamp(0.0, viewportHeight);
    final visibleHeight = visibleBottom - visibleTop;
    final visibilityRatio = visibleHeight / size.height;

    final isCurrentlyVisible =
        visibilityRatio >= _visibilityThreshold && _appInForeground;

    if (isCurrentlyVisible && !_isVisible) {
      // Message just became visible
      _isVisible = true;
      _becameVisibleAt = DateTime.now();
      widget.onVisibilityChanged?.call(widget.messageId, true);

      // Schedule read receipt after threshold
      Future.delayed(_readThreshold, () {
        _attemptMarkAsRead();
      });
    } else if (!isCurrentlyVisible && _isVisible) {
      // Message is no longer visible
      _isVisible = false;
      _becameVisibleAt = null;
      widget.onVisibilityChanged?.call(widget.messageId, false);
    }
  }

  void _attemptMarkAsRead() {
    if (!mounted ||
        !_isVisible ||
        _markedAsRead ||
        widget.isMyMessage ||
        _becameVisibleAt == null) {
      return;
    }

    final visibleDuration = DateTime.now().difference(_becameVisibleAt!);

    if (visibleDuration >= _readThreshold && _appInForeground) {
      // Message has been visible for enough time - mark as read
      _markedAsRead = true;
      _markMessageAsRead();
    }
  }

  void _markMessageAsRead() {
    try {
      // Get MessageDeliveryService and call markAsRead
      Get.find<MessageDeliveryService>().markAsRead(
        chatDocId: widget.chatDocId,
        messageId: widget.messageId,
        isLastMessage: false, // Will be determined by controller logic
      );

      print(
          '[VisibilityDetector] ✅ Marked message as read: ${widget.messageId}');
    } catch (e) {
      print('[VisibilityDetector] ❌ Failed to mark as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Recheck visibility on scroll
        if (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _checkVisibility();
          });
        }
        return false;
      },
      child: widget.child,
    );
  }
}

/// 🔥 EXAMPLE USAGE IN CHAT CONTROLLER
///
/// ```dart
/// // In chat_list.dart, wrap each message:
/// MessageVisibilityDetector(
///   messageId: msg.id!,
///   chatDocId: chatDocId,
///   isMyMessage: msg.token == myToken,
///   onVisibilityChanged: (messageId, isVisible) {
///     if (isVisible) {
///       print('Message $messageId is now visible');
///     }
///   },
///   child: ChatMessageWidget(
///     message: msg,
///     // ... other params
///   ),
/// )
/// ```
