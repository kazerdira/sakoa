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

Widget ChatLeftItem(Msgcontent item) {
  return GestureDetector(
    onLongPress: () {
      final context = Get.context;
      if (context != null) {
        _showMessageOptions(context, item);
      }
    },
    child: Container(
      padding:
          EdgeInsets.only(top: 10.h, left: 20.w, right: 20.w, bottom: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 250.w,
              minHeight: 40.w,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(left: 0.w, top: 0.w),
                  padding: EdgeInsets.only(
                    top: 10.w,
                    bottom: 10.w,
                    left: 10.w,
                    right: 10.w,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySecondaryBackground,
                    borderRadius: BorderRadius.all(Radius.circular(5.w)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            isMyMessage: false,
                          ),
                        ),
                      if (item.reply != null) SizedBox(height: 8.h),

                      // 🔥 Message content (text, image, or voice)
                      if (item.type == "text")
                        LeftRichTextContainer("${item.content}")
                      else if (item.type == "voice")
                        VoiceMessagePlayer(
                          messageId: item.id ?? '',
                          audioUrl: item.content ?? '',
                          durationSeconds: item.voice_duration ?? 0,
                          isMyMessage: false,
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
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
