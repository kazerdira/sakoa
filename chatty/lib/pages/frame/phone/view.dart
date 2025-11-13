import 'package:sakoa/common/routes/names.dart';
import 'package:sakoa/common/values/values.dart';
import 'package:sakoa/common/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'index.dart';

class PhonePage extends GetView<PhoneController> {
  AppBar _buildAppBar() {
    return AppBar();
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 0.h, bottom: 30.h),
          child: Text(
            "Sakoa",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 28.sp,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 0.h, bottom: 30.h),
          child: Text(
            "Sign in with phone number",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.normal,
              fontSize: 16.sp,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildPhoneBtn() {
    return GestureDetector(
        child: Container(
          width: 295.w,
          height: 44.h,
          margin: EdgeInsets.only(top: 60.h, bottom: 30.h),
          padding: EdgeInsets.all(10.h),
          decoration: BoxDecoration(
            color: AppColors.primaryElement,
            borderRadius: BorderRadius.all(Radius.circular(5)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 2,
                offset: Offset(0, 1), // changes position of shadow
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                child: Text(
                  "Sign in",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primaryElementText,
                    fontWeight: FontWeight.normal,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          controller.handlePhone();
          //
        });
  }

  Widget _buildPhoneInput(BuildContext context) {
    return Container(
        width: 295.w,
        height: 44.h,
        margin: EdgeInsets.only(bottom: 20.h, top: 0.h),
        padding: EdgeInsets.all(0.h),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.all(Radius.circular(5)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 1), // changes position of shadow
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              child: Container(
                width: 60.w,
                height: 25.h,
                decoration: BoxDecoration(
                    border: Border(
                  right: BorderSide(
                      width: 2.w, color: AppColors.primarySecondaryBackground),
                )),
                child: Text(
                  "${controller.state.choose_index_flag.value}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
              onTap: () {
                ChooseCountry();
              },
            ),
            Container(
                width: 233.w,
                height: 44.h,
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: controller.PhoneEditingController,
                  onChanged: (value) {
                    controller.state.phone_number.value = value;
                  },
                  decoration: InputDecoration(
                    hintText: "Enter your phone number",
                    contentPadding: EdgeInsets.fromLTRB(15, 0, 15, 0),
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
                      color: AppColors.primarySecondaryElementText,
                    ),
                    prefixIcon: GestureDetector(
                      onTap: () {},
                      child: Container(
                        margin:
                            EdgeInsets.only(top: 12.h, left: 15.w, right: 5.w),
                        child: Text(
                          "${controller.state.choose_index_dialCode.value}",
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.normal,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.normal,
                    fontSize: 14.sp,
                  ),
                  maxLines: 1,
                  autocorrect: false,
                  // 自动纠正
                  obscureText: false, // 隐藏输入内容, 密码框
                ))
          ],
        ));
  }

  Future ChooseCountry() {
    controller.state.choose_index.value = 0;
    return Get.bottomSheet(
      Obx(() => Container(
          height: 350.h,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                  width: 360.w,
                  height: 50.h,
                  padding: EdgeInsets.only(left: 15.w, right: 15.w),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                            child: Text(
                              "Cancel",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontFamily: "Avenir",
                                fontWeight: FontWeight.normal,
                                fontSize: 15.sp,
                              ),
                            ),
                            onTap: () {
                              Get.back();
                            }),
                        GestureDetector(
                            child: Text(
                              "Confirm",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.thirdElement,
                                fontFamily: "Avenir",
                                fontWeight: FontWeight.normal,
                                fontSize: 15.sp,
                              ),
                            ),
                            onTap: () {
                              controller.saveAddress();
                            })
                      ])),
              Container(
                width: 360.w,
                height: 300.h,
                child: CupertinoPicker.builder(
                  backgroundColor: Colors.white,
                  itemExtent: 50.h,
                  magnification: 1.1,
                  diameterRatio: 1.0,
                  selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                      background: Color.fromRGBO(200, 200, 200, 0.1)),
                  scrollController: controller.fixedExtentScrollController,
                  useMagnifier: true,
                  childCount: controller.state.CountryList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      height: 27.h,
                      child: Text(
                        "${controller.state.CountryList.elementAt(index).dialCode} ${controller.state.CountryList.elementAt(index).flag} ${controller.state.CountryList.elementAt(index).name}",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontFamily: "Avenir",
                          fontWeight: FontWeight.normal,
                          fontSize: 20.sp,
                        ),
                      ),
                    );
                  },
                  onSelectedItemChanged: (value) {
                    print(value);
                    controller.state.choose_index.value = value;
                  },
                ),
              ),
            ],
          ))),
      barrierColor: Color.fromRGBO(0, 0, 0, 0.6),
      isDismissible: true,
      enableDrag: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.white,
      body: Obx(() {
        return CustomScrollView(slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              vertical: 15.w,
              horizontal: 15.w,
            ),
            sliver: SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.only(bottom: 0.h, top: 0.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLogo(),
                    _buildPhoneInput(context),
                    _buildPhoneBtn(),
                  ],
                ),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}
