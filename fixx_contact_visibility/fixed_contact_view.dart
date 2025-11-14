import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sakoa/common/widgets/widgets.dart';
import 'package:sakoa/common/entities/contact_entity.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'index.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
        // ✨ PROMINENT REQUEST BADGE - ALWAYS VISIBLE
        Obx(() {
          int requestCount = controller.state.pendingRequestCount.value;
          
          return Container(
            margin: EdgeInsets.only(right: 15.w),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications,
                    color: requestCount > 0 ? AppColors.primaryElement : AppColors.primaryText,
                    size: 28.w,
                  ),
                  onPressed: () {
                    // Switch to requests tab when tapped
                    controller.state.selectedTab.value = 1;
                  },
                ),
                if (requestCount > 0)
                  Positioned(
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
                        minHeight: 18.h,
                      ),
                      child: Center(
                        child: Text(
                          requestCount > 99 ? '99+' : '$requestCount',
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
          );
        }),
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
                Future.delayed(Duration(milliseconds: 500), () {
                  if (controller.state.searchQuery.value == value) {
                    controller.searchUsers(value);
                  }
                });
              },
              decoration: InputDecoration(
                hintText: "Search users by name...",
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
    return Obx(() {
      bool isSelected = controller.state.selectedTab.value == index;
      int badgeCount = title == "Requests" ? controller.state.pendingRequestCount.value : 0;
      
      return Expanded(
        child: InkWell(
          onTap: () => controller.state.selectedTab.value = index,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryElement
                  : AppColors.primarySecondaryBackground,
              borderRadius: BorderRadius.circular(10.w),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryElement.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.primaryText,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Badge for Requests tab
                if (title == "Requests" && badgeCount > 0)
                  Positioned(
                    right: 10.w,
                    top: 6.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : AppColors.primarySecondaryBackground,
                          width: 2,
                        ),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20.w,
                        minHeight: 20.h,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
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
      );
    });
  }

  Widget _buildContactItem(ContactEntity contact) {
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
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with online status
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
                      image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.person, size: 50.w),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14.w,
                  height: 14.w,
                  decoration: BoxDecoration(
                    color: (contact.contact_online ?? 0) == 1 ? Colors.green : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
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
              controller.goChat(ContactItem(
                token: contact.contact_token,
                name: contact.contact_name,
                avatar: contact.contact_avatar,
                online: contact.contact_online ?? 1,
              ));
            },
          ),
          // Block button
          IconButton(
            icon: Icon(Icons.block, color: Colors.red),
            onPressed: () {
              controller.blockUser(
                contact.contact_token ?? "",
                contact.contact_name ?? "",
                contact.contact_avatar ?? "",
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(ContactEntity request) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.primarySecondaryBackground,
        borderRadius: BorderRadius.circular(10.w),
        border: Border.all(
          color: AppColors.primaryElement.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryElement.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
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
                  image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
              errorWidget: (context, url, error) => Icon(Icons.person, size: 50.w),
            ),
          ),
          SizedBox(width: 10.w),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.user_name ?? "Unknown",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  "Wants to connect",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primaryText.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Accept button
          Container(
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8.w),
            ),
            child: IconButton(
              icon: Icon(Icons.check, color: Colors.white),
              onPressed: () => controller.acceptContactRequest(request),
            ),
          ),
          SizedBox(width: 8.w),
          // Reject button
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8.w),
            ),
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => controller.rejectContactRequest(request),
            ),
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
                  image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
              errorWidget: (context, url, error) => Icon(Icons.person, size: 50.w),
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
                  image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
              errorWidget: (context, url, error) => Icon(Icons.person, size: 50.w),
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
          // Dynamic status button
          Obx(() {
            var config = controller.getButtonConfig(user.token);
            return ElevatedButton.icon(
              onPressed: config['enabled']
                  ? () async {
                      if (config['text'] == '📬 Respond') {
                        controller.state.selectedTab.value = 1;
                      } else if (config['text'] == '⏳ Pending') {
                        if (user.token != null) {
                          await controller.cancelContactRequest(user.token!);
                        }
                      } else {
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
              // Search results view
              return Expanded(
                child: controller.state.isSearching.value
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.primaryElement,
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              "Searching users...",
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 14.sp,
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
                                    color: AppColors.primaryText.withOpacity(0.6),
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
                                    color: AppColors.primaryText.withOpacity(0.7),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: controller.state.searchResults.length,
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
                          // Contacts Tab
                          return Obx(() {
                            if (controller.state.isLoadingContacts.value &&
                                controller.state.acceptedContacts.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: AppColors.primaryElement,
                                    ),
                                    SizedBox(height: 10.h),
                                    Text(
                                      "Loading contacts...",
                                      style: TextStyle(
                                        color: AppColors.primaryText,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (controller.state.acceptedContacts.isEmpty) {
                              return RefreshIndicator(
                                onRefresh: controller.refreshContacts,
                                child: SingleChildScrollView(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  child: Container(
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.people_outline,
                                            size: 64.w,
                                            color: AppColors.primaryText.withOpacity(0.3)),
                                        SizedBox(height: 10.h),
                                        Text(
                                          "No contacts yet",
                                          style: TextStyle(
                                              color: AppColors.primaryText, fontSize: 16.sp),
                                        ),
                                        SizedBox(height: 5.h),
                                        Text(
                                          "Start searching to add friends!",
                                          style: TextStyle(
                                              color: AppColors.primaryText.withOpacity(0.6),
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
                              child: ListView.builder(
                                itemCount: controller.state.acceptedContacts.length,
                                itemBuilder: (context, index) {
                                  return _buildContactItem(
                                      controller.state.acceptedContacts[index]);
                                },
                              ),
                            );
                          });
                        } else if (selectedTab == 1) {
                          // Requests Tab
                          return RefreshIndicator(
                            onRefresh: controller.refreshRequests,
                            child: controller.state.pendingRequests.isEmpty
                                ? SingleChildScrollView(
                                    physics: AlwaysScrollableScrollPhysics(),
                                    child: Container(
                                      height: MediaQuery.of(context).size.height * 0.6,
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.inbox_outlined,
                                              size: 64.w,
                                              color: AppColors.primaryText.withOpacity(0.3)),
                                          SizedBox(height: 10.h),
                                          Text(
                                            "No pending requests",
                                            style: TextStyle(
                                                color: AppColors.primaryText, fontSize: 16.sp),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: controller.state.pendingRequests.length,
                                    itemBuilder: (context, index) {
                                      return _buildRequestItem(
                                          controller.state.pendingRequests[index]);
                                    },
                                  ),
                          );
                        } else {
                          // Blocked Tab
                          return RefreshIndicator(
                            onRefresh: controller.refreshBlocked,
                            child: controller.state.blockedList.isEmpty
                                ? SingleChildScrollView(
                                    physics: AlwaysScrollableScrollPhysics(),
                                    child: Container(
                                      height: MediaQuery.of(context).size.height * 0.6,
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.block_outlined,
                                              size: 64.w,
                                              color: AppColors.primaryText.withOpacity(0.3)),
                                          SizedBox(height: 10.h),
                                          Text(
                                            "No blocked users",
                                            style: TextStyle(
                                                color: AppColors.primaryText, fontSize: 16.sp),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: controller.state.blockedList.length,
                                    itemBuilder: (context, index) {
                                      return _buildBlockedItem(
                                          controller.state.blockedList[index]);
                                    },
                                  ),
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
