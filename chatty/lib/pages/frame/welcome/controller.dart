import 'package:sakoa/common/routes/routes.dart';
import 'package:sakoa/common/store/store.dart';
import 'package:get/get.dart';

import 'index.dart';

class WelcomeController extends GetxController {
  final state = WelcomeState();
  WelcomeController();
  final title = "Sakoa";

  @override
  void onReady() {
    super.onReady();
    Future.delayed(
        Duration(seconds: 3), () => Get.offAllNamed(AppRoutes.Message));
  }
}
