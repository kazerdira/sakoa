import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:sakoa/common/services/blocking_service.dart';

/// 🔥 SUPERNOVA-LEVEL BLOCK SETTINGS DIALOG
/// Professional UI for configuring block restrictions
/// with beautiful animations and smooth interactions
class BlockSettingsDialog {
  /// Show advanced block settings dialog
  static Future<BlockRestrictions?> show({
    required BuildContext context,
    required String userName,
    BlockRestrictions? currentRestrictions,
  }) async {
    return await showDialog<BlockRestrictions>(
      context: context,
      builder: (context) => _BlockSettingsDialogWidget(
        userName: userName,
        initialRestrictions: currentRestrictions,
      ),
    );
  }
}

class _BlockSettingsDialogWidget extends StatefulWidget {
  final String userName;
  final BlockRestrictions? initialRestrictions;

  const _BlockSettingsDialogWidget({
    required this.userName,
    this.initialRestrictions,
  });

  @override
  State<_BlockSettingsDialogWidget> createState() =>
      _BlockSettingsDialogWidgetState();
}

class _BlockSettingsDialogWidgetState extends State<_BlockSettingsDialogWidget>
    with TickerProviderStateMixin {
  late BlockRestrictions _restrictions;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  int _selectedPreset = 1; // 0=None, 1=Standard, 2=Strict

  @override
  void initState() {
    super.initState();
    _restrictions = widget.initialRestrictions ?? BlockRestrictions.standard();

    // Animation setup
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _applyPreset(int preset) {
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 0:
          _restrictions = BlockRestrictions.none();
          break;
        case 1:
          _restrictions = BlockRestrictions.standard();
          break;
        case 2:
          _restrictions = BlockRestrictions.strict();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 340.w,
          constraints: BoxConstraints(maxHeight: 600.h),
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(20.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(),

              // Preset Selection
              _buildPresetSelection(),

              // Restrictions List
              Flexible(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildSection(
                        title: 'Chat Security',
                        icon: Icons.security,
                        children: [
                          _buildRestrictionTile(
                            icon: Icons.screenshot_outlined,
                            title: 'Prevent Screenshots',
                            subtitle: 'Block screenshots and screen recording',
                            value: _restrictions.preventScreenshots,
                            onChanged: (val) => setState(() {
                              _restrictions = _restrictions.copyWith(
                                  preventScreenshots: val);
                              _selectedPreset = -1;
                            }),
                          ),
                          _buildRestrictionTile(
                            icon: Icons.content_copy,
                            title: 'Prevent Copy',
                            subtitle: 'Disable text selection and copying',
                            value: _restrictions.preventCopy,
                            onChanged: (val) => setState(() {
                              _restrictions =
                                  _restrictions.copyWith(preventCopy: val);
                              _selectedPreset = -1;
                            }),
                          ),
                          _buildRestrictionTile(
                            icon: Icons.download_outlined,
                            title: 'Prevent Downloads',
                            subtitle: 'Block media and file downloads',
                            value: _restrictions.preventDownload,
                            onChanged: (val) => setState(() {
                              _restrictions =
                                  _restrictions.copyWith(preventDownload: val);
                              _selectedPreset = -1;
                            }),
                          ),
                          _buildRestrictionTile(
                            icon: Icons.forward_outlined,
                            title: 'Prevent Forwarding',
                            subtitle: 'Block message forwarding',
                            value: _restrictions.preventForward,
                            onChanged: (val) => setState(() {
                              _restrictions =
                                  _restrictions.copyWith(preventForward: val);
                              _selectedPreset = -1;
                            }),
                          ),
                        ],
                      ),
                      _buildSection(
                        title: 'Privacy Controls',
                        icon: Icons.visibility_off,
                        children: [
                          _buildRestrictionTile(
                            icon: Icons.circle_outlined,
                            title: 'Hide Online Status',
                            subtitle: "Don't show when you're online",
                            value: _restrictions.hideOnlineStatus,
                            onChanged: (val) => setState(() {
                              _restrictions =
                                  _restrictions.copyWith(hideOnlineStatus: val);
                              _selectedPreset = -1;
                            }),
                          ),
                          _buildRestrictionTile(
                            icon: Icons.access_time,
                            title: 'Hide Last Seen',
                            subtitle: 'Hide your last active time',
                            value: _restrictions.hideLastSeen,
                            onChanged: (val) => setState(() {
                              _restrictions =
                                  _restrictions.copyWith(hideLastSeen: val);
                              _selectedPreset = -1;
                            }),
                          ),
                          _buildRestrictionTile(
                            icon: Icons.done_all,
                            title: 'Hide Read Receipts',
                            subtitle: "Don't show message read status",
                            value: _restrictions.hideReadReceipts,
                            onChanged: (val) => setState(() {
                              _restrictions =
                                  _restrictions.copyWith(hideReadReceipts: val);
                              _selectedPreset = -1;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.primaryElement.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.w),
          topRight: Radius.circular(20.w),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.w),
                ),
                child: Icon(
                  Icons.block,
                  color: Colors.red,
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Block ${widget.userName}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Configure privacy restrictions',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.primaryText.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelection() {
    return Container(
      margin: EdgeInsets.all(15.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.primarySecondaryBackground,
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Row(
        children: [
          _buildPresetButton(0, 'None', Colors.green),
          SizedBox(width: 4.w),
          _buildPresetButton(1, 'Standard', Colors.orange),
          SizedBox(width: 4.w),
          _buildPresetButton(2, 'Strict', Colors.red),
        ],
      ),
    );
  }

  Widget _buildPresetButton(int preset, String label, Color color) {
    final isSelected = _selectedPreset == preset;
    return Expanded(
      child: GestureDetector(
        onTap: () => _applyPreset(preset),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10.w),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : AppColors.primaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
            child: Row(
              children: [
                Icon(icon,
                    size: 16.w, color: AppColors.primaryText.withOpacity(0.6)),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primarySecondaryBackground,
              borderRadius: BorderRadius.circular(12.w),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryBackground.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: value
                  ? AppColors.primaryElement.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8.w),
            ),
            child: Icon(
              icon,
              size: 20.w,
              color: value
                  ? AppColors.primaryElement
                  : AppColors.primaryText.withOpacity(0.4),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.primaryText.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryElement,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: AppColors.primarySecondaryBackground.withOpacity(0.3),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.w),
          bottomRight: Radius.circular(20.w),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.primarySecondaryBackground,
                  borderRadius: BorderRadius.circular(10.w),
                ),
                child: Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => Get.back(result: _restrictions),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.red.shade700],
                  ),
                  borderRadius: BorderRadius.circular(10.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, color: Colors.white, size: 18.w),
                    SizedBox(width: 8.w),
                    Text(
                      'Block User',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
