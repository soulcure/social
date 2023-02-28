/// 此类是用来控制入门仪式任务提交http任务 及 ws 执行顺序不确定导致的缺陷
/// 通常ws比http请求响应要快
class TaskWsUtil {
  /// 是否在入门仪式任务界面 (此状态必须维护好)
  static bool isOnTaskPage = false;

  /// 用来存储ws消息用户状态发生变化的信息
  static Map onUserNoticeData = {};

  /// 重置ws任务信息
  static void resetTaskWsState() {
    TaskWsUtil.isOnTaskPage = false;
    TaskWsUtil.onUserNoticeData = {};
  }
}
