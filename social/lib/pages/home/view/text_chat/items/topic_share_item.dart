import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/text_chat_api.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_mixin.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/widgets/realtime_user_info.dart';

import '../../../../../routes.dart';
import '../text_chat_ui_creator.dart';

class TopicShareItem extends StatefulWidget {
  final MessageEntity message;
  final String quoteL1;

  const TopicShareItem({
    Key key,
    this.message,
    this.quoteL1,
  }) : super(key: key);

  @override
  _TopicShareItemState createState() => _TopicShareItemState();
}

class _TopicShareItemState extends State<TopicShareItem> {
  MessageEntity _topicMes;
  _PermissionModel _permissionModel;
  bool canReadHistory = true;
  bool isChannelDelete = false;

  @override
  void initState() {
    buildMes();
    TextChannelUtil.instance.stream.listen((e) {
      if (e is RecallMessageEvent || e is DeleteMessageEvent) {
        if (e?.id == _topicMes?.messageId) buildMes();
      }
      if (e is UpdateTopicMessageEvent) {
        if (e?.message?.messageId == widget?.message?.messageId) buildMes();
      }
    });
    super.initState();
  }

  void buildMes() {
    final entity = widget.message.content as TopicShareEntity;
    final chartTargetModel = ChatTargetsModel.instance;
    final guildId = widget.message.guildId;
    addChannelRemoveListener();
    isChannelDelete = chartTargetModel.getChannel(entity.channelId) == null;
    _permissionModel ??=
        _PermissionModel(widget.message.guildId, permissionChange: () async {
      final canShowMes = canReadMes(guildId, entity.channelId);
      canReadHistory = canShowMes;
      print('频道权限发生改变:$canShowMes');
      if (canShowMes && _topicMes == null)
        _topicMes = await getTopicChildMessage(widget.message);
      _refresh();
    });
    final memMes = InMemoryDb.getMessage(
            entity.channelId, BigInt.parse(entity.messageId)) ??
        _getFromCachedMap(widget.message);
    if (memMes != null) {
      _topicMes = copyMessage(memMes);
      _topicMes?.shareParentId = widget.message.messageId;
    }
    getTopicChildMessage(widget.message).then((value) {
      if (value == null) {
        final canShowMes = canReadMes(guildId, entity.channelId);
        if (canReadHistory != canShowMes) {
          canReadHistory = canShowMes;
          _refresh();
        }
        return;
      }
      final copyMes = copyMessage(value);
      if (_topicMes == null) {
        _topicMes = copyMes;
        _topicMes.shareParentId = widget.message.messageId;
        _refresh();
      }
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  MessageEntity<MessageContentEntity> copyMessage(
      MessageEntity<MessageContentEntity> value) {
    final copyMes = MessageEntity(
      value.action,
      value.channelId,
      value.userId,
      value.guildId,
      value.time,
      value.content,
      recall: value.recall,
      pin: value.pin,
      quoteL1: value.quoteL1,
      quoteL2: value.quoteL2,
      quoteTotal: value.quoteTotal,
      messageId: value.messageId,
      seq: value.seq,
      deleted: value.deleted,
      status: value.status,
      type: value.type,
      channelType: value.channelType,
      replyMarkup: value.replyMarkup,
    );
    return copyMes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRecalled = _topicMes?.isRecalled ?? false;
    final content = widget.message.content as TopicShareEntity;
    final userId = content.userId ?? _topicMes?.userId;

    final guildId = _topicMes?.guildId ?? widget.message.guildId;
    final channelId = _topicMes?.channelId ?? content.channelId;
    final hasPermission = PermissionUtils.isChannelVisible(
        PermissionModel.getPermission(guildId), channelId);
    final canShowItem = _topicMes != null &&
        canReadHistory &&
        !isChannelDelete &&
        hasPermission;

    return GestureDetector(
      onTap: () async {
        if (_topicMes == null || isChannelDelete) return;
        if (guildId == null || channelId == null) return;
        if (_topicMes == null) return;
        if (!hasPermission) return;
        await Routes.pushTopicPage(context, _topicMes, isTopicShare: true);
      },
      child: AbsorbPointer(
        absorbing: !isRecalled,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            color: CustomColor(context).globalBackgroundColor3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 2,
                          height: 20,
                          decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(1))),
                        ),
                        const SizedBox(width: 6),
                        if (userId != null)
                          UserInfo.consume(userId,
                              builder: (ctx, userInfo, child) {
                            return Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RealtimeAvatar(
                                    userId: userInfo.userId,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: RealtimeNickname(
                                      userId: userId,
                                      showNameRule: ShowNameRule.remarkAndGuild,
                                      breakWord: true,
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              theme.textTheme.bodyText2.color),
                                    ),
                                  ),
                                  Text(
                                    '发起的话题'.tr,
                                    maxLines: 1,
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.bodyText2.color),
                                  ),
                                ],
                              ),
                            );
                          })
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 0.5,
                      alignment: Alignment.center,
                      color: const Color(0xff737780).withOpacity(0.2),
                    ),
                    const SizedBox(height: 12),
                    if (hasPermission && !canReadHistory && !isChannelDelete)
                      Text('╮(╯▽╰)╭当前暂无查看该话题所在频道的历史消息的权限'.tr),
                    if (isChannelDelete) Text('╮(╯▽╰)╭话题所在频道已被删除'.tr),
                    if (!hasPermission && !isChannelDelete) Text('该消息无权限查看'.tr),
                  ],
                ),
              ),
              if (canShowItem)
                TextChatUICreator.createItem(
                  context,
                  0,
                  UnmodifiableListView([_topicMes]),
                  guidId: ChatTargetsModel.instance.selectedChatTarget.id,
                  shouldShowUserInfo: false,
                  isFromShareTopic: true,
                  onUnFold: (data) => {},
                  isUnFold: (data) => true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _permissionModel?.disposePermissionListener();
    super.dispose();
  }

  void addChannelRemoveListener() {
    TextChannelUtil.instance.stream.listen((value) {
      if (value is ChannelRemoveEvent) {
        if (_topicMes != null && _topicMes.channelId == value.channelId) {
          isChannelDelete = true;
          _refresh();
        }
      }
    });
  }
}

class _PermissionModel with GuildPermissionListener {
  final String mesId;
  final VoidCallback permissionChange;

  _PermissionModel(this.mesId, {this.permissionChange}) {
    addPermissionListener();
  }

  @override
  String get guildPermissionMixinId => mesId;

  @override
  void onPermissionChange() {
    permissionChange?.call();
  }
}

///对从网络获取的进行缓存, key 为 messageId
Map<String, MessageEntity> _cacheMap = {};

Future<MessageEntity> getTopicChildMessage(MessageEntity message) async {
  MessageEntity childMes;

  ///第一步，从内存中读取
  final entity = message.content as TopicShareEntity;

  childMes =
      InMemoryDb.getMessage(entity.channelId, BigInt.parse(entity.messageId));
  if (childMes != null) return childMes;

  ///第二步，如果从内存中找不到则从数据库拿
  childMes = await ChatTable.getDisplayableMessage(entity.messageId);
  if (childMes != null) {
    _putMessageToMap(childMes, entity.messageId);
    return childMes;
  }

  ///第三步，如果从数据库找不到，则从服务器拿,此时还需进行权限判断

  final canShowMes = canReadMes(message.guildId, entity.channelId);
  if (!canShowMes) return null;
  childMes = _getFromCachedMap(message) ??
      await TextChatApi.getMessage(entity.channelId, entity.messageId);
  if (childMes != null) _putMessageToMap(childMes, entity.messageId);
  return childMes;
}

MessageEntity _getFromCachedMap(MessageEntity message) {
  final entity = message.content as TopicShareEntity;
  return _cacheMap[entity?.messageId ?? ''];
}

void _putMessageToMap(MessageEntity message, String id) {
  _cacheMap[id] = message;
}

bool canReadMes(String guildId, String channelId) {
  ///如果没有查看此消息的权限
  final canReadMes = PermissionUtils.oneOf(
      PermissionModel.getPermission(guildId), [Permission.READ_MESSAGE_HISTORY],
      channelId: channelId);
  return canReadMes;
}

void updateWhenRemoveChannel(ChatChannel channel) {
  TextChannelUtil.instance.stream.add(ChannelRemoveEvent(channel.id));
}

class ChannelRemoveEvent {
  String channelId;

  ChannelRemoveEvent(this.channelId);
}
