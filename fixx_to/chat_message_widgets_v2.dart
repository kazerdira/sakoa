import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:sakoa/common/utils/utils.dart';

/// 🔥 SUPERNOVA-LEVEL CHAT MESSAGE WIDGET
/// Features:
/// - Smart timestamp grouping (5-min intervals)
/// - Double-tap to show full details
/// - Last-message-only delivery status
/// - Telegram-style clean UI
class ChatMessageWidget extends StatefulWidget {
  final Msgcontent message;
  final Msgcontent? previousMessage;
  final Msgcontent? nextMessage;
  final bool isMyMessage;
  final bool isLastMessage;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;

  const ChatMessageWidget({
    Key? key,
    required this.message,
    this.previousMessage,
    this.nextMessage,
    required this.isMyMessage,
    required this.isLastMessage,
    this.onDoubleTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  bool _showDetails = false;

  /// Check if timestamp should be shown (5-min gap rule)
  bool get _shouldShowTimestamp {
    if (widget.previousMessage == null) return true;

    final currentTime = widget.message.addtime?.toDate();
    final previousTime = widget.previousMessage?.addtime?.toDate();

    if (currentTime == null || previousTime == null) return false;

    final timeDiff = currentTime.difference(previousTime);
    return timeDiff >= Duration(minutes: 5);
  }

  /// Check if messages should be grouped (same sender, <2 min apart)
  bool get _shouldGroupWithPrevious {
    if (widget.previousMessage == null) return false;
    if (widget.previousMessage!.token != widget.message.token) return false;

    final currentTime = widget.message.addtime?.toDate();
    final previousTime = widget.previousMessage?.addtime?.toDate();

    if (currentTime == null || previousTime == null) return false;

    final timeDiff = currentTime.difference(previousTime);
    return timeDiff < Duration(minutes: 2);
  }

  bool get _shouldGroupWithNext {
    if (widget.nextMessage == null) return false;
    if (widget.nextMessage!.token != widget.message.token) return false;

    final currentTime = widget.message.addtime?.toDate();
    final nextTime = widget.nextMessage?.addtime?.toDate();

    if (currentTime == null || nextTime == null) return false;

    final timeDiff = nextTime.difference(currentTime);
    return timeDiff < Duration(minutes: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Timestamp separator (only if 5+ min gap)
        if (_shouldShowTimestamp) _buildTimestampSeparator(),

        // Message bubble
        GestureDetector(
          onDoubleTap: () {
            setState(() {
              _showDetails = !_showDetails;
            });
            widget.onDoubleTap?.call();
            
            // Auto-hide details after 5 seconds
            if (_showDetails) {
              Future.delayed(Duration(seconds: 5), () {
                if (mounted) {
                  setState(() {
                    _showDetails = false;
                  });
                }
              });
            }
          },
          onLongPress: widget.onLongPress,
          child: Container(
            padding: EdgeInsets.only(
              top: _shouldGroupWithPrevious ? 2.h : 8.h,
              bottom: _shouldGroupWithNext ? 2.h : 8.h,
              left: 20.w,
              right: 20.w,
            ),
            child: Row(
              mainAxisAlignment: widget.isMyMessage
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 280.w),
                  child: Column(
                    crossAxisAlignment: widget.isMyMessage
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Message content
                      _buildMessageBubble(),

                      // Details (on double-tap)
                      if (_showDetails) _buildMessageDetails(),

                      // Delivery status (ONLY for last sent message)
                      if (widget.isMyMessage && 
                          widget.isLastMessage && 
                          !_showDetails)
                        _buildDeliveryStatus(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build timestamp separator (Telegram-style)
  Widget _buildTimestampSeparator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.primarySecondaryBackground.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12.w),
          ),
          child: Text(
            _formatDateSeparator(widget.message.addtime),
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.primaryText.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Build message bubble with smart styling
  Widget _buildMessageBubble() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: widget.isMyMessage
            ? AppColors.primaryElement
            : AppColors.primarySecondaryBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(
            (!widget.isMyMessage && !_shouldGroupWithPrevious) ? 18.w : 4.w,
          ),
          topRight: Radius.circular(
            (widget.isMyMessage && !_shouldGroupWithPrevious) ? 18.w : 4.w,
          ),
          bottomLeft: Radius.circular(
            (!widget.isMyMessage && !_shouldGroupWithNext) ? 18.w : 4.w,
          ),
          bottomRight: Radius.circular(
            (widget.isMyMessage && !_shouldGroupWithNext) ? 18.w : 4.w,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply bubble (if exists)
          if (widget.message.reply != null) ...[
            _buildReplyPreview(),
            SizedBox(height: 4.h),
          ],

          // Message content
          _buildContent(),
        ],
      ),
    );
  }

  /// Build message content based on type
  Widget _buildContent() {
    switch (widget.message.type) {
      case 'text':
        return Text(
          widget.message.content ?? '',
          style: TextStyle(
            fontSize: 14.sp,
            color: widget.isMyMessage
                ? Colors.white
                : AppColors.primaryText,
          ),
        );
      case 'voice':
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mic,
                size: 18.w,
                color: widget.isMyMessage ? Colors.white : AppColors.primaryElement,
              ),
              SizedBox(width: 8.w),
              Text(
                '${widget.message.voice_duration ?? 0}s',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: widget.isMyMessage
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.primaryText.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      case 'image':
        return Container(
          constraints: BoxConstraints(maxWidth: 200.w, maxHeight: 300.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.w),
            child: Image.network(
              widget.message.content ?? '',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100.w,
                  height: 100.w,
                  color: Colors.grey.shade300,
                  child: Icon(Icons.broken_image, size: 40.w),
                );
              },
            ),
          ),
        );
      default:
        return Text(
          widget.message.content ?? '',
          style: TextStyle(
            fontSize: 14.sp,
            color: widget.isMyMessage ? Colors.white : AppColors.primaryText,
          ),
        );
    }
  }

  /// Build reply preview (if message is a reply)
  Widget _buildReplyPreview() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: widget.isMyMessage
            ? Colors.white.withOpacity(0.2)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6.w),
        border: Border(
          left: BorderSide(
            color: widget.isMyMessage
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
          Text(
            widget.message.reply?.originalSenderName ?? 'Unknown',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: widget.isMyMessage
                  ? Colors.white.withOpacity(0.9)
                  : AppColors.primaryElement,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            widget.message.reply?.getDisplayText() ?? '',
            style: TextStyle(
              fontSize: 11.sp,
              color: widget.isMyMessage
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

  /// Build message details (shown on double-tap)
  Widget _buildMessageDetails() {
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            'Sent',
            _formatDetailTime(widget.message.addtime),
            Icons.send,
          ),
          if (widget.message.delivery_status == 'delivered' ||
              widget.message.delivery_status == 'read') ...[
            SizedBox(height: 2.h),
            _buildDetailRow(
              'Delivered',
              _formatDetailTime(
                widget.message.delivered_at != null
                    ? Timestamp.fromDate(widget.message.delivered_at!)
                    : null,
              ),
              Icons.done_all,
            ),
          ],
          if (widget.message.delivery_status == 'read') ...[
            SizedBox(height: 2.h),
            _buildDetailRow(
              'Read',
              _formatDetailTime(
                widget.message.read_at != null
                    ? Timestamp.fromDate(widget.message.read_at!)
                    : null,
              ),
              Icons.done_all,
              color: Colors.blue,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12.w,
          color: color ?? Colors.white.withOpacity(0.7),
        ),
        SizedBox(width: 4.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Build delivery status (ONLY for last sent message)
  Widget _buildDeliveryStatus() {
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDeliveryIcon(),
        ],
      ),
    );
  }

  Widget _buildDeliveryIcon() {
    final status = widget.message.delivery_status;
    
    switch (status) {
      case 'sending':
        return SizedBox(
          width: 12.w,
          height: 12.w,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.grey.withOpacity(0.5),
            ),
          ),
        );
      case 'sent':
        return Icon(
          Icons.done,
          size: 14.sp,
          color: Colors.grey.withOpacity(0.6),
        );
      case 'delivered':
        return Icon(
          Icons.done_all,
          size: 14.sp,
          color: Colors.grey.withOpacity(0.6),
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

  /// Format date separator (e.g., "Today", "Yesterday", "Jan 15")
  String _formatDateSeparator(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
      return '$weekday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      final month = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][date.month - 1];
      return '$month ${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Format detail time (e.g., "14:30:45")
  String _formatDetailTime(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';

    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}
