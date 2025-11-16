import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/entities/contact_entity.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'index.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ContactPage extends GetView<ContactController> {
  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        "Contacts",
        style: TextStyle(
          color: AppColors.primaryText,
          fontSize: 16.sp,
          fontWeight: FontWeight.normal,
        ),
      ),
      actions: [
        // ✅ FIX #3: Prominent notification badge with bell icon
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications,
                size: 28.w,
                color: AppColors.primaryText,
              ),
              onPressed: () {
                // Tap to jump to requests tab
                controller.state.selectedTab.value = 1;
              },
            ),
            Obx(() {
              int count = controller.state.pendingRequestCount.value;
              if (count == 0) return SizedBox.shrink();

              return Positioned(
                right: 8.w,
                top: 8.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10.w),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    minWidth: 18.w,
                    minHeight: 18.w,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          ],
        ),
        SizedBox(width: 5.w),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      decoration: BoxDecoration(
        color: AppColors.primarySecondaryBackground,
        borderRadius: BorderRadius.circular(20.w),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.primaryText),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              onChanged: (value) {
                controller.state.searchQuery.value = value;
                // Debounced search - only search after user stops typing
                Future.delayed(Duration(milliseconds: 500), () {
                  if (controller.state.searchQuery.value == value) {
                    controller.searchUsers(value);
                  }
                });
              },
              decoration: InputDecoration(
                hintText: "Search users by name or email...",
                hintStyle: TextStyle(
                  color: AppColors.primaryText.withOpacity(0.5),
                  fontSize: 14.sp,
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 14.sp,
              ),
            ),
          ),
          Obx(() => controller.state.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.primaryText),
                  onPressed: () {
                    controller.state.searchQuery.value = "";
                    controller.state.searchResults.clear();
                  },
                )
              : SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w),
      child: Row(
        children: [
          _buildTab("Contacts", 0),
          SizedBox(width: 10.w),
          _buildTab("Requests", 1),
          SizedBox(width: 10.w),
          _buildTab("Blocked", 2),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    return Obx(() => Expanded(
          child: InkWell(
            onTap: () => controller.state.selectedTab.value = index,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: controller.state.selectedTab.value == index
                    ? AppColors.primaryElement
                    : AppColors.primarySecondaryBackground,
                borderRadius: BorderRadius.circular(10.w),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: controller.state.selectedTab.value == index
                            ? Colors.white
                            : AppColors.primaryText,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Badge for Requests tab
                  if (title == "Requests" &&
                      controller.state.pendingRequestCount.value > 0)
                    Positioned(
                      right: 10.w,
                      top: 5.h,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 20.w,
                          minHeight: 20.w,
                        ),
                        child: Center(
                          child: Text(
                            '${controller.state.pendingRequestCount.value}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ));
  }

  /// ✨ SKELETON LOADER: Professional loading placeholder
  Widget _buildContactSkeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.primarySecondaryBackground,
      highlightColor: Colors.grey.shade300,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: AppColors.primarySecondaryBackground,
          borderRadius: BorderRadius.circular(10.w),
        ),
        child: Row(
          children: [
            // Avatar skeleton
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.w),
              ),
            ),
            SizedBox(width: 10.w),
            // Name skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.w),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: 80.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.w),
                    ),
                  ),
                ],
              ),
            ),
            // Buttons skeleton
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.w),
              ),
            ),
            SizedBox(width: 10.w),
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.w),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({required int index}) {
    // 🔥 REACTIVE FIX: Access contact directly from controller inside Obx
    // This ensures the widget rebuilds when contact object is replaced
    return Obx(() {
      // Re-read the contact from the list on every rebuild
      final contact = controller.state.acceptedContacts[index];

      // 🔥 FIX: Don't use TweenAnimationBuilder child cache - it prevents reactivity!
      // Build the entire widget tree inside Obx() so changes are detected
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: AppColors.primarySecondaryBackground,
          borderRadius: BorderRadius.circular(10.w),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with online status indicator
            Stack(
              children: [
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25.w),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: contact.contact_avatar ?? "",
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25.w),
                        image: DecorationImage(
                            image: imageProvider, fit: BoxFit.cover),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.person, size: 50.w),
                  ),
                ),
                // Online/Offline status indicator - 🔥 Updates via ContactController
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      color: (contact.contact_online ?? 0) == 1
                          ? Colors.green
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 10.w),
            // Name
            Expanded(
              child: Text(
                contact.contact_name ?? "Unknown",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            // Chat button
            IconButton(
              icon: Icon(Icons.chat, color: AppColors.primaryElement),
              onPressed: () {
                // Use original goChat from ContactController
                controller.goChat(ContactItem(
                  token: contact.contact_token,
                  name: contact.contact_name,
                  avatar: contact.contact_avatar,
                  online: contact.contact_online ??
                      0, // ✅ Default to offline, not online!
                ));
              },
            ),
            // Block button
            IconButton(
              icon: Icon(Icons.block, color: Colors.red),
              onPressed: () {
                Get.defaultDialog(
                  title: "Block ${contact.contact_name}?",
                  middleText:
                      "Are you sure you want to block ${contact.contact_name}? They will be removed from your contacts and won't be able to send you messages.",
                  textConfirm: "Block",
                  textCancel: "Cancel",
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  cancelTextColor: Colors.grey,
                  onConfirm: () {
                    Get.back(); // Close dialog
                    controller.blockUser(
                      contact.contact_token ?? "",
                      contact.contact_name ?? "",
                      contact.contact_avatar ?? "",
                    );
                  },
                );
              },
            ),
          ],
        ),
      );
    }); // 🔥 Close Obx()
  }

  Widget _buildRequestItem(ContactEntity request) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.primarySecondaryBackground,
        borderRadius: BorderRadius.circular(10.w),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.w),
            ),
            child: CachedNetworkImage(
              imageUrl: request.user_avatar ?? "",
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.w),
                  image:
                      DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
              errorWidget: (context, url, error) =>
                  Icon(Icons.person, size: 50.w),
            ),
          ),
          SizedBox(width: 10.w),
          // Name
          Expanded(
            child: Text(
              request.user_name ?? "Unknown",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
          ),
          // Accept button
          IconButton(
            icon: Icon(Icons.check, color: Colors.green),
            onPressed: () => controller.acceptContactRequest(request),
          ),
          // Reject button
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: () => controller.rejectContactRequest(request),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedItem(ContactEntity blocked) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.primarySecondaryBackground,
        borderRadius: BorderRadius.circular(10.w),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.w),
            ),
            child: CachedNetworkImage(
              imageUrl: blocked.contact_avatar ?? "",
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.w),
                  image:
                      DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
              errorWidget: (context, url, error) =>
                  Icon(Icons.person, size: 50.w),
            ),
          ),
          SizedBox(width: 10.w),
          // Name
          Expanded(
            child: Text(
              blocked.contact_name ?? "Unknown",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
          ),
          // Unblock button
          ElevatedButton(
            onPressed: () => controller.unblockUser(blocked),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryElement,
            ),
            child: Text("Unblock", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(UserProfile user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.primarySecondaryBackground,
        borderRadius: BorderRadius.circular(10.w),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.w),
            ),
            child: CachedNetworkImage(
              imageUrl: user.avatar ?? "",
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.w),
                  image:
                      DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
              errorWidget: (context, url, error) =>
                  Icon(Icons.person, size: 50.w),
            ),
          ),
          SizedBox(width: 10.w),
          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? "Unknown",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  user.email ?? "",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primaryText.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Dynamic status button with real-time updates
          Obx(() {
            var config = controller.getButtonConfig(user.token);
            return ElevatedButton.icon(
              onPressed: config['enabled']
                  ? () async {
                      if (config['text'] == '📬 Respond') {
                        // Switch to requests tab
                        controller.state.selectedTab.value = 1;
                      } else if (config['text'] == '⏳ Pending') {
                        // Cancel request
                        if (user.token != null) {
                          await controller.cancelContactRequest(user.token!);
                        }
                      } else {
                        // Add contact
                        await controller.sendContactRequest(user);
                      }
                    }
                  : null,
              icon: Icon(config['icon'], size: 16.sp),
              label: Text(
                config['text'],
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: config['enabled']
                    ? config['color']
                    : config['color'].withOpacity(0.6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          SizedBox(height: 10.h),

          // Show search results or tabs
          Obx(() {
            if (controller.state.searchQuery.value.isNotEmpty) {
              // Search results view with loading indicator
              return Expanded(
                child: controller.state.isSearching.value
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 50.w,
                              height: 50.w,
                              child: CircularProgressIndicator(
                                color: AppColors.primaryElement,
                                strokeWidth: 3.w,
                              ),
                            ),
                            SizedBox(height: 15.h),
                            Text(
                              "Searching users...",
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : controller.state.searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 60.w,
                                  color: AppColors.primaryText.withOpacity(0.3),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  "No users found",
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  "Try a different search term",
                                  style: TextStyle(
                                    color:
                                        AppColors.primaryText.withOpacity(0.6),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15.w),
                                child: Text(
                                  "${controller.state.searchResults.length} user(s) found",
                                  style: TextStyle(
                                    color:
                                        AppColors.primaryText.withOpacity(0.7),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Expanded(
                                child: ListView.builder(
                                  itemCount:
                                      controller.state.searchResults.length,
                                  itemBuilder: (context, index) {
                                    return _buildSearchResultItem(
                                        controller.state.searchResults[index]);
                                  },
                                ),
                              ),
                            ],
                          ),
              );
            } else {
              // Tabs view
              return Expanded(
                child: Column(
                  children: [
                    _buildTabs(),
                    SizedBox(height: 15.h),
                    Expanded(
                      child: Obx(() {
                        int selectedTab = controller.state.selectedTab.value;

                        if (selectedTab == 0) {
                          // ✨ SKELETON LOADERS: Show during initial loading (cache hit shows content instantly!)
                          if (controller.state.acceptedContacts.isEmpty &&
                              controller.state.isLoadingContacts.value) {
                            return ListView.builder(
                              itemCount: 8,
                              itemBuilder: (context, index) =>
                                  _buildContactSkeleton(),
                            );
                          }

                          // Accepted Contacts with Pull-to-Refresh and Pagination
                          if (controller.state.acceptedContacts.isEmpty &&
                              !controller.state.isLoadingContacts.value) {
                            return RefreshIndicator(
                              onRefresh: controller.refreshContacts,
                              child: SingleChildScrollView(
                                physics: AlwaysScrollableScrollPhysics(),
                                child: Container(
                                  height:
                                      MediaQuery.of(Get.context!).size.height *
                                          0.6,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.people_outline,
                                          size: 64.w,
                                          color: AppColors.primaryText
                                              .withOpacity(0.3)),
                                      SizedBox(height: 10.h),
                                      Text(
                                        "No contacts yet",
                                        style: TextStyle(
                                            color: AppColors.primaryText,
                                            fontSize: 16.sp),
                                      ),
                                      SizedBox(height: 5.h),
                                      Text(
                                        "Start searching to add friends!",
                                        style: TextStyle(
                                            color: AppColors.primaryText
                                                .withOpacity(0.6),
                                            fontSize: 12.sp),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: controller.refreshContacts,
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (ScrollNotification scrollInfo) {
                                // Lazy loading: Load more when scrolled to 80% of the list
                                if (!controller.state.isLoadingContacts.value &&
                                    controller.state.hasMoreContacts.value &&
                                    scrollInfo.metrics.pixels >=
                                        scrollInfo.metrics.maxScrollExtent *
                                            0.8) {
                                  controller.loadMoreContacts();
                                }
                                return false;
                              },
                              child: Obx(() => ListView.builder(
                                    // ✅ FIX: Wrap itemCount in Obx() for reactivity!
                                    itemCount: controller
                                            .state.acceptedContacts.length +
                                        (controller.state.hasMoreContacts.value
                                            ? 1
                                            : 0),
                                    itemBuilder: (context, index) {
                                      if (index ==
                                          controller
                                              .state.acceptedContacts.length) {
                                        // Loading indicator at the end
                                        return Obx(() => controller
                                                .state.isLoadingContacts.value
                                            ? Container(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 20.h),
                                                alignment: Alignment.center,
                                                child: SizedBox(
                                                  width: 30.w,
                                                  height: 30.w,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: AppColors
                                                        .primaryElement,
                                                    strokeWidth: 2.5.w,
                                                  ),
                                                ),
                                              )
                                            : SizedBox.shrink());
                                      }
                                      return _buildContactItem(
                                        index: index, // ✨ Pass index for lookup
                                      );
                                    },
                                  )),
                            ),
                          );
                        } else if (selectedTab == 1) {
                          // Pending Requests with Pull-to-Refresh
                          return RefreshIndicator(
                            onRefresh: controller.refreshRequests,
                            child: Obx(() => controller
                                    .state.pendingRequests.isEmpty
                                ? SingleChildScrollView(
                                    physics: AlwaysScrollableScrollPhysics(),
                                    child: Container(
                                      height: MediaQuery.of(Get.context!)
                                              .size
                                              .height *
                                          0.6,
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.inbox_outlined,
                                              size: 64.w,
                                              color: AppColors.primaryText
                                                  .withOpacity(0.3)),
                                          SizedBox(height: 10.h),
                                          Text(
                                            "No pending requests",
                                            style: TextStyle(
                                                color: AppColors.primaryText,
                                                fontSize: 16.sp),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    // ✅ FIX: Now reactive!
                                    itemCount:
                                        controller.state.pendingRequests.length,
                                    itemBuilder: (context, index) {
                                      return _buildRequestItem(controller
                                          .state.pendingRequests[index]);
                                    },
                                  )),
                          );
                        } else {
                          // Blocked Users with Pull-to-Refresh
                          return RefreshIndicator(
                            onRefresh: controller.refreshBlocked,
                            child: Obx(() => controller
                                    .state.blockedList.isEmpty
                                ? SingleChildScrollView(
                                    physics: AlwaysScrollableScrollPhysics(),
                                    child: Container(
                                      height: MediaQuery.of(Get.context!)
                                              .size
                                              .height *
                                          0.6,
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.block_outlined,
                                              size: 64.w,
                                              color: AppColors.primaryText
                                                  .withOpacity(0.3)),
                                          SizedBox(height: 10.h),
                                          Text(
                                            "No blocked users",
                                            style: TextStyle(
                                                color: AppColors.primaryText,
                                                fontSize: 16.sp),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    // ✅ FIX: Now reactive!
                                    itemCount:
                                        controller.state.blockedList.length,
                                    itemBuilder: (context, index) {
                                      return _buildBlockedItem(
                                          controller.state.blockedList[index]);
                                    },
                                  )),
                          );
                        }
                      }),
                    ),
                  ],
                ),
              );
            }
          }),
        ],
      ),
    );
  }
}
