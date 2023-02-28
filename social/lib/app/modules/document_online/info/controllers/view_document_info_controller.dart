import 'package:get/get.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';

import '../../document_api.dart';

class ViewDocumentInfoController extends GetxController {
  DocInfoItem docInfoItem;
  LoadingStatus loadingStatus;

  @override
  void onInit() {
    super.onInit();
    onLoading();
  }

  void onLoading() {
    final String fileId = Get.arguments;
    _reqData(fileId);
  }

  Future<void> _reqData(String fileId) async {
    loadingStatus = LoadingStatus.loading;
    final DocInfoItem res =
        await DocumentApi.docInfo(fileId, checkPermission: true);
    if (res != null) {
      docInfoItem = res;
      loadingStatus = LoadingStatus.complete;
      update();
      return;
    }

    loadingStatus = LoadingStatus.error;
    update();
  }
}
