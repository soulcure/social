import 'dlog_base_model.dart';

class DLogUserLogoutModel extends DLogBaseModel {
  String logoutLogType;
  String guildId = '';
  String guildSessionId = '';
  int onlineDuration = 0;
  Map extJson;

  DLogUserLogoutModel() {
    logType = 'dlog_app_logout_fb';
    extJson = {};
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    final superMap = super.toJson();
    data.addAll(superMap);
    data['guild_id'] = guildId ?? '';
    data['guild_session_id'] = guildSessionId ?? '';
    data['online_duration'] = onlineDuration ?? '';
    data['logout_log_type'] = logoutLogType ?? '';
    data['ext_json'] = extJson ?? '';
    return data;
  }
}
