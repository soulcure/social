import 'package:get/get.dart';
import 'package:im/app/modules/wallet/controllers/wallet_verified_controller.dart';

class WalletVerifiedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WalletVerifiedController>(
      () => WalletVerifiedController(),
    );
  }
}
