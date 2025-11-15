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
// 🔥 Voice & Reply imports
import 'package:sakoa/pages/message/chat/widgets/voice_message_player.dart';
import 'package:sakoa/pages/message/chat/widgets/in_message_reply_bubble.dart';
import 'package:sakoa/pages/message/chat/controller.dart';
import 'package:flutter/services.dart';

// 🔥 INDUSTRIAL-GRADE: Delivery status icon builder
Widget _buildDeliveryStatusIcon(String? status) {
  switch (status) {
    case 'sending':
      return SizedBox(
        width: 12.w,
        height: 12.w,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.primarySecondaryElementText.withOpacity(0.5),
          ),
        ),
      );
    case 'sent':
      return Icon(
        Icons.check,
        size: 14.sp,
        color: AppColors.primarySecondaryElementText.withOpacity(0.6),
      );
    case 'delivered':
      return Icon(
        Icons.done_all,
        size: 14.sp,
        color: AppColors.primarySecondaryElementText.withOpacity(0.6),
      );
    case 'read':
      return Icon(
        Icons.done_all,
        size: 14.sp,
        color: Colors.blue,
      );
    case 'failed':
      return Icon(
        Icons.error_outline,
        size: 14.sp,
        color: Colors.red,
      );
    default:
      return SizedBox.shrink();
  }
}

// 🔥 Format timestamp for delivery status
String _formatTime(Timestamp? timestamp) {
  if (timestamp == null) return "";
  final date = timestamp.toDate();
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays > 0) {
    return "${date.day}/${date.month}";
  } else if (difference.inHours > 0) {
    return "${difference.inHours}h ago";
  } else if (difference.inMinutes > 0) {
    return "${difference.inMinutes}m ago";
  } else {
    return "Just now";
  }
}

Widget RightRichTextContainer(String textContent) {
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
              color: AppColors.primaryElementText,
              decoration: TextDecoration.underline,
            )));
      }
      return '';
    },
    onNonMatch: (String text) {
      if (text.isNotEmpty) {
        widgets.add(TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.primaryElementText,
            )));
      }
      return '';
    },
  );
  return RichText(
    text: TextSpan(children: [...widgets]),
  );
}

// 🔥 Show long-press menu for sent messages
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
          // Delete option (for my messages)
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete',
                style: TextStyle(fontSize: 14.sp, color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement delete functionality
              Get.snackbar(
                'Info',
                'Delete feature coming soon',
                snackPosition: SnackPosition.BOTTOM,
                duration: Duration(seconds: 2),
              );
            },
          ),
        ],
      ),
    ),
  );
}

Widget ChatRightItem(Msgcontent item) {
  return GestureDetector(
    onLongPress: () {
      final context = Get.context;
      if (context != null) {
        _showMessageOptions(context, item);
      }
    },
    child: Container(
      padding:
          EdgeInsets.only(top: 10.w, left: 20.w, right: 20.w, bottom: 10.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 250.w,
              minHeight: 40.w,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  margin: EdgeInsets.only(right: 0.w, top: 0.w),
                  padding: EdgeInsets.only(
                    top: 10.w,
                    bottom: 10.w,
                    left: 10.w,
                    right: 10.w,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryElement,
                    borderRadius: BorderRadius.all(Radius.circular(5.w)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 🔥 Reply bubble (if this message is a reply)
                      if (item.reply != null)
                        GestureDetector(
                          onTap: () {
                            final controller = Get.find<ChatController>();
                            controller
                                .scrollToMessage(item.reply!.originalMessageId);
                          },
                          child: InMessageReplyBubble(
                            reply: item.reply!,
                            isMyMessage: true,
                          ),
                        ),
                      if (item.reply != null) SizedBox(height: 8.h),

                      // 🔥 Message content (text, image, or voice)
                      if (item.type == "text")
                        RightRichTextContainer("${item.content}")
                      else if (item.type == "voice")
                        VoiceMessagePlayer(
                          messageId: item.id ?? '',
                          audioUrl: item.content ?? '',
                          durationSeconds: item.voice_duration ?? 0,
                          isMyMessage: true,
                        )
                      else // Image
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 90.w),
                          child: GestureDetector(
                            child:
                                CachedNetworkImage(imageUrl: "${item.content}"),
                            onTap: () {
                              Get.toNamed(AppRoutes.Photoimgview,
                                  parameters: {"url": item.content ?? ""});
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                // 🔥 INDUSTRIAL-GRADE: Timestamp + Delivery Status
                Container(
                  margin: EdgeInsets.only(top: 10.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.addtime == null
                            ? ""
                            : duTimeLineFormat(
                                (item.addtime as Timestamp).toDate()),
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.primarySecondaryElementText,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      _buildDeliveryStatusIcon(item.delivery_status),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
