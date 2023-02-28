import 'package:im/dlog/model/dlog_base_model.dart';

class DLogExtensionEventModel extends DLogBaseModel {
  Map extJson;

  DLogExtensionEventModel() {
    logType = '';
    extJson = {};
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    final superMap = super.toJson();
    data.addAll(superMap);
    // 移除map为null的字段
    extJson.removeWhere((key, value) => value == null);
    data['ext_map'] = extJson ?? {};
    return data;
  }
}
