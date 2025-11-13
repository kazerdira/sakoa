import 'package:flutter/material.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dots_indicator/dots_indicator.dart';

import 'index.dart';

class WelcomePage extends GetView<WelcomeController> {
  /// 页头标题
  Widget _buildPageHeadTitle(String title) {
    return Container(
      margin: EdgeInsets.only(top: (310 + 44.0).h), // 顶部系统栏 44px
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.primaryElementText,
          fontFamily: "Montserrat",
          fontWeight: FontWeight.bold,
          fontSize: 45.sp,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.primaryElement,
      body: Container(
          width: 360.w,
          height: 780.h,
          child: _buildPageHeadTitle(controller.title)
      ),
    );
  }
}
