import 'package:sakoa/common/routes/names.dart';
import 'package:sakoa/common/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
// 🔥 Voice & Reply imports
import 'package:sakoa/pages/message/chat/widgets/voice_message_player_v9.dart';
import 'package:sakoa/pages/message/chat/widgets/in_message_reply_bubble.dart';
import 'package:sakoa/pages/message/chat/controller.dart';
import 'package:flutter/services.dart';
// 🔥 V2: Message delivery service for timestamp grouping
import 'package:sakoa/common/services/message_delivery_service.dart';

// 🔥 Helper function to format voice message duration
String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '${minutes.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
}

Widget LeftRichTextContainer(String textContent) {
  const urlPattern =
      r"[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:._\+-~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:_\+.~#?&\/\/=]*)";
  List<InlineSpan> widgets = [];

  textContent.splitMapJoin(
    RegExp(urlPattern, caseSensitive: false, multiLine: false),
    onMatch: (Match match) {
      final matchText = match[0];
      if (matchText != null) {
        widgets.add(TextSpan(
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Uri _url = Uri.parse(matchText);
                launchUrl(_url);
              },
            text: matchText,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.primaryText,
              decoration: TextDecoration.underline,
            )));
      }
      return '';
    },
    onNonMatch: (String text) {
      if (text.isNotEmpty) {
        widgets.add(TextSpan(
            text: text,
            style: TextStyle(fontSize: 14.sp, color: AppColors.primaryText)));
      }
      return '';
    },
  );

  return RichText(
    text: TextSpan(children: [...widgets]),
  );
}

// 🔥 Show long-press menu for received messages
void _showMessageOptions(BuildContext context, Msgcontent item) {
  final controller = Get.find<ChatController>();

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.primaryBackground,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
    ),
    builder: (context) => Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply option
          ListTile(
            leading: Icon(Icons.reply, color: AppColors.primaryElement),
            title: Text('Reply', style: TextStyle(fontSize: 14.sp)),
            onTap: () {
              Navigator.pop(context);
              controller.setReplyTo(item);
            },
          ),
          // Copy option (only for text messages)
          if (item.type == "text")
            ListTile(
              leading: Icon(Icons.copy, color: AppColors.primaryElement),
              title: Text('Copy', style: TextStyle(fontSize: 14.sp)),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: item.content ?? ''));
                Get.snackbar(
                  'Copied',
                  'Message copied to clipboard',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: Duration(seconds: 1),
                );
              },
            ),
        ],
      ),
    ),
  );
}

// 🔥 V2: Telegram-style timestamp separator (shared with right items)
Widget _buildTimestampSeparator(DateTime messageTime) {
  return Container(
    margin: EdgeInsets.symmetric(vertical: 10.h),
    alignment: Alignment.center,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppColors.primarySecondaryElementText.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Text(
        formatDateSeparator(messageTime),
        style: TextStyle(
          fontSize: 11.sp,
          color: AppColors.primarySecondaryElementText.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

// 🔥 V2: Message timeline details overlay (double-tap for received messages)
Widget _buildMessageDetails(Msgcontent item) {
  final sentTime = item.sent_at != null
      ? DateFormat('HH:mm:ss').format((item.sent_at as Timestamp).toDate())
      : (item.addtime != null
          ? DateFormat('HH:mm:ss').format((item.addtime as Timestamp).toDate())
          : 'N/A');
  final deliveredTime = item.delivered_at != null
      ? DateFormat('HH:mm:ss').format((item.delivered_at as Timestamp).toDate())
      : 'Not delivered';
  final readTime = item.read_at != null
      ? DateFormat('HH:mm:ss').format((item.read_at as Timestamp).toDate())
      : 'Not read';

  return Container(
    margin: EdgeInsets.only(top: 8.h, left: 20.w),
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.7),
      borderRadius: BorderRadius.circular(8.w),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '✓ Sent: $sentTime',
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '✓✓ Delivered: $deliveredTime',
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '👁 Read: $readTime',
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.blue.shade300,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}

// 🔥 V2: Stateful wrapper for double-tap timeline details (left items)
class _ChatLeftItemState extends State<_ChatLeftItemWidget> {
  bool _showDetails = false;

  void _toggleDetails() {
    setState(() {
      _showDetails = !_showDetails;
    });

    // Auto-hide after 5 seconds
    if (_showDetails) {
      Future.delayed(Duration(seconds: 5), () {
        if (mounted && _showDetails) {
          setState(() {
            _showDetails = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildChatLeftItem(
      widget.item,
      previousMessage: widget.previousMessage,
      showDetails: _showDetails,
      onToggleDetails: _toggleDetails,
    );
  }
}

class _ChatLeftItemWidget extends StatefulWidget {
  final Msgcontent item;
  final Msgcontent? previousMessage;

  const _ChatLeftItemWidget(
    this.item, {
    this.previousMessage,
  });

  @override
  _ChatLeftItemState createState() => _ChatLeftItemState();
}

Widget ChatLeftItem(
  Msgcontent item, {
  Msgcontent? previousMessage,
}) {
  return _ChatLeftItemWidget(
    item,
    previousMessage: previousMessage,
  );
}

Widget _buildChatLeftItem(
  Msgcontent item, {
  Msgcontent? previousMessage,
  bool showDetails = false,
  VoidCallback? onToggleDetails,
}) {
  // 🔥 V2: Check if we should show timestamp separator
  final messageDeliveryService = Get.find<MessageDeliveryService>();
  final showTimestamp = messageDeliveryService.shouldShowTimestamp(
    item,
    previousMessage,
  );
  final messageTime = item.addtime != null
      ? (item.addtime as Timestamp).toDate()
      : DateTime.now();

  // 🔥 V2: Message grouping logic (Telegram-style) for received messages
  bool shouldGroupWithPrevious = false;
  if (previousMessage != null &&
      previousMessage.addtime != null &&
      item.addtime != null) {
    final prevTime = (previousMessage.addtime as Timestamp).toDate();
    final currTime = (item.addtime as Timestamp).toDate();
    final timeDiff = currTime.difference(prevTime).inMinutes;

    // Group if: same sender (both received messages) AND within 2 minutes
    final sameSender = previousMessage.token == null &&
        item.token == null; // Both are received messages
    shouldGroupWithPrevious = sameSender && timeDiff < 2;
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // 🔥 V2: Timestamp separator (appears when messages are 5+ minutes apart)
      if (showTimestamp) _buildTimestampSeparator(messageTime),

      // Original message bubble
      GestureDetector(
        onLongPress: () {
          final context = Get.context;
          if (context != null) {
            _showMessageOptions(context, item);
          }
        },
        // 🔥 V2: Double-tap to show delivery timeline details
        onDoubleTap: onToggleDetails,
        child: Container(
          // 🔥 V2: Smart padding - tight for grouped, normal for ungrouped
          padding: EdgeInsets.only(
            top: shouldGroupWithPrevious ? 2.h : 10.h,
            left: 20.w,
            right: 20.w,
            bottom: 10.h,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: item.type == "voice" ? 200.w : 250.w,
                  minHeight: 40.w,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 0.w, top: 0.w),
                      padding: item.type == "voice"
                          ? EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.w)
                          : EdgeInsets.all(10.w),
                      // 🔥 V2: Smart bubble grouping with Telegram-style corners
                      decoration: BoxDecoration(
                        color: AppColors.primarySecondaryBackground,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                              shouldGroupWithPrevious ? 4.w : 18.w),
                          topRight: Radius.circular(18.w),
                          bottomLeft: Radius.circular(18.w),
                          bottomRight: Radius.circular(18.w),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔥 Reply bubble (if this message is a reply)
                          if (item.reply != null)
                            GestureDetector(
                              onTap: () {
                                final controller = Get.find<ChatController>();
                                controller.scrollToMessage(
                                    item.reply!.originalMessageId);
                              },
                              child: InMessageReplyBubble(
                                reply: item.reply!,
                                isMyMessage: false,
                              ),
                            ),
                          if (item.reply != null) SizedBox(height: 8.h),

                          // 🔥 Message content (text, image, or voice)
                          if (item.type == "text")
                            LeftRichTextContainer("${item.content}")
                          else if (item.type == "voice")
                            VoiceMessagePlayerV10(
                              messageId: item.id ?? '',
                              audioUrl: item.content ?? '',
                              duration:
                                  _formatDuration(item.voice_duration ?? 0),
                              isMyMessage: false,
                            )
                          else // Image
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 90.w),
                              child: GestureDetector(
                                child: CachedNetworkImage(
                                    imageUrl: "${item.content}"),
                                onTap: () {
                                  Get.toNamed(AppRoutes.Photoimgview,
                                      parameters: {"url": item.content ?? ""});
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 10.h),
                      child: Text(
                        item.addtime == null
                            ? ""
                            : duTimeLineFormat(
                                (item.addtime as Timestamp).toDate()),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.primarySecondaryElementText,
                        ),
                      ),
                    ),
                    // 🔥 V2: Show delivery timeline details on double-tap
                    if (showDetails) _buildMessageDetails(item),
                  ],
                ),
              ),
            ],
          ),
        ), // Close Container
      ), // Close GestureDetector
    ], // Close Column children
  ); // Close Column
}
