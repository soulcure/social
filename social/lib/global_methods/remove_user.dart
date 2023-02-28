// import 'package:get/get.dart';
// import 'package:im/api/data_model/user_info.dart';
// import 'package:im/api/guild_api.dart';
// import 'package:im/pages/bot_market/model/channel_cmds_model.dart';
// import 'package:im/pages/bot_market/model/robot_model.dart';
// import 'package:im/pages/home/model/chat_index_model.dart';
// import 'package:im/pages/member_list/model/member_list_model.dart';
// import 'package:im/utils/show_confirm_dialog.dart';
//
// import '../global.dart';
//
// Future<void> removeUserFromGuild(UserInfo user) {
//   return _remove(user,
//       ban: false,
//       message: '确定移出服务器成员 ${user.showName()} ？移出后，该成员可以通过新的邀请链接再加入。');
// }
//
// Future<void> banUserFromGuild(UserInfo user) {
//   return _remove(user, ban: true, message: "加入黑名单后，用户将被移出服务器且无法再次加入".tr);
// }
//
// Future<void> _remove(
//   UserInfo user, {
//   bool ban,
//   String message,
// }) async {
//   final res = await showConfirmDialog(
//     title: '移出成员'.tr,
//     content: message,
//   );
//   if (res != true) return;
//   if (user.isBot) {
//     // 移除该机器人下的快捷指令
//     await ChannelCmdsModel.instance.removeAllChannelCmds(
//       robotId: user.userId,
//     );
//   }
//   final guildId = ChatTargetsModel.instance.selectedChatTarget.id;
//   await GuildApi.removeUser(
//     guildId: guildId,
//     userId: Global.user.id,
//     userName: user.showName(),
//     memberId: user.userId,
//     showDefaultErrorToast: false,
//     isOriginDataReturn: true,
//     ban: ban,
//   );
//
//   await MemberListModel.instance.remove(user.userId);
//   if (user.isBot)
//     await RobotModel.instance.removeGuildRobot(guildId, user.userId);
//   Get.back();
// }
