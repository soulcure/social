import 'package:im/dlog/model/dlog_base_model.dart';

class DLogCustomEventModel extends DLogBaseModel {
  String actionEventId;
  String actionEventSubId;
  String actionEventSubParam;
  String pageId;
  Map extJson;

  DLogCustomEventModel() {
    logType = 'dlog_app_action_event_fb';
    extJson = {};
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    final superMap = super.toJson();
    data.addAll(superMap);
    data['action_event_id'] = actionEventId ?? '';
    data['action_event_sub_id'] = actionEventSubId ?? '';
    data['action_event_sub_param'] = actionEventSubParam ?? '';
    data['page_id'] = pageId ?? '';
    // 移除map为null的字段
    extJson.removeWhere((key, value) => value == null);
    data['ext_json'] = extJson ?? {};
    return data;
  }
}
