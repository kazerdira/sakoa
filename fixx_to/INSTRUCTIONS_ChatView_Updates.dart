// ✅ ADD THIS TO THE EXISTING ChatPage in chat/view.dart

// 🔥 Replace the build() method's body content section with this:

Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(),
    body: Obx(() {
      // 🔥 NEW: Check if chat is blocked
      if (controller.isBlocked.value) {
        return _buildBlockedChatUI();
      }

      // Normal chat UI (existing code)
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints.expand(),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ChatList(),
              Positioned(
                bottom: 0.h,
                child: _buildInputSection(),
              ),
              controller.state.more_status.value
                  ? _buildMoreOptions()
                  : Container()
            ],
          ),
        ),
      );
    }),
  );
}

// 🔥 NEW: Build blocked chat UI with professional design
Widget _buildBlockedChatUI() {
  final status = controller.blockStatus.value;
  final iBlocked = status?.iBlocked ?? false;

  return Container(
    color: AppColors.primaryBackground,
    child: Stack(
      children: [
        // Chat history (read-only, dimmed)
        Opacity(
          opacity: 0.3,
          child: IgnorePointer(
            child: Container(
              padding: EdgeInsets.only(bottom: 200.h),
              child: ChatList(),
            ),
          ),
        ),

        // Overlay blur effect
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBackground.withOpacity(0.3),
                  AppColors.primaryBackground.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),

        // Blocked message card
        Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 30.w),
            padding: EdgeInsets.all(25.w),
            decoration: BoxDecoration(
              color: AppColors.primarySecondaryBackground,
              borderRadius: BorderRadius.circular(20.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.block,
                    color: Colors.red,
                    size: 50.w,
                  ),
                ),
                SizedBox(height: 20.h),

                // Title
                Text(
                  iBlocked ? 'User Blocked' : 'You Are Blocked',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: 10.h),

                // Description
                Text(
                  iBlocked
                      ? 'You have blocked ${controller.state.to_name.value}. You cannot send or receive messages from this user.'
                      : '${controller.state.to_name.value} has blocked you. You cannot send or receive messages.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.primaryText.withOpacity(0.6),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 25.h),

                // Actions
                if (iBlocked)
                  ElevatedButton(
                    onPressed: () async {
                      // Unblock user
                      final result = await Get.dialog<bool>(
                        AlertDialog(
                          title: Text('Unblock ${controller.state.to_name.value}?'),
                          content: Text(
                            'Are you sure you want to unblock this user? You will be able to chat again.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(result: false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Get.back(result: true),
                              child: Text(
                                'Unblock',
                                style: TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (result == true) {
                        final success = await BlockingService.to
                            .unblockUser(controller.state.to_token.value);
                        if (success) {
                          toastInfo(
                              msg: '${controller.state.to_name.value} has been unblocked');
                          controller.isBlocked.value = false;
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 30.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.w),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 20.w),
                        SizedBox(width: 8.w),
                        Text(
                          'Unblock User',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Back button (always show)
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Go Back',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.primaryText.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Security badge (if restrictions are active)
        if (iBlocked && status?.restrictions != null)
          Positioned(
            top: 20.h,
            left: 20.w,
            right: 20.w,
            child: _buildSecurityBadge(status!.restrictions!),
          ),
      ],
    ),
  );
}

// 🔥 NEW: Security badge showing active restrictions
Widget _buildSecurityBadge(BlockRestrictions restrictions) {
  final activeRestrictions = <String>[];
  if (restrictions.preventScreenshots) activeRestrictions.add('Screenshots');
  if (restrictions.preventCopy) activeRestrictions.add('Copy');
  if (restrictions.preventDownload) activeRestrictions.add('Download');
  if (restrictions.preventForward) activeRestrictions.add('Forward');

  if (activeRestrictions.isEmpty) return Container();

  return Container(
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: AppColors.primaryElement.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12.w),
      border: Border.all(
        color: AppColors.primaryElement.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Icon(
          Icons.security,
          color: AppColors.primaryElement,
          size: 20.w,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security Active',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryElement,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Protected: ${activeRestrictions.join(', ')}',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.primaryText.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// 🔥 ENHANCED: Update AppBar to show block button
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
      // Avatar
      Container(
        margin: EdgeInsets.only(right: 10.w),
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
                  offset: Offset(0, 1),
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
                        borderRadius: BorderRadius.all(Radius.circular(22.w)),
                        image: DecorationImage(
                            image: imageProvider, fit: BoxFit.fill),
                      ),
                    ),
                    errorWidget: (context, url, error) => Image(
                      image: AssetImage('assets/images/account_header.png'),
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
      ),

      // 🔥 NEW: Block/More options menu
      Obx(() => PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.primaryText),
            onSelected: (value) async {
              if (value == 'block') {
                await controller.blockUserFromChat();
              }
            },
            itemBuilder: (context) => [
              if (!controller.isBlocked.value)
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red, size: 20.w),
                      SizedBox(width: 10.w),
                      Text('Block User'),
                    ],
                  ),
                ),
            ],
          )),
    ],
  );
}

// 🔥 Extract input section to separate method for clarity
Widget _buildInputSection() {
  return Obx(() {
    // Disable input if blocked
    if (controller.isBlocked.value) {
      return _buildDisabledInput();
    }

    // Normal input (existing code)
    return Container(
      width: 360.w,
      constraints: BoxConstraints(maxHeight: 170.h, minHeight: 70.h),
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 10.h, top: 10.h),
      color: AppColors.primaryBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            width: 270.w,
            constraints: BoxConstraints(maxHeight: 170.h, minHeight: 30.h),
            padding: EdgeInsets.only(top: 5.h, bottom: 5.h),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              border: Border.all(color: AppColors.primarySecondaryElementText),
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: Row(children: [
              Container(
                width: 220.w,
                constraints: BoxConstraints(maxHeight: 150.h, minHeight: 20.h),
                child: TextField(
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  controller: controller.myinputController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: "Message...",
                    isDense: true,
                    contentPadding: EdgeInsets.only(left: 10.w, top: 0, bottom: 0),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    hintStyle: TextStyle(
                      color: AppColors.primarySecondaryElementText,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  child: Image.asset("assets/icons/send.png"),
                ),
                onTap: () {
                  controller.sendMessage();
                },
              )
            ]),
          ),
          GestureDetector(
            child: Container(
              height: 40.w,
              width: 40.w,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primaryElement,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
                borderRadius: BorderRadius.all(Radius.circular(40.w)),
              ),
              child: controller.state.more_status.value
                  ? Image.asset("assets/icons/by.png")
                  : Image.asset("assets/icons/add.png"),
            ),
            onTap: () {
              controller.goMore();
            },
          ),
        ],
      ),
    );
  });
}

// 🔥 NEW: Disabled input UI
Widget _buildDisabledInput() {
  return Container(
    width: 360.w,
    padding: EdgeInsets.all(20.w),
    decoration: BoxDecoration(
      color: AppColors.primarySecondaryBackground,
      border: Border(
        top: BorderSide(
          color: Colors.red.withOpacity(0.3),
          width: 2,
        ),
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.block, color: Colors.red, size: 20.w),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            'Chat is blocked',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.primaryText.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

// 🔥 ENHANCED: Extract more options to separate method
Widget _buildMoreOptions() {
  return Positioned(
    right: 20.w,
    bottom: 70.h,
    height: 200.w,
    width: 40.w,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMoreOption(
          icon: "assets/icons/file.png",
          onTap: () => controller.imgFromGallery(),
        ),
        _buildMoreOption(
          icon: "assets/icons/photo.png",
          onTap: () => controller.imgFromCamera(),
        ),
        _buildMoreOption(
          icon: "assets/icons/call.png",
          onTap: () => controller.callAudio(),
        ),
        _buildMoreOption(
          icon: "assets/icons/video.png",
          onTap: () => controller.callVideo(),
        ),
      ],
    ),
  );
}

Widget _buildMoreOption({required String icon, required VoidCallback onTap}) {
  return GestureDetector(
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
            offset: Offset(1, 1),
          ),
        ],
        borderRadius: BorderRadius.all(Radius.circular(40.w)),
      ),
      child: Image.asset(icon),
    ),
    onTap: onTap,
  );
}

// 🔥 Add these imports at the top:
import 'package:sakoa/common/services/blocking_service.dart';
import 'package:sakoa/common/widgets/toast.dart';
