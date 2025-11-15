import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:sakoa/common/entities/message_reply_entity.dart';

/// 🔥 REPLY PREVIEW WIDGET
/// Shows above input bar when user is replying to a message
/// Displays original message preview with close button
class ReplyPreviewWidget extends StatelessWidget {
  final MessageReply reply;
  final VoidCallback onClose;
  final bool isMyMessage;

  const ReplyPreviewWidget({
    Key? key,
    required this.reply,
    required this.onClose,
    required this.isMyMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.primarySecondaryBackground,
        borderRadius: BorderRadius.circular(8.w),
        border: Border(
          left: BorderSide(
            color: AppColors.primaryElement,
            width: 4.w,
          ),
        ),
      ),
      child: Row(
        children: [
          // Reply icon
          Icon(
            Icons.reply,
            color: AppColors.primaryElement,
            size: 20.w,
          ),

          SizedBox(width: 10.w),

          // Reply content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sender name
                Text(
                  isMyMessage ? 'You' : reply.originalSenderName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryElement,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 3.h),

                // Message preview
                Text(
                  reply.getDisplayText(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primarySecondaryElementText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Close button
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Icon(
                Icons.close,
                color: AppColors.primarySecondaryElementText,
                size: 18.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
