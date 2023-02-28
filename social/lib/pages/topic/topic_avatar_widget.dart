import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/topic_avatar.dart';
import 'package:im/api/topic_avatar_api.dart';
import 'package:im/db/topic_db.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/guild_topic_model.dart';
import 'package:im/widgets/avatar.dart';

class TopicAvatarWidget extends StatefulWidget {
  final MessageEntity message;

  const TopicAvatarWidget({Key key, this.message}) : super(key: key);

  @override
  _TopicAvatarWidgetState createState() => _TopicAvatarWidgetState();
}

class _TopicAvatarWidgetState extends State<TopicAvatarWidget> {
  TopicAvatar _topicAvatar;
  final CancelToken _token = CancelToken();
  bool isRefreshing = true;
  int _showNum = 0;
  Timer _timer;
  bool isCountingDown = false;

  @override
  void initState() {
    _timer = Timer.periodic(const Duration(seconds: 3), _timeToRefresh);
    final mes = widget.message;
    if (mes.channelId != null || _avatarMapCache[mes.messageId] != null)
      _refreshAvatar(mes).then((value) {
        isRefreshing = false;
        _refresh();
      });
    _topicAvatar ??= _avatarMapCache[mes.messageId];
    super.initState();
  }

  Future<void> _refreshAvatar(MessageEntity mes) async {
    if (_avatarMapCache[mes.messageId] != null) {
      _topicAvatar ??= _avatarMapCache[mes.messageId];
    }
    final tempAvatar = await TopicAvatarApi.getAvatarData(
        mes.messageId, mes.channelId,
        token: _token);
    if (tempAvatar == null) return;
    if (tempAvatar.users?.isEmpty ?? true) {
      final firstChild = await TopicTable.getFirstTopicChild(mes.messageId);
      if (firstChild != null)
        tempAvatar.users.add(int.parse(firstChild.userId));
    }
    _topicAvatar = tempAvatar;
    _avatarMapCache[mes.messageId] = _topicAvatar;
    if (_showNum == 0) _showNum = await getMesCount(mes) ?? 0;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future _timeToRefresh(Timer timer) async {
    _timer = timer;
    if (isCountingDown) return;
    isCountingDown = true;
    final mes = widget.message;
    if (mes == null) {
      isCountingDown = false;
      return;
    }
    final count = await getMesCount(widget.message);
    if (count > _showNum) {
      _showNum = count;
      _refresh();
    }
    isCountingDown = false;
  }

  @override
  void didUpdateWidget(TopicAvatarWidget oldWidget) {
    final om = oldWidget.message;
    final m = widget.message;
    final usersNeedRefresh = _topicAvatar?.users?.isNotEmpty ?? false;
    final needRefresh = mesIdReplyNum[widget.message.messageId] == null ||
        om.messageId != m.messageId ||
        !usersNeedRefresh;
    if (needRefresh) {
      isRefreshing = true;
      _refresh();
      _refreshAvatar(widget.message).then((value) {
        isRefreshing = false;
        _refresh();
      });
    }
    getMesCount(widget.message).then((value) {
      if (value == null) return;
      _showNum = value;
      _refresh();
    });
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final users = _topicAvatar?.users ?? [];
    final userIds = users.length > 1 ? users.sublist(0, 1) : users;

    return Container(
      height: 40,
      margin: const EdgeInsets.only(right: 4),
      child: Stack(children: [
        ...List.generate(userIds.length, (index) {
          final id = userIds[index].toString();
          return Container(
              margin: EdgeInsets.only(left: index * 16.0),
              alignment: Alignment.center,
              child: UserInfo.consume(id, builder: (ctx, info, child) {
                if (isRefreshing)
                  return Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFf0f1f2),
                      shape: BoxShape.circle,
                    ),
                    width: 17,
                    height: 17,
                  );
                return Avatar(
                  url: info.avatar,
                  radius: 8.5,
                );
              }));
        }),
        if (_showNum <= 1)
          const SizedBox()
        else
          Center(
            child: Container(
              margin: EdgeInsets.only(left: userIds.length * 14.0),
              padding: const EdgeInsets.only(left: 5, right: 5),
              height: 20,
              decoration: BoxDecoration(
                  color: const Color(0xffB6B9BF),
                  border: Border.all(color: Colors.white, width: 1.5),
                  borderRadius: const BorderRadius.all(Radius.circular(17))),
              child: Center(
                child: Text(
                  '+${_showNum - 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  @override
  void dispose() {
    _token.cancel();
    _timer.cancel();
    super.dispose();
  }
}

///key为messageId
Map<String, TopicAvatar> _avatarMapCache = {};
