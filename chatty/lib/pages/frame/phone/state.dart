import 'package:sakoa/common/entities/entities.dart';
import 'package:get/get.dart';

class PhoneState {
  RxString username = "".obs;
  RxString email = "".obs;
  RxString password = "".obs;
  RxString verifycode = "".obs;
  var choose_index = 0.obs;
  var choose_index_flag = "🇦🇫".obs;
  var choose_index_dialCode = "+93".obs;
  var phone_number = "".obs;
  RxList<Country> CountryList = RxList<Country>();
}
