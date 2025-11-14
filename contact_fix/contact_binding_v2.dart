import 'package:get/get.dart';
import 'contact_controller_v2.dart';
import 'contact_repository.dart';

/// 🚀 SUPERNOVA-LEVEL CONTACT BINDING
class ContactBindingV2 implements Bindings {
  @override
  void dependencies() {
    // Initialize repository first
    Get.lazyPut<ContactRepository>(() => ContactRepository(), fenix: true);
    
    // Then initialize controller
    Get.lazyPut<ContactControllerV2>(() => ContactControllerV2());
  }
}
