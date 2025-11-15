import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:sakoa/common/entities/message_reply_entity.dart';

/// 🔥 IN-MESSAGE REPLY BUBBLE
/// Shows inside message bubble when message is a reply
/// Tappable to scroll to original message
class InMessageReplyBubble extends StatelessWidget {
  final MessageReply reply;
  final bool isMyMessage;

  const InMessageReplyBubble({
    Key? key,
    required this.reply,
    required this.isMyMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: isMyMessage
            ? Colors.white.withOpacity(0.2)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6.w),
        border: Border(
          left: BorderSide(
            color: isMyMessage
                ? Colors.white.withOpacity(0.5)
                : AppColors.primaryElement.withOpacity(0.5),
            width: 3.w,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sender name
          Row(
            children: [
              Icon(
                Icons.reply,
                size: 12.w,
                color: isMyMessage
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.primaryElement.withOpacity(0.7),
              ),
              SizedBox(width: 4.w),
              Text(
                reply.originalSenderName,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: isMyMessage
                      ? Colors.white.withOpacity(0.9)
                      : AppColors.primaryElement,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Original message preview
          Text(
            reply.getDisplayText(),
            style: TextStyle(
              fontSize: 11.sp,
              color: isMyMessage
                  ? Colors.white.withOpacity(0.7)
                  : AppColors.primarySecondaryElementText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
