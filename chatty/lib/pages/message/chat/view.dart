import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/widgets/widgets.dart';
import 'package:sakoa/pages/message/chat/widgets/chat_list.dart';
import 'index.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatPage extends GetView<ChatController> {
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primaryBackground,
      title: Obx(() {
        return Container(
          padding: EdgeInsets.only(top: 0.w, left: 0.w, right: 0.w),
          child: Text(
            "${controller.state.to_name}",
            overflow: TextOverflow.clip,
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
              fontSize: 16.sp,
            ),
          ),
        );
      }),
      actions: [
        // 🔥 BLOCK/UNBLOCK MENU
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.primaryText),
          onSelected: (value) async {
            if (value == 'block') {
              await controller.blockUserFromChat(Get.context!);
            } else if (value == 'unblock') {
              await controller.unblockUserFromChat();
            }
          },
          itemBuilder: (context) => [
            // Show "Block" only if chat is NOT blocked
            if (!controller.isBlocked.value)
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red, size: 20.w),
                    SizedBox(width: 10.w),
                    Text('Block User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            // 🔥 Show "Unblock" ONLY if I'M the blocker (not if they blocked me)
            if (controller.isBlocked.value &&
                controller.blockStatus.value?.iBlocked == true)
              PopupMenuItem(
                value: 'unblock',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20.w),
                    SizedBox(width: 10.w),
                    Text('Unblock User', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
          ],
        ),
        Obx(() => Container(
              margin: EdgeInsets.only(right: 20.w),
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: AppColors.primarySecondaryBackground,
                    borderRadius: BorderRadius.all(Radius.circular(22.w)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: Offset(0, 1), // changes position of shadow
                      ),
                    ],
                  ),
                  child: controller.state.to_avatar.value == null
                      ? Image(
                          image: AssetImage('assets/images/account_header.png'),
                        )
                      : CachedNetworkImage(
                          imageUrl: controller.state.to_avatar.value,
                          height: 44.w,
                          width: 44.w,
                          imageBuilder: (context, imageProvider) => Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(22.w)),
                              image: DecorationImage(
                                  image: imageProvider, fit: BoxFit.fill
                                  // colorFilter: ColorFilter.mode(Colors.red, BlendMode.colorBurn),
                                  ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Image(
                            image:
                                AssetImage('assets/images/account_header.png'),
                          ),
                        ),
                ),
                Positioned(
                  bottom: 5.w,
                  right: 0.w,
                  height: 14.w,
                  child: Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      border: Border.all(
                          width: 2.w, color: AppColors.primaryElementText),
                      color: controller.state.to_online.value == "1"
                          ? AppColors.primaryElementStatus
                          : AppColors.primarySecondaryElementText,
                      borderRadius: BorderRadius.all(Radius.circular(12.w)),
                    ),
                  ),
                )
              ]),
            )) // Close Obx
      ],
    );
  }

  /// 🔥 Disabled input bar when blocked
  Widget _buildDisabledInput() {
    // Determine the correct message based on who blocked whom
    final blockStatus = controller.blockStatus.value;
    String blockMessage;

    if (blockStatus != null && blockStatus.iBlocked) {
      // I blocked them
      blockMessage = 'You blocked this user';
    } else if (blockStatus != null && blockStatus.theyBlocked) {
      // They blocked me
      blockMessage = '${controller.state.to_name.value} has blocked you';
    } else {
      // Fallback
      blockMessage = 'Chat is blocked';
    }

    return Container(
      width: 360.w,
      height: 70.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      color: Colors.grey.shade200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(25.w),
              ),
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red.shade400, size: 20.w),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      blockMessage,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 🔥 Only show unblock button if I'M the blocker (not if they blocked me)
          if (blockStatus != null && blockStatus.iBlocked) ...[
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: () => controller.unblockUserFromChat(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'UNBLOCK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(),
        body: Obx(() => SafeArea(
                child: ConstrainedBox(
              constraints: BoxConstraints.expand(),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  ChatList(),
                  // 🔥 Show disabled input if blocked, normal input otherwise
                  Positioned(
                    bottom: 0.h,
                    child: controller.isBlocked.value
                        ? _buildDisabledInput()
                        : Container(
                            width: 360.w,
                            constraints: BoxConstraints(
                                maxHeight: 170.h, minHeight: 70.h),
                            padding: EdgeInsets.only(
                                left: 20.w,
                                right: 20.w,
                                bottom: 10.h,
                                top: 10.h),
                            color: AppColors.primaryBackground,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Container(
                                    width: 270.w,
                                    constraints: BoxConstraints(
                                        maxHeight: 170.h, minHeight: 30.h),
                                    padding:
                                        EdgeInsets.only(top: 5.h, bottom: 5.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBackground,
                                      border: Border.all(
                                          color: AppColors
                                              .primarySecondaryElementText),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                    child: Row(children: [
                                      Container(
                                        width: 220.w,
                                        constraints: BoxConstraints(
                                            maxHeight: 150.h, minHeight: 20.h),
                                        child: TextField(
                                          keyboardType: TextInputType.multiline,
                                          maxLines: null,
                                          controller:
                                              controller.myinputController,
                                          autofocus: false,
                                          decoration: InputDecoration(
                                            hintText: "Message...",
                                            isDense: true,
                                            contentPadding: EdgeInsets.only(
                                                left: 10.w, top: 0, bottom: 0),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.transparent,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.transparent,
                                              ),
                                            ),
                                            disabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.transparent,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.transparent,
                                              ),
                                            ),
                                            hintStyle: TextStyle(
                                              color: AppColors
                                                  .primarySecondaryElementText,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        child: Container(
                                          width: 40.w,
                                          height: 40.h,
                                          child: Image.asset(
                                              "assets/icons/send.png"),
                                        ),
                                        onTap: () {
                                          controller.sendMessage();
                                        },
                                      )
                                    ])),
                                GestureDetector(
                                    child: Container(
                                        height: 40.w,
                                        width: 40.w,
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryElement,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              spreadRadius: 2,
                                              blurRadius: 2,
                                              offset: Offset(1,
                                                  1), // changes position of shadow
                                            ),
                                          ],
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(40.w)),
                                        ),
                                        child: controller
                                                .state.more_status.value
                                            ? Image.asset("assets/icons/by.png")
                                            : Image.asset(
                                                "assets/icons/add.png")),
                                    onTap: () {
                                      controller.goMore();
                                    }),
                              ],
                            ),
                          ),
                  ), // Closes ternary operator for normal input

                  controller.state.more_status.value
                      ? Positioned(
                          right: 20.w,
                          bottom: 70.h,
                          height: 200.w,
                          width: 40.w,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              GestureDetector(
                                child: Container(
                                    height: 40.w,
                                    width: 40.w,
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBackground,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 2,
                                          offset: Offset(1,
                                              1), // changes position of shadow
                                        ),
                                      ],
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(40.w)),
                                    ),
                                    child:
                                        Image.asset("assets/icons/file.png")),
                                onTap: () {
                                  controller.imgFromGallery();
                                },
                              ),
                              GestureDetector(
                                child: Container(
                                    height: 40.w,
                                    width: 40.w,
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBackground,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 2,
                                          offset: Offset(1,
                                              1), // changes position of shadow
                                        ),
                                      ],
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(40.w)),
                                    ),
                                    child:
                                        Image.asset("assets/icons/photo.png")),
                                onTap: () {
                                  controller.imgFromCamera();
                                },
                              ),
                              GestureDetector(
                                child: Container(
                                    height: 40.w,
                                    width: 40.w,
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBackground,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 2,
                                          offset: Offset(1,
                                              1), // changes position of shadow
                                        ),
                                      ],
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(40.w)),
                                    ),
                                    child:
                                        Image.asset("assets/icons/call.png")),
                                onTap: () {
                                  controller.callAudio();
                                },
                              ),
                              GestureDetector(
                                child: Container(
                                    height: 40.w,
                                    width: 40.w,
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBackground,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 2,
                                          offset: Offset(1,
                                              1), // changes position of shadow
                                        ),
                                      ],
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(40.w)),
                                    ),
                                    child:
                                        Image.asset("assets/icons/video.png")),
                                onTap: () {
                                  controller.callVideo();
                                },
                              ),
                            ],
                          ))
                      : Container()
                ],
              ),
            ))));
  }
}
