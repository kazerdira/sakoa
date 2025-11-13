import 'package:intl/intl.dart';
import 'package:sakoa/common/values/colors.dart';
import 'package:sakoa/common/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'controller.dart';
import 'package:photo_view/photo_view.dart';

class PhotoImgViewPage extends GetView<PhotoImgViewController> {

  AppBar _buildAppBar() {
    return AppBar(
        bottom: PreferredSize(
            child: Container(
              color: AppColors.secondaryElement,
              height: 2.0,
            ),
            preferredSize: Size.fromHeight(1.0)),
        title: Text(
          "PhotoView",
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 16.sp,
            fontWeight: FontWeight.normal,
          ),
        ));
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.white,
      body: Container(
          child: PhotoView(
            imageProvider: NetworkImage(controller.state.url.value),
          )
      ),
    );
  }
}
