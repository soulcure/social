import 'dlog_base_model.dart';

class DLogUserLoginModel extends DLogBaseModel {
  String loginLogType;
  String guildId = '';
  String guildSessionId = '';
  Map extJson;

  DLogUserLoginModel() {
    logType = 'dlog_app_login_fb';
    extJson = {};
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    final superMap = super.toJson();
    data.addAll(superMap);
    data['login_log_type'] = loginLogType ?? '';
    data['guild_id'] = guildId ?? '';
    data['guild_session_id'] = guildSessionId ?? '';
    data['ext_json'] = extJson ?? {};
    return data;
  }
}
