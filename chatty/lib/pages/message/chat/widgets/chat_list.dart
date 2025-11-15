import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sakoa/common/widgets/message_visibility_detector.dart';
import '../index.dart';
import 'chat_left_item.dart';
import 'chat_right_item.dart';

class ChatList extends GetView<ChatController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
        color: AppColors.primaryBackground,
        padding: EdgeInsets.only(bottom: 70.h),
        child: GestureDetector(
          child: CustomScrollView(
              reverse: true,
              controller: controller.myscrollController,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    vertical: 0.w,
                    horizontal: 0.w,
                  ),
                  sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                    (content, index) {
                      var item = controller.state.msgcontentList[index];
                      final isLastMessage =
                          index == 0; // Reversed list, index 0 is last message
                      final previousItem =
                          index < controller.state.msgcontentList.length - 1
                              ? controller.state.msgcontentList[index + 1]
                              : null;

                      if (controller.token == item.token) {
                        return ChatRightItem(
                          item,
                          isLastMessage: isLastMessage,
                          previousMessage: previousItem,
                        );
                      }

                      // Wrap received messages with visibility detector
                      return MessageVisibilityDetector(
                        messageId: item.id ?? '',
                        chatDocId: controller.doc_id,
                        isMyMessage: false,
                        child: ChatLeftItem(item),
                      );
                    },
                    childCount: controller.state.msgcontentList.length,
                  )),
                ),
                SliverPadding(
                    padding:
                        EdgeInsets.symmetric(vertical: 0.w, horizontal: 0.w),
                    sliver: SliverToBoxAdapter(
                      child: controller.state.isloading.value
                          ? Align(
                              alignment: Alignment.center,
                              child: new Text('loading...'),
                            )
                          : Container(),
                    )),
              ]),
          onTap: () {
            controller.close_all_pop();
          },
        )));
  }
}
