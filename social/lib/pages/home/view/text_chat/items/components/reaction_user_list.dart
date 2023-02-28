import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/user_api.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/text_chat/items/components/reaction_detail.dart';
import 'package:im/pages/home/view/text_chat/items/components/reaction_detail_api.dart';
import 'package:im/pages/topic/controllers/topic_controller.dart';
import 'package:im/themes/const.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/user_info/popup/user_info_popup.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rxdart/rxdart.dart';

class ReactionUserList extends StatefulWidget {
  const ReactionUserList(this.channelId, this.messageId, this.emojiName,
      this.sum, this.me, this.subject,
      {Key key, this.isCircleMessage = false})
      : super(key: key);

  final String channelId;
  final String messageId;
  final String emojiName;
  final int sum;
  final bool me;
  final PublishSubject subject;

  /// * 是否圈子回复消息
  final bool isCircleMessage;

  @override
  _ReactionUserListState createState() => _ReactionUserListState();
}

class _ReactionUserListState extends State<ReactionUserList> {
  final List<String> users = [];

  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    reqReactionUserImage();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _body(),
    );
  }

  Widget _body() {
    if (users.isEmpty) {
      return _initStatus();
    }
    return _buildList(users);
  }

  /// 加载中
  Widget _initStatus() => Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: appThemeData.disabledColor.withOpacity(0.2),
            backgroundColor: Colors.white,
            strokeWidth: 1.5,
          ),
        ),
      );

  void checkReactionCount(int count) {
    if (!mounted) return;

    if (users.isEmpty) {
      ///此case在测试异常测试中出现，在计数错误错误的情况下，正常情况不会出现
      ///本地有表态数据，实际服务器查询没有，故本地计数出现了错误，移除本地的错误表态，关闭关闭详情页
      widget.subject.add(ReactionCountChange(widget.emojiName, 0, false));
      showToast("未查询到表态信息".tr);
      Get.back();
    } else {
      final bool me = users.contains(Global.user.id);
      if (count != widget.sum || me != widget.me) {
        widget.subject.add(ReactionCountChange(widget.emojiName, count, me));
      }
    }
  }

  Future<void> reqUserInfo(List<String> list) async {
    if (list == null || list.isEmpty) return;

    final keys = Db.userInfoBox.keys;
    if (keys != null && keys.isNotEmpty) {
      for (int i = list.length - 1; i >= 0; i--) {
        final String item = list[i];
        if (keys.contains(item)) {
          list.removeAt(i);
        }
      }
    }

    if (list.isNotEmpty) {
      final List<UserInfo> res = await UserApi.getUserInfo(list);
      if (res != null && res.isNotEmpty) {
        res.forEach((e) => Db.userInfoBox.put(e.userId, e));
      }
    }
  }

  Future<void> reqReactionUserImage() async {
    ReactionData reactionData;
    if (!widget.isCircleMessage) {
      reactionData = await ReactionDetailApi.getReactionDetailSingle(
          widget.messageId, widget.channelId, widget.emojiName,
          size: TopicController.LOAD_SIZE.toString());
    } else {
      reactionData = await ReactionDetailApi.getCircleReactionDetailSingle(
          widget.messageId, widget.emojiName);
    }

    final list = reactionData?.lists;
    final count = reactionData?.count ?? 0;

    if (list != null && list.isNotEmpty) {
      final int length = list.length;
      users.addAll(list);
      await reqUserInfo(list);
      if (mounted) setState(() {});
      if (length == TopicController.LOAD_SIZE) {
        _refreshController.loadComplete();
      } else {
        _refreshController.loadNoData();
        checkReactionCount(count);
      }
    } else if (list != null && list.isEmpty) {
      ///没有表态的情况
      if (mounted) setState(() {});
      _refreshController.loadNoData();
      checkReactionCount(count);
    }
  }

  Future<void> _onLoading() async {
    ReactionData reactionData;
    if (!widget.isCircleMessage) {
      reactionData = await ReactionDetailApi.getReactionDetailSingle(
          widget.messageId, widget.channelId, widget.emojiName,
          size: TopicController.LOAD_SIZE.toString(), after: users.last);
    } else {
      reactionData = await ReactionDetailApi.getCircleReactionDetailSingle(
          widget.messageId, widget.emojiName,
          listId: users.last);
    }

    final list = reactionData?.lists;
    final count = reactionData?.count ?? 0;

    if (list != null) {
      if (list.isNotEmpty) {
        final int length = list.length;
        users.addAll(list);
        await reqUserInfo(list);
        if (mounted) setState(() {});
        if (length == TopicController.LOAD_SIZE) {
          _refreshController.loadComplete();
        } else {
          _refreshController.loadNoData();
          checkReactionCount(count);
        }
      } else {
        _refreshController.loadNoData();
        checkReactionCount(count);
      }
    }
  }

  Widget _buildList(List<String> users) {
    return SmartRefresher(
      enablePullDown: false,
      enablePullUp: true,
      controller: _refreshController,
      onLoading: _onLoading,
      footer: CustomFooter(
        height: 20,
        builder: (context, mode) {
          if (mode == LoadStatus.idle) {
            return sizedBox;
          } else if (mode == LoadStatus.loading) {
            return const CupertinoActivityIndicator.partiallyRevealed(
                radius: 8);
          } else if (mode == LoadStatus.failed) {
            return const Icon(Icons.error, size: 20, color: Colors.grey);
          } else if (mode == LoadStatus.canLoading) {
            return sizedBox;
          } else {
            return sizedBox;
          }
        },
      ),
      child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return _item(users[index]);
          },
          itemCount: users.length),
    );
  }

  Widget _item(String userId) {
    return FadeBackgroundButton(
      tapDownBackgroundColor:
          Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
      onTap: () {
        showUserInfoPopUp(
          context,
          userId: userId,
          guildId: ChatTargetsModel.instance.selectedChatTarget.id,
          showRemoveFromGuild: true,
          enterType:
              GlobalState.selectedChannel.value?.type == ChatChannelType.dm
                  ? EnterType.fromDefault
                  : EnterType.fromServer,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          children: <Widget>[
            RealtimeAvatar(userId: userId, size: 32),
            sizeWidth16,
            Expanded(
                child: RealtimeNickname(
              userId: userId,
              showNameRule: ShowNameRule.remarkAndGuild,
            ))
          ],
        ),
      ),
    );
  }
}
