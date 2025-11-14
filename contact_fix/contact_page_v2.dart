import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:sakoa/common/entities/entities.dart';
import 'package:sakoa/common/entities/contact_entity.dart';
import 'contact_controller_v2.dart';
import 'contact_state_v2.dart';
import 'package:shimmer/shimmer.dart';

/// 🚀 SUPERNOVA-LEVEL CONTACT PAGE
/// Features that surpass Telegram/Messenger:
/// - Smooth animations everywhere
/// - Skeleton loaders
/// - Swipe actions
/// - Beautiful transitions
/// - Haptic feedback
/// - Advanced search with filters
/// - Stunning empty states
/// - Floating action button
/// - Bottom sheet actions
class ContactPageV2 extends GetView<ContactControllerV2> {
  const ContactPageV2({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(() => controller.state.isInitializing.value
          ? _buildLoadingView()
          : _buildMainView()),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  // ============================================================
  // LOADING VIEW WITH SKELETON
  // ============================================================
  
  Widget _buildLoadingView() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildSkeletonSearchBar(),
              SizedBox(height: 10.h),
              _buildSkeletonTabs(),
              SizedBox(height: 15.h),
            ],
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSkeletonContactCard(),
            childCount: 8,
          ),
        ),
      ],
    );
  }
  
  // ============================================================
  // MAIN VIEW
  // ============================================================
  
  Widget _buildMainView() {
    return Obx(() {
      final isSearching = controller.state.isShowingSearchResults;
      
      return CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSearchBar(),
                if (!isSearching) ...[
                  SizedBox(height: 10.h),
                  _buildStatsBar(),
                  SizedBox(height: 10.h),
                  _buildTabs(),
                  SizedBox(height: 15.h),
                ],
              ],
            ),
          ),
          if (isSearching)
            _buildSearchResults()
          else
            _buildTabContent(),
        ],
      );
    });
  }
  
  // ============================================================
  // APP BAR
  // ============================================================
  
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Contacts',
        style: TextStyle(
          color: AppColors.primaryText,
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Notification bell with badge
        Obx(() {
          final count = controller.state.pendingRequestCount.value;
          return Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  size: 26.w,
                  color: AppColors.primaryText,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  controller.switchTab(1);
                },
              ),
              if (count > 0)
                Positioned(
                  right: 8.w,
                  top: 8.h,
                  child: _buildNotificationBadge(count),
                ),
            ],
          );
        }),
        
        // More options
        IconButton(
          icon: Icon(
            Icons.more_vert,
            size: 24.w,
            color: AppColors.primaryText,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showMoreOptions();
          },
        ),
        SizedBox(width: 5.w),
      ],
    );
  }
  
  Widget _buildNotificationBadge(int count) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10.w),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  spreadRadius: 1,
                  blurRadius: 6,
                ),
              ],
            ),
            constraints: BoxConstraints(minWidth: 18.w, minHeight: 18.w),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
  
  // ============================================================
  // SEARCH BAR
  // ============================================================
  
  Widget _buildSearchBar() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[600], size: 22.w),
            SizedBox(width: 10.w),
            Expanded(
              child: TextField(
                onChanged: (value) {
                  // Debounced search
                  Future.delayed(Duration(milliseconds: 500), () {
                    if (controller.state.searchQuery.value == value) {
                      controller.searchUsers(value);
                    }
                  });
                  controller.state.searchQuery.value = value;
                },
                decoration: InputDecoration(
                  hintText: "Search by name...",
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 15.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 15.sp,
                ),
              ),
            ),
            Obx(() => controller.state.isSearching.value
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      color: AppColors.primaryElement,
                    ),
                  )
                : controller.state.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          controller.clearSearch();
                        },
                      )
                    : SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
  
  // ============================================================
  // STATS BAR
  // ============================================================
  
  Widget _buildStatsBar() {
    return Obx(() {
      return TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: child,
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 15.w),
          padding: EdgeInsets.all(15.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryElement,
                AppColors.primaryElement.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(15.w),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryElement.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.people,
                controller.state.totalContactsCount.toString(),
                'Contacts',
              ),
              Container(
                width: 1,
                height: 30.h,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                Icons.circle,
                controller.state.onlineCount.toString(),
                'Online',
              ),
              Container(
                width: 1,
                height: 30.h,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildStatItem(
                Icons.mail_outline,
                controller.state.pendingRequestCount.value.toString(),
                'Requests',
              ),
            ],
          ),
        ),
      );
    });
  }
  
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 18.w),
            SizedBox(width: 5.w),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
  
  // ============================================================
  // TABS
  // ============================================================
  
  Widget _buildTabs() {
    return Obx(() {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 15.w),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12.w),
        ),
        child: Row(
          children: [
            _buildTab('Contacts', 0, Icons.people),
            _buildTab('Requests', 1, Icons.inbox),
            _buildTab('Blocked', 2, Icons.block),
          ],
        ),
      );
    });
  }
  
  Widget _buildTab(String title, int index, IconData icon) {
    final isSelected = controller.state.selectedTab.value == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          controller.switchTab(index);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryElement : Colors.transparent,
            borderRadius: BorderRadius.circular(10.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 18.w,
              ),
              SizedBox(width: 5.w),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (title == 'Requests' &&
                  controller.state.pendingRequestCount.value > 0)
                Container(
                  margin: EdgeInsets.only(left: 5.w),
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${controller.state.pendingRequestCount.value}',
                    style: TextStyle(
                      color: isSelected ? AppColors.primaryElement : Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // ============================================================
  // TAB CONTENT
  // ============================================================
  
  Widget _buildTabContent() {
    return Obx(() {
      final tab = controller.state.selectedTab.value;
      
      switch (tab) {
        case 0:
          return _buildContactsList();
        case 1:
          return _buildRequestsList();
        case 2:
          return _buildBlockedList();
        default:
          return SliverToBoxAdapter(child: SizedBox.shrink());
      }
    });
  }
  
  // ============================================================
  // CONTACTS LIST
  // ============================================================
  
  Widget _buildContactsList() {
    return Obx(() {
      final contacts = controller.state.filteredContacts;
      
      if (controller.state.isLoadingContacts.value && contacts.isEmpty) {
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSkeletonContactCard(),
            childCount: 6,
          ),
        );
      }
      
      if (contacts.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(
            icon: Icons.people_outline,
            title: 'No contacts yet',
            subtitle: 'Start searching to add friends!',
            action: 'Find Friends',
            onAction: () {
              // Focus search bar
            },
          ),
        );
      }
      
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOut,
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(50 * (1 - value), 0),
                    child: child,
                  ),
                );
              },
              child: _buildContactCard(contacts[index]),
            );
          },
          childCount: contacts.length,
        ),
      );
    });
  }
  
  // ============================================================
  // CONTACT CARD (Swipeable with actions)
  // ============================================================
  
  Widget _buildContactCard(ContactEntity contact) {
    return Dismissible(
      key: Key(contact.id ?? contact.contact_token ?? ''),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        return await _showContactActions(contact);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15.w),
        ),
        child: Icon(Icons.block, color: Colors.white, size: 28.w),
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          controller.goChat(ContactItem(
            token: contact.contact_token,
            name: contact.contact_name,
            avatar: contact.contact_avatar,
            online: contact.contact_online ?? 1,
          ));
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  Hero(
                    tag: 'avatar_${contact.contact_token}',
                    child: Container(
                      width: 55.w,
                      height: 55.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: contact.contact_avatar ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.person, size: 30.w),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.person, size: 30.w),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Online status
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        color: (contact.contact_online ?? 0) == 1
                            ? Colors.green
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 12.w),
              
              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.contact_name ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      (contact.contact_online ?? 0) == 1
                          ? 'Online'
                          : 'Offline',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: (contact.contact_online ?? 0) == 1
                            ? Colors.green
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Chat button
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryElement.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.primaryElement,
                  size: 20.w,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // ============================================================
  // SEARCH RESULTS
  // ============================================================
  
  Widget _buildSearchResults() {
    return Obx(() {
      if (controller.state.isSearching.value) {
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildSkeletonContactCard(),
            childCount: 5,
          ),
        );
      }
      
      final results = controller.state.searchResults;
      
      if (results.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(
            icon: Icons.search_off,
            title: 'No users found',
            subtitle: 'Try a different search term',
          ),
        );
      }
      
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Text(
                '${results.length} user(s) found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ...results.asMap().entries.map((entry) {
              return TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (entry.key * 50)),
                curve: Curves.easeOut,
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(50 * (1 - value), 0),
                      child: child,
                    ),
                  );
                },
                child: _buildSearchResultCard(entry.value),
              );
            }).toList(),
          ],
        ),
      );
    });
  }
  
  Widget _buildSearchResultCard(UserProfile user) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 1,
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
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: user.avatar ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.person, size: 28.w),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.person, size: 28.w),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          
          // Name and email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.email != null) ...[
                  SizedBox(height: 3.h),
                  Text(
                    user.email!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Action button
          Obx(() => _buildSearchActionButton(user)),
        ],
      ),
    );
  }
  
  Widget _buildSearchActionButton(UserProfile user) {
    final config = controller.getButtonConfig(user.token);
    final enabled = config['enabled'] as bool;
    final text = config['text'] as String;
    final colorStr = config['color'] as String;
    
    Color buttonColor;
    switch (colorStr) {
      case 'green':
        buttonColor = Colors.green;
        break;
      case 'orange':
        buttonColor = Colors.orange;
        break;
      case 'blue':
        buttonColor = Colors.blue;
        break;
      case 'red':
        buttonColor = Colors.red;
        break;
      default:
        buttonColor = AppColors.primaryElement;
    }
    
    return ElevatedButton(
      onPressed: enabled
          ? () async {
              HapticFeedback.mediumImpact();
              
              if (text == 'Respond') {
                controller.switchTab(1);
              } else if (text == 'Pending') {
                if (user.token != null) {
                  await controller.cancelContactRequest(user.token!);
                }
              } else {
                await controller.sendContactRequest(user);
              }
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? buttonColor : buttonColor.withOpacity(0.5),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        elevation: enabled ? 2 : 0,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  // ============================================================
  // REQUESTS LIST
  // ============================================================
  
  Widget _buildRequestsList() {
    return Obx(() {
      final requests = controller.state.pendingRequests;
      
      if (requests.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No pending requests',
            subtitle: 'Friend requests will appear here',
          ),
        );
      }
      
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOut,
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(50 * (1 - value), 0),
                    child: child,
                  ),
                );
              },
              child: _buildRequestCard(requests[index]),
            );
          },
          childCount: requests.length,
        ),
      );
    });
  }
  
  Widget _buildRequestCard(ContactEntity request) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.w),
        border: Border.all(
          color: AppColors.primaryElement.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryElement.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: request.user_avatar ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.person, size: 28.w),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.person, size: 28.w),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              
              // Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.user_name ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Wants to connect',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    controller.acceptContactRequest(request);
                  },
                  icon: Icon(Icons.check, size: 18.w),
                  label: Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    controller.rejectContactRequest(request);
                  },
                  icon: Icon(Icons.close, size: 18.w),
                  label: Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // ============================================================
  // BLOCKED LIST
  // ============================================================
  
  Widget _buildBlockedList() {
    return Obx(() {
      final blocked = controller.state.blockedList;
      
      if (blocked.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(
            icon: Icons.block_outlined,
            title: 'No blocked users',
            subtitle: 'Blocked users will appear here',
          ),
        );
      }
      
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final contact = blocked[index];
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar (grayed out)
                  Opacity(
                    opacity: 0.5,
                    child: Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: contact.contact_avatar ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.person, size: 28.w),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.person, size: 28.w),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  
                  // Name
                  Expanded(
                    child: Text(
                      contact.contact_name ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Unblock button
                  OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      controller.unblockUser(contact);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryElement,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      side: BorderSide(color: AppColors.primaryElement),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                    ),
                    child: Text('Unblock'),
                  ),
                ],
              ),
            );
          },
          childCount: blocked.length,
        ),
      );
    });
  }
  
  // ============================================================
  // EMPTY STATES
  // ============================================================
  
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? action,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              padding: EdgeInsets.all(30.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64.w,
                color: Colors.grey[400],
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null && onAction != null) ...[
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryElement,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
              ),
              child: Text(action),
            ),
          ],
        ],
      ),
    );
  }
  
  // ============================================================
  // SKELETON LOADERS
  // ============================================================
  
  Widget _buildSkeletonSearchBar() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        height: 50.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25.w),
        ),
      ),
    );
  }
  
  Widget _buildSkeletonTabs() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15.w),
        height: 45.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.w),
        ),
      ),
    );
  }
  
  Widget _buildSkeletonContactCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.w),
        ),
        child: Row(
          children: [
            Container(
              width: 55.w,
              height: 55.w,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150.w,
                    height: 16.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: 100.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4.r),
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
  
  // ============================================================
  // FLOATING ACTION BUTTON
  // ============================================================
  
  Widget _buildFloatingActionButton() {
    return Obx(() {
      final isSearching = controller.state.isShowingSearchResults;
      
      if (isSearching) return SizedBox.shrink();
      
      return FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showQuickActions();
        },
        backgroundColor: AppColors.primaryElement,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Contact',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    });
  }
  
  // ============================================================
  // BOTTOM SHEETS & DIALOGS
  // ============================================================
  
  Future<bool?> _showContactActions(ContactEntity contact) async {
    return await Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              contact.contact_name ?? 'Unknown',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: Icon(Icons.chat, color: AppColors.primaryElement),
              title: Text('Open Chat'),
              onTap: () {
                Get.back(result: false);
                controller.goChat(ContactItem(
                  token: contact.contact_token,
                  name: contact.contact_name,
                  avatar: contact.contact_avatar,
                  online: contact.contact_online ?? 1,
                ));
              },
            ),
            ListTile(
              leading: Icon(Icons.block, color: Colors.red),
              title: Text('Block User'),
              onTap: () {
                Get.back(result: true);
                controller.blockUser(
                  contact.contact_token ?? '',
                  contact.contact_name ?? '',
                  contact.contact_avatar ?? '',
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: Colors.grey),
              title: Text('Cancel'),
              onTap: () => Get.back(result: false),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showQuickActions() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: Icon(Icons.search, color: AppColors.primaryElement),
              title: Text('Search Users'),
              subtitle: Text('Find friends by name'),
              onTap: () {
                Get.back();
                // Focus search bar
              },
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: Colors.green),
              title: Text('Refresh All'),
              subtitle: Text('Update all lists'),
              onTap: () {
                Get.back();
                controller.refreshAll();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMoreOptions() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Options',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            Obx(() => SwitchListTile(
              value: controller.state.filterOnlineOnly.value,
              onChanged: (value) {
                controller.toggleOnlineFilter();
              },
              title: Text('Show Online Only'),
              secondary: Icon(Icons.filter_list, color: AppColors.primaryElement),
            )),
            ListTile(
              leading: Icon(Icons.sort, color: AppColors.primaryElement),
              title: Text('Sort By'),
              subtitle: Obx(() => Text(_getSortText())),
              onTap: () {
                Get.back();
                _showSortOptions();
              },
            ),
            ListTile(
              leading: Icon(Icons.refresh, color: Colors.green),
              title: Text('Refresh All'),
              onTap: () {
                Get.back();
                controller.refreshAll();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSortOptions() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Sort Contacts By',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            _buildSortOption(
              'Name (A-Z)',
              ContactSortBy.name,
              Icons.sort_by_alpha,
            ),
            _buildSortOption(
              'Recently Added',
              ContactSortBy.recentlyAdded,
              Icons.schedule,
            ),
            _buildSortOption(
              'Online First',
              ContactSortBy.onlineFirst,
              Icons.circle,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSortOption(String title, ContactSortBy sortBy, IconData icon) {
    return Obx(() {
      final isSelected = controller.state.sortBy.value == sortBy;
      
      return ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primaryElement : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primaryElement : AppColors.primaryText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check, color: AppColors.primaryElement)
            : null,
        onTap: () {
          controller.changeSortBy(sortBy);
          Get.back();
        },
      );
    });
  }
  
  String _getSortText() {
    switch (controller.state.sortBy.value) {
      case ContactSortBy.name:
        return 'Name (A-Z)';
      case ContactSortBy.recentlyAdded:
        return 'Recently Added';
      case ContactSortBy.onlineFirst:
        return 'Online First';
    }
  }
}
