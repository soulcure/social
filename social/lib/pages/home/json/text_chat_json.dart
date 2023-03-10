import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:filesize/filesize.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/api/entity/reply_markup.dart';
import 'package:im/api/entity/role_bean.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/modules/document_online/info/controllers/doc_link_preview_controller.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/cicle_news_table.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/json/add_friend_tips_entity.dart';
import 'package:im/pages/home/json/document_entity.dart';
import 'package:im/pages/home/json/file_entity.dart';
import 'package:im/pages/home/json/message_card_entity.dart';
import 'package:im/pages/home/json/redpack_entity.dart';
import 'package:im/pages/home/json/task_entity.dart';
import 'package:im/pages/home/json/unsupported_entity.dart';
import 'package:im/pages/home/json/vote_entity.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/in_memory_db.dart';
import 'package:im/pages/home/model/reaction_model.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/view/text_chat/items/components/message_reaction.dart';
import 'package:im/pages/home/view/text_chat/items/recalled_item.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/pages/tool/url_handler/invite_link_handler.dart';
import 'package:im/pages/topic/controllers/topic_controller.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/emo_util.dart';
import 'package:im/utils/message_util.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:im/utils/utils.dart';
import 'package:im/web/widgets/send_image/send_image_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:tuple/tuple.dart';

import '../../../utils/content_checker.dart';
import '../../../utils/cos_file_upload.dart';
import 'du_entity.dart';

part 'text_chat_json.g.dart';

class MessageAction {
  static const connect = "connect";
  static const send = "send";
  static const message = "message";
  static const joinNotice = "joinNotice";
  static const push = "push";
  static const pong = "pong";
  static const text = "text";
  static const channelStatus = "channelStatus";
  static const channelNotice = "channelNotice";
  static const circleStatus = "CircleStatus";
  static const userNotice = "userNotice";
  static const callNotice = "callNotice";
  static const relation = "relation";
  static const circle = "circle";

  /// ?????????????????????
  static const handleNonEntity = "push_non_entity";

  ///????????????-????????????
  static const circlePush = "circle_push";

  ///??????????????????
  static const circleEnter = "circleEnter";

  ///????????????-????????????
  static const circlePost = "circle_post";

  static const notPull = "notPull";
  static const stick = "top";
  static const unStick = "untop";
  static const userBan = "userBan";

  static const upLastRead = "upLastRead";
  static const getReadList = "getReadList";
  static const onlineDevice = "onlineDevice";
  static const syncRead = "syncRead";

  static const getTaskList = "getTaskList";
  static const mChannel = "mChannel";
  static const taskNote = "taskNote";
  static const taskDone = "taskDone";

  static const userQuit = "userQuit";
  static const userRem = "userRem";
  static const userJoin = "userJoin";
  static const joinSet = "joinSet";
  static const upEmoji = "upEmoji";
  static const update = "update";

  /// ??????????????????
  /// ?????????????????????1.6.60 ??????????????? botSetting????????????????????? botSetting_list
  static const botSetting = "botSetting_list";

  /// ?????????????????????
  static const memberList = "memberList";

  ///????????????action
  static const livePush = "livePush";
  static const liveJoin = "liveJoin";
  static const liveQuit = "liveQuit";
  static const liveDisband = "liveDisband";

  static const kickOutOfGuild = "kickOutOfGuild";

  static const circleCoverStatus = "CircleCoverStatus";

//  static const recall = "recall";
//  static const reactionAdd = "reactionAdd";
//  static const reactionDel = "reactionDel";
  static const roleDel = "roleDel";
  static const roleAdd = "roleAdd";
  static const roleUp = "roleUp";
  static const rolesUpdate = "role";
  static const userRolesUpdate = "userRole";
  static const guildNotice = "guildNotice";
  static const userSetting = "userSetting";
  static const blackAdd = "blackAdd";
  static const blackDel = "blackDel";
  static const voiceStateUpdate = "voiceStateUpdate";
  static const liveStatusUpdate = "liveOnline";

  /// ???????????? ???????????????
  static const overwriteUpdate = "cpermissUp";
  static const overwriteDel = "cpermissDel";
  static const pin = "pinned";

  /// ?????? ???????????? ???????????????
  static const overwriteCircleUpdate = "circlepermissUp";

  ///content message type
  static const task = "task";

  ///????????????
  static const miniPush = "miniPush";
  static const vote = "vote";
  static const du = "du";

  /// ??????
  static const file = "file";

  /// ??????
  static const mute = "Forbid";

  ///???????????????
  //static const redPack = "redPack";
  static const redPack1 = "sendRedBag1";
  static const redPack2 = "sendRedBag2";

  ///??????????????????fanbook???????????????
  static const unbind = "unbind";

  ///??????????????????
  static const friend = "friend";

  static const GuildStatus = "GuildStatus";

  ///??????????????????????????????
  static const tcDocViewUp = "view_up";

  ///?????????????????????????????????
  static const tcDocGroupUp = "group_up";

  ///????????????
  static const doc = "doc";
}

class MessageStatusCode {
  ///????????????
  static const success = 0;

  ///????????????
  static const fail = -1;

  ///????????????
  static const timeout = -2;
}

enum MessageType {
  unSupport,
  start,
  text,
  image,
  video,
  voice,
  newJoin,
  call,
  del,
  richText,
  empty,
  upMsg,
  recall,
  topicShare,
  stickerEntity,
  circleShareEntity,
  pinned,
  reaction,
  goodsShareEntity,
  externalShareEntity,
  task,
  vote,
  du,
  circle,
  file,
  messageCard,
  messageCardKey,
  redPack,
  friend,
  document,
}

enum MessageLocalStatus {
  normal,
  local, // ????????????????????????
  quote,
  sticky, // ????????????
  illegal, // ???????????????
  incomplete, //??????????????????: ?????????ID,?????????
  temporary, //????????????
}

DateTime _timeFromJson(Map<String, dynamic> srcJson) {
  final time = srcJson['time'];
  if (srcJson['time'] is int && time > 0) {
    return DateTime.fromMillisecondsSinceEpoch(time);
  } else {
    ///?????????????????????????????????messageId????????????????????????
    return msgIdStr2DateTime(srcJson['message_id'].toString());
  }
}

///???messageId??????????????????unix ?????????
DateTime msgIdStr2DateTime(String msgIdStr) {
  assert(msgIdStr.hasValue);
  final BigInt msgId = BigInt.parse(msgIdStr);
  return msgId2DateTime(msgId);
}

///?????????id??????????????????unix ?????????
DateTime msgId2DateTime(BigInt msgId) {
  final BigInt msgTime = (msgId >> 22) + BigInt.from(1565222888000);
  return DateTime.fromMillisecondsSinceEpoch(msgTime.toInt());
}

int _timeToJson(DateTime time) =>
    time == null ? 0 : time.millisecondsSinceEpoch;

// @JsonSerializable()
class MessageEntity<T extends MessageContentEntity> {
  static final TextEntity deleteContent = TextEntity(text: "??????????????????".tr);
  static final TextEntity nullContent = TextEntity(text: "")
    ..messageState = MessageState.sent.obs; //??????????????????

  @JsonKey(defaultValue: null)
  final String action;
  final String channelId;
  final String userId;
  final int seq;
  String messageId;
  String quoteL1;
  String quoteL2;
  int quoteTotal;
  String guildId;

  // todo ??????????????????????????????
  final ChatChannelType type;
  final ChatChannelType channelType;

  ///???????????????parendId???????????????null???????????????message?????????????????????????????????
  String shareParentId;

  @JsonKey(fromJson: _timeFromJson, toJson: _timeToJson)
  DateTime time;
  @JsonKey(
      toJson: MessageEntity._contentToJson,
      fromJson: MessageEntity.contentFromString)
  T content;

  @JsonKey(defaultValue: 0)
  int deleted;

  String recall;
  String pin;

  // 0 ?????? 1 ????????????????????? 2 ??????
  @JsonKey(defaultValue: 0)
  int status;
  MessageLocalStatus localStatus = MessageLocalStatus.normal;

  // @JsonKey(fromJson: _timeFromJson, toJson: _timeToJson)
  ReactionModel reactionModel;
  ReplyMarkup replyMarkup;

  // ????????????@?????????
  List<String> mentions;

  // ????????????@????????????
  List<String> mentionRoles;

  //?????????????????????ID:????????????????????????
  String nonce;

  ///messageId???BigInt?????????????????????
  BigInt messageIdBigInt;

  List<String> roleIds;

  // ??????????????????????????????0 ??????????????????  1 ?????????????????????
  int unreactive = 0;

  //????????????????????????
  int extra;

  //?????????????????????
  String circleContent;

  MessageEntity(
    this.action,
    this.channelId,
    this.userId,
    this.guildId,
    this.time,
    this.content, {
    this.recall,
    this.pin,
    this.quoteL1,
    this.quoteL2,
    this.quoteTotal,
    this.messageId,
    this.seq,
    this.deleted = 0,
    this.status = 0,
    this.type,
    this.channelType,
    List<dynamic> reactions,
    this.replyMarkup,
    this.nonce,
    this.localStatus,
    this.unreactive = 0,
    this.circleContent,
    String postId,
  }) {
    List<ReactionEntity> reactionList = [];
    if (reactions != null && reactions.isNotEmpty) {
      reactionList = reactions.map((e) => ReactionEntity.fromMap(e)).toList();
    }
    reactionModel = ReactionModel(
      messageId: messageId,
      channelId: channelId,
      actions: reactionList,
      guildId: guildId,
      postId: postId,
    );

    content ??= nullContent as T;
    messageIdBigInt =
        messageId.hasValue ? BigInt.parse(messageId) : BigInt.from(0);
  }

  bool get isBlocked => status != MessageStatus.normal.index;

  bool get isIllegal => localStatus == MessageLocalStatus.illegal;

  bool get isNormal => localStatus == MessageLocalStatus.normal;

  bool get canAddReaction => unreactive == 0;

  ///?????????????????????????????????ID,?????????
  bool get isIncomplete =>
      localStatus == MessageLocalStatus.incomplete ||
      content == null ||
      content == nullContent;

  ///?????????????????????????????????????????????
  bool get isTemporary => localStatus == MessageLocalStatus.temporary;

  bool get isDeleted => deleted == 1;

  bool get isRecalled => recall != null;

  bool get isContent => content != null && content != nullContent;

  /// ????????????????????????????????????????????????????????????
  /// ???????????????????????? localStatus = normal | incomplete
  bool get displayable =>
      !isDeleted &&
      (localStatus == MessageLocalStatus.incomplete ||
          localStatus == MessageLocalStatus.normal ||
          localStatus == MessageLocalStatus.illegal);

  bool get isPinned => pin != '0' && pin != '' && pin != null;

  bool get isBacked => extra != null && extra == TopicController.NEW_BACK;

  ///????????????
  bool get isDmMessage {
    return Db.channelBox.get(channelId)?.type == ChatChannelType.dm;
  }

  ///????????????
  bool get isDmGroupMessage {
    return Db.channelBox.get(channelId)?.type == ChatChannelType.group_dm;
  }

  ///????????????????????????
  bool get isCircleMessage {
    return type == ChatChannelType.guildCircle;
  }

  DateTime messageTime() {
    if (time != null && time.year > 2019) {
      return time;
    } else {
      return msgIdStr2DateTime(messageId);
    }
  }

  static String _contentToJson(MessageContentEntity content) {
    if (content == null) return "";

    return jsonEncode(content.toJson());
  }

  static MessageContentEntity contentFromString(String src) {
    if (src.noValue) return UnSupportedEntity(unSupportContent: {});
    return contentFromJson(jsonDecode(src));
  }

  static MessageContentEntity contentFromJson(Map<String, dynamic> json) {
    final type = json["type"];

    switch (type) {
      case "start":
        return StartEntity.fromJson(json);
      case "text":
        return TextEntity.fromJson(json);
      case "image":
        return ImageEntity.fromJson(json);
      case "newJoin":
        return WelcomeEntity.fromJson(json);
      case "call":
        return CallEntity.fromJson(json);
      case "voice":
        return VoiceEntity.fromJson(json);
      case "video":
        return VideoEntity.fromJson(json);
      case "del":
        return deleteContent;
      case "recall":
        return RecallEntity.fromJson(json);
      case "upMsg":
        if (json["reply_markup"] is String) {
          json["reply_markup"] = jsonDecode(json["reply_markup"]);
        }
        return MessageModificationEntity.fromJson(json);
      case "reaction":
        return ReactionEntity2.fromJson(json);
      case "topicShare":
        return TopicShareEntity.fromJson(json);
      case "stickerEntity":
        return StickerEntity.fromJson(json);
      case "circleShareEntity":
        return CircleShareEntity.fromJson(json);
      case "goodsShareEntity":
        return GoodsShareEntity.fromJson(json);
      case "externalShareEntity":
        return ExternalShareEntity.fromJson(json);
      case "pinned":
        return PinEntity.fromJson(json);
      case "richText":
        return RichTextEntity.fromJson(json);
      case MessageAction.task:
        return TaskEntity.fromJson(json);
      case MessageAction.vote:
        return VoteEntity.fromJson(json);
      case MessageAction.du:
        return DuEntity.fromJson(json);
      case 'circle':
        return CirclePostNewsEntity.fromJson(json);
      case MessageAction.file:
        return FileEntity.fromJson(json);
      case "messageCard":
        return MessageCardEntity.fromJson(json);
      //case MessageAction.redPack:
      case MessageAction.redPack1:
      case MessageAction.redPack2:
        return RedPackEntity.fromJson(json);
      case MessageAction.friend:
        return AddFriendTipsEntity.fromJson(json);
      case MessageAction.doc:
        return DocumentEntity.fromJson(json);
      case "messageCardOperate":
        return MessageCardKeyPushEntity.fromJson(json);
      default:
        print("Unsupported message content type $type");
    }

    print("unsupported message type $type");
    return UnSupportedEntity(unSupportContent: json);
  }

  factory MessageEntity.fromJson(Map<String, dynamic> srcJson) {
    try {
      // ??????????????????????????????
      MessageContentEntity _contentEntity;
      try {
        if (srcJson['content'] == null) {
          _contentEntity = nullContent;
        } else {
          _contentEntity =
              MessageEntity.contentFromString(srcJson['content'] as String);

          if (_contentEntity is DocumentEntity) {
            _contentEntity.desc = srcJson['desc'];
          } else if (_contentEntity is MessageCardEntity &&
              srcJson["message_card"] != null) {
            _contentEntity.loadKeysFromJson(srcJson['message_card']);
          }
        }
      } catch (e) {
        _contentEntity = UnSupportedEntity(unSupportContent: {});
        logger.severe("Failed to deserialize message content", e);
      }

      _contentEntity.messageState = Rx(
          (srcJson['status'] == 0 || srcJson['status'] == null)
              ? MessageState.sent
              : MessageState.shield);
      String mId, mNonce;
      //web???????????????
      if (srcJson['message_id'] is int) {
        mId = srcJson['message_id'].toString();
      } else {
        mId = srcJson['message_id'];
      }
      if (srcJson['nonce'] != null) {
        mNonce = srcJson['nonce'].toString();
      }
      final m = MessageEntity<T>(
        srcJson['action'].toString(),
        srcJson['channel_id'].toString(),
        srcJson['user_id'].toString(),
        srcJson['guild_id']?.toString() ?? "0",
        _timeFromJson(srcJson),
        _contentEntity,
        quoteL1: srcJson['quote_l1'],
        quoteL2: srcJson['quote_l2'],
        quoteTotal: srcJson['quote_total'],
        messageId: mId,
        seq: srcJson['seq'],
        deleted: srcJson['deleted'] == null ? 0 : srcJson['deleted'] as int,
        type: chatChannelTypeFromJson(srcJson['type']),
        channelType: chatChannelTypeFromJson(srcJson['channel_type']),
        reactions: srcJson['reactions'],
        recall: srcJson['recall'],
        pin: srcJson['pin'],
        status: srcJson['status'] ?? 0,
        nonce: mNonce,
        circleContent: srcJson['circle_content'],
        unreactive: srcJson['unreactive'] ?? 0,
        replyMarkup: srcJson['reply_markup'] == null ||
                srcJson['reply_markup'] == "" ||
                srcJson['reply_markup'] == "null"
            ? null

            /// ????????????????????? json ????????????????????? json ??????????????????????????????
            : srcJson['reply_markup'] is String
                ? ReplyMarkup.fromJson(jsonDecode(srcJson['reply_markup']))
                : ReplyMarkup.fromJson(srcJson['reply_markup']),
      )..localStatus = srcJson['localStatus'] == null
          ? MessageLocalStatus.normal
          : MessageLocalStatus.values[srcJson['localStatus']];

      if (srcJson['mentions'] != null) {
        m.mentions = [];
        for (final user in srcJson['mentions']) {
          final userId = user['user_id'];

          /// ?????????????????????????????????@???????????????????????????isbot,???????????????????????????false
          /// ??????????????? isBot ?????????false,???????????????????????????????????????????????????
          // Db.userInfoBox
          //     .get(userId, defaultValue: UserInfo(userId: userId))
          //     .nickname = user['nickname'];
          m.mentions.add(userId);
        }
      }
      if (srcJson['mention_roles'] != null)
        m.mentionRoles = List.castFrom(srcJson['mention_roles']);

      ///???????????????????????????
      if (m.localStatus == MessageLocalStatus.local) {
        m.content.messageState = MessageState.timeout.obs;
      }

      ///??????????????? member ??? author?????????UserInfo
      String nick;
      if (srcJson['member'] != null) {
        final member = srcJson["member"] as Map<String, dynamic>;
        nick = member['nick'];
        m.roleIds = List.castFrom(member['roles']);
        // ???????????????????????????
        RoleBean.update(m.userId, m.guildId, m.roleIds);
      }
      if (srcJson['author'] != null) {
        final author = srcJson["author"] as Map<String, dynamic>;
        if (author != null) {
          UserInfo.updateIfChanged(
            userId: m.userId,
            nickname: author["nickname"],
            username: author["username"],
            avatar: author["avatar"],
            gNick: nick,
            guildId: srcJson['guild_id'],
            isBot: author["bot"],
            avatarNft: author["avatar_nft"] ?? '',
            avatarNftId: author["avatar_nft_id"] ?? '',
          );
        }
      }
      return m;
    } catch (e) {
      logger.severe("Failed to deserialize message", e);
      return null;
    }
  }

  ///?????????????????????map
  Map<String, dynamic> toWsJson() {
    final res = {
      'action': "send",
      'channel_id': channelId,
      'seq': seq,
      'quote_l1': quoteL1,
      'quote_l2': quoteL2,
      'guild_id': guildId,
      'content': MessageEntity._contentToJson(content),
    };

    if (content is TextEntity) {
      res['ctype'] = (content as TextEntity).contentType;
    }

    addDesc(res);

    return res;
  }

  Map<String, dynamic> toJson() {
    final res = {
      'action': action,
      'channel_id': channelId,
      'user_id': userId,
      'seq': seq,
      'message_id': messageId,
      'quote_l1': quoteL1,
      'quote_l2': quoteL2,
      'quote_total': quoteTotal,
      'recall': recall,
      'pin': pin,
      'guild_id': guildId,
      'type': chatChannelTypeToJson(type),
      'time': _timeToJson(time),
      'content':
          content == nullContent ? null : MessageEntity._contentToJson(content),
      'deleted': deleted,
      'status': status,
      if (localStatus != null) 'localStatus': localStatus.index,
      'reactions':
          (reactionModel?.reactions ?? []).map((v) => v.toJson()).toList(),
      'reply_markup': replyMarkup?.toJson(),
      'nonce': nonce,
      ChatTable.columnUnreactive: unreactive,
    };

    addDesc(res);
    return res;
  }

  ///?????????????????????
  Map<String, dynamic> toQuoteJson() {
    final res = {
      'channel_id': channelId,
      'user_id': userId,
      'message_id': messageId,
      'quote_l1': quoteL1,
      'quote_l2': quoteL2,
      'quote_total': quoteTotal,
      'recall': recall,
      'pin': pin,
      'guild_id': guildId,
      'time': _timeToJson(time),
      'content':
          content == nullContent ? null : MessageEntity._contentToJson(content),
      'deleted': deleted,
      'status': status,
      'localStatus': localStatus.index,
      'reply_markup': replyMarkup?.toJson(),
      'nonce': nonce,
    };
    return res;
  }

  ///????????????json
  Map<String, dynamic> toCircleNewsJson() {
    final entity = content as CirclePostNewsEntity;
    final circleType = CircleNewsTable.getCircleType(entity.circleType);
    var isUpdate = CircleNewsTable.isUpdateUnread(
        CircleNewsTable.getCircleType(entity.circleType));
    if (CirclePostNewsType.postDel == circleType) isUpdate = true;

    final res = {
      'message_id': messageId,
      'channel_id': channelId,
      'user_id': userId,
      'guild_id': guildId,
      'quote_l1': quoteL1.hasValue ? BigInt.parse(quoteL1).toInt() : 0,
      'post_id': entity.postId,
      'comment_id': entity.commentId.toInt(),
      'circle_type': entity.circleType,
      'at_me': entity.atMe,
      'status': isUpdate ? entity.status : 1,
    };
    // debugPrint('getChat toCircleNewsJson: - $res');
    return res;
  }

  @override
  String toString() => content.toJson().toString();

  /// - ???????????????????????????
  /// - ??????APP?????????????????????????????????????????????????????????????????????????????????????????????????????????
  /// - ?????????????????????????????????????????????
  Future<String> toNotificationString() async {
    switch (content.type) {
      case MessageType.empty:
      case MessageType.friend:
      case MessageType.circle:
      case MessageType.del:
      case MessageType.pinned:
      case MessageType.start:
      case MessageType.messageCardKey:
      case MessageType.du:
      case MessageType.upMsg:
        return "";
      case MessageType.text:
        return (content as TextEntity).toNotificationString(guildId, userId);
      case MessageType.image:
        return (content as ImageEntity).toNotificationString();
      case MessageType.video:
        return (content as VideoEntity).toNotificationString();
      case MessageType.voice:
        return (content as VoiceEntity).toNotificationString();
      case MessageType.newJoin:
        return (content as WelcomeEntity).toNotificationString(userId);
      case MessageType.call:
        return (content as CallEntity).toNotificationString();
      case MessageType.richText:
        return (content as RichTextEntity)
            .toNotificationString(guildId, userId);
      case MessageType.recall:
        return (content as RecallEntity)
            .toNotificationString(guildId, channelId);
      case MessageType.topicShare:
        return (content as TopicShareEntity).toNotificationString();
      case MessageType.stickerEntity:
        return (content as StickerEntity).toNotificationString();
      case MessageType.circleShareEntity:
        return (content as CircleShareEntity)
            .toNotificationString(userId: userId);
      case MessageType.reaction:
        return (content as ReactionEntity2).toNotificationString();
      case MessageType.goodsShareEntity:
        return (content as GoodsShareEntity).toNotificationString();
      case MessageType.externalShareEntity:
        return (content as ExternalShareEntity).toNotificationString();
      case MessageType.task:
        return (content as TaskEntity).toNotificationString();
      case MessageType.vote:
        try {
          final user = await UserInfo.get(userId);
          final ChatChannel channel = Db.channelBox.get(channelId);
          final isInGuild = channel.isInGuild;
          return '${user.showName(hideGuildNickname: !isInGuild)}?????????????????????';
        } catch (e) {
          return '????????????';
        }
        break;
      case MessageType.file:
        return (content as FileEntity).toNotificationString();
      case MessageType.messageCard:
        return (content as MessageCardEntity).toNotificationString();
      case MessageType.redPack:

        /// NOTE: 2022/1/12 ???????????? ??????[??????]+?????????
        return (content as RedPackEntity).toNotificationString() +
            (content as RedPackEntity).redPackGreetings;
      case MessageType.document:
        return (content as DocumentEntity).toNotificationString();
      case MessageType.unSupport:
        return (content as UnSupportedEntity).toNotificationString();
    }
    return "";
  }

  ///?????? ???????????????(??????????????????pin???)
  static bool messageIsNotVisible(MessageEntity message) {
    //?????????????????????????????????????????????
    // todo ?????? switch-case????????? enum extension
    if (message == null ||
        message.content.type == MessageType.upMsg ||
        message.content.type == MessageType.messageCardKey ||
        message.content.type == MessageType.recall ||
        message.content.type == MessageType.reaction ||
        message.content.type == MessageType.pinned) {
      return true;
    }
    return false;
  }

  void addDesc(Map<String, dynamic> res) {
    if (type == ChatChannelType.dm || type == ChatChannelType.group_dm) {
      String desc = '???????????????'.tr;
      //????????????
      if (content is TextEntity) {
        //????????????
        final c = content as TextEntity;
        if (type == ChatChannelType.group_dm) {
          final String userId = Global.user.id;
          final String nickname = Global.user.nickname;

          desc = '$userId::$nickname::${c.desc()}';
        } else {
          desc = c.desc();
        }
      } else if (content is ImageEntity) {
        //??????
        desc = '[??????]'.tr;
      } else if (content is VideoEntity) {
        //??????
        desc = '[??????]'.tr;
      } else if (content is MessageModificationEntity) {
        //??????
        desc = '[??????]'.tr;
      } else if (content is RecallEntity) {
        //??????
      } else if (content is TopicShareEntity) {
        //??????
        desc = '[???????????????]'.tr;
      } else if (content is StickerEntity) {
        //??????
        desc = '[??????]'.tr;
      } else if (content is CircleShareEntity) {
        //????????????
        desc = '[????????????]'.tr;
      } else if (content is ExternalShareEntity) {
        //??????????????????
        desc = '[????????????]'.tr;
      } else if (content is CallEntity) {
        //??????
        desc = '[??????]'.tr;
      } else if (content is VoiceEntity) {
        //??????
        desc = '[????????????]'.tr;
      } else if (content is RichTextEntity) {
        //?????????
        final c = content as RichTextEntity;
        if (c.title.length <= 30) {
          desc = c.title;
        } else {
          desc = '${c.title.substring(0, 20)}...';
        }
      } else if (content is FileEntity) {
        //??????
        desc = '[??????]'.tr;
      } else if (content is RedPackEntity) {
        desc = '[??????]'.tr;
      }
      res['desc'] = desc;
    }
  }
}

enum MessageState {
  none,
  waiting,
  timeout,
  sent,
  shield,
}

abstract class MessageContentEntity {
  @JsonKey(ignore: true)
  Rx<MessageState> messageState;

  final MessageType type;

  String get typeInString => _$MessageTypeEnumMap[type];

  MessageContentEntity(this.type);

  void deferredEnterWaitingState() {
    messageState ??= MessageState.none.obs;
    messageState.value = MessageState.none;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (messageState.value == MessageState.none) {
        messageState.value = MessageState.waiting;
      }
    });
  }

  Future startUpload({String channelId}) async {
    messageState ??= MessageState.waiting.obs;
    messageState.value = MessageState.waiting;
  }

  Map<String, dynamic> toJson();

  /// ??????????????????????????? mention ???????????????????????????
  Tuple2<List<String>, List<String>> get mentions => const Tuple2(null, null);
}

class EmptyEntity extends MessageContentEntity {
  EmptyEntity() : super(MessageType.empty);

  @override
  Map<String, dynamic> toJson() {
    return null;
  }
}

class ContentMask {
  static const at = 1;
  static const command = 2;
  static const allEmoji = 4;
  static const channelLink = 8;
  static const urlLink = 16;
  static const cusEmo = 32;

  /// ????????????????????????????????????@???????????????
  static const hide = 64;

  /// ?????????????????????
  static const clickable = 128;
}

class StartEntity extends MessageContentEntity {
  StartEntity() : super(MessageType.start);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{'type': typeInString};

  factory StartEntity.fromJson(Map<String, dynamic> _) => StartEntity();
}

class TextEntity extends MessageContentEntity {
  //???????????????????????????(???{})
  static final RegExp atPattern = RegExp(r"\$\{@([!&])(\d+)\}");

  //??????????????????????????????(??????{})
  static final RegExp atPatternIncomplete = RegExp(r"@([!&])(\d+)");
  static final RegExp channelLinkPattern = RegExp(r"\$\{#(\d+)\}");
  static final RegExp commandPattern = RegExp(r"\$\{/(.+?)\}");
  static final RegExp emoPattern = RegExp(r"\[(.*?)\]");

  // ???????????????????????????http://whois.chinaz.com/gblsuf?dtype=&stype=&region=&keyword=&st=ltdown
  // ???????????? (?<![$])????????????$?????????????????????????????????@XXX,?????????????????????????????????https://newtest.fanbook.mobi/doc/300000000%24OozXapqeCOPl${@!320076970777907200}
  static final RegExp urlPattern = RegExp(
      r"(http(s)?)://[a-zA-Z\d@:._+~#=-]{1,256}\.[a-z\d]{2,18}\b([-a-zA-Z\d!@:_+.~#?&/=%,$]*)(?<![$])");
  static final RegExp emojiRegExp = RegExp(
      r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');

  static bool isEmojiRegPass(String input) =>
      input.replaceAll(emojiRegExp, '') != input;

  String text;
  @JsonKey()
  int contentType = 0;
  List<String> urlList;
  List<String> inviteList;

  TextEntity({this.text, this.contentType = 0}) : super(MessageType.text) {
    _parseTextUrl();
  }

  List<String> _mentionRoles;
  List<String> _mentions;
  String atDesc;

  @override
  Tuple2<List<String>, List<String>> get mentions =>
      Tuple2(_mentionRoles, _mentions);

  /// ????????????????????????
  /// @param s: ???????????????????????????@???????????????????????????????????????????????????
  /// @param isHide: ?????????????????????@???????????????
  /// @param isClickable: ???????????????????????????
  TextEntity.fromString(
    this.text, {
    bool isHide = false,
    bool isClickable = false,
  }) : super(MessageType.text) {
    if (contentType == null) return;

    /// ?????? @ ??????
    final matches = atPattern.allMatches(text);
    if (matches.isNotEmpty) {
      matches.forEach((match) {
        if (match.group(1) == '!') {
          _mentions ??= [];
          _mentions.add(match.group(2));
        } else {
          _mentionRoles ??= [];
          _mentionRoles.add(match.group(2));
        }
      });

      ///??????
      if (_mentions != null) {
        _mentions = _mentions.toSet().toList();
      }
      if (_mentionRoles != null) {
        _mentionRoles = _mentionRoles.toSet().toList();
      }

      contentType |= ContentMask.at;
    }
    if (commandPattern.hasMatch(text)) {
      contentType |= ContentMask.command;
    }
    if (channelLinkPattern.hasMatch(text)) {
      contentType |= ContentMask.channelLink;
    }
    if (urlPattern.hasMatch(text)) {
      _parseTextUrl();
      contentType |= ContentMask.urlLink;
    }

    String s = text;

    ///????????????????????????????????????
    int cusEmoNum = 0;
    if (emoPattern.hasMatch(text)) {
      final result = text.replaceAllMapped(emoPattern, (match) {
        final start = match.start;
        final end = match.end;
        final content = text.substring(start, end);
        if (end - start <= 1) return content;
        final realContent = text.substring(start + 1, end - 1);
        if (EmoUtil.instance.allEmoMap[realContent] == null) return content;
        contentType |= ContentMask.cusEmo;
        cusEmoNum++;
        return '';
      });
      s = result;
    }

    ///?????????????????????emoji?????????char????????????1???????????????emoji?????????????????????????????????
    final Characters char = Characters(s);

    ///??????????????????emoji?????????char?????????+1???????????????????????????????????????????????????
    final int charLength =
        char.startsWith(Characters(' ')) ? char.length - 1 : char.length;
    if (charLength + cusEmoNum <= 6 && isAllEmo(char)) {
      contentType = 0;
      contentType |= ContentMask.allEmoji;
    }

    if (isHide) {
      contentType |= ContentMask.hide;
    }
    if (isClickable) {
      contentType |= ContentMask.clickable;
    }
  }

  factory TextEntity.fromJson(Map<String, dynamic> json) => TextEntity(
        text: json['text'],
        contentType: (json['contentType']) ?? 0,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': typeInString,
        'text': text,
        'contentType': contentType,
      };

  /// ??????????????????????????????????????????????????????????????????
  int get numUrls {
    return (urlList?.length ?? 0) + (inviteList?.length ?? 0);
  }

  bool get isPureLink => 1 == inviteList?.length && text == inviteList?.first;

  void _parseTextUrl() {
    final Iterable<RegExpMatch> urls = urlPattern.allMatches(text);
    urls.forEach((element) {
      final url = element.group(0);
      if (isInvitedUrl(url)) {
        inviteList ??= <String>[];
        inviteList.add(url);
      } else {
        urlList ??= <String>[];
        urlList.add(url);
      }
    });
  }

  static bool isInvitedUrl(String url) => const InviteLinkHandler().match(url);

  @override
  Future startUpload({String channelId}) async {
    await super.startUpload(channelId: channelId);

    /// ????????? 1s ???????????? loading
    messageState = MessageState.none.obs;
    deferredEnterWaitingState();

    final checkText = text.replaceAll(atPattern, '');
    final isValid = await CheckUtil.startCheck(
        TextCheckItem(checkText, getTextChatChannel(channelId: channelId)),
        toastError: false);
    if (!isValid) {
      throw CheckRejectException.fromMessageContent(this);
    }
  }

  Future<String> toNotificationString(String guildId, String userId) async {
    if (contentType == null) return text;

    String result;
    if (contentType & ContentMask.urlLink != 0) {
      result = await getText();
    } else {
      result = text;
    }

    if (contentType & ContentMask.at != 0) {
      result = await result.replaceAllMappedAsync(atPattern, (m) async {
        final id = m.group(2);
        String name;
        if (m.group(1) == "!") {
          name = (await UserInfo.get(id))?.showName(guildId: guildId) ?? "";
        } else {
          if (id == guildId) {
            name = "????????????".tr;
          } else {
            try {
              final role = PermissionModel.getPermission(guildId)
                  .roles
                  .firstWhere((element) => element.id == id);
              name = role != null && role.name != null && role.name.isNotEmpty
                  ? role.name
                  : "??????????????????".tr;
            } catch (e) {
              name = "??????????????????".tr;
            }
          }
        }
        return " @$name ";
      });
    }

    if (contentType & ContentMask.command != 0) {
      result =
          result.replaceAllMapped(RegExp(r"\$\{/(.*?)\}"), (m) => m.group(1));
    }

    if (contentType & ContentMask.channelLink != 0) {
      result = result.replaceAllMapped(channelLinkPattern, (m) {
        final id = m.group(1);
        return " #${ChatTargetsModel.instance.getChannel(id)?.name ?? '?????????????????????'.tr} ";
      });
    }
    return result;
  }

  /// ???????????????????????????
  bool isHideCommand() => contentTypeResult(ContentMask.hide);

  /// ?????????????????????
  bool isCommandClickable() => contentTypeResult(ContentMask.clickable);

  bool contentTypeResult(int contentMask) {
    if (contentType == null) return false;
    return contentType & contentMask != 0;
  }

  String desc() {
    if (text.length <= 30) {
      return text;
    } else {
      final List<String> idList = MessageUtil.getUserIdListInText(text);
      if (idList != null && idList.isNotEmpty) {
        ///fix: ?????????????????????@userId?????????????????????
        return text;
      } else if (TcDocUtils.docUrlRegFull.hasMatch(text)) {
        return text;
      } else {
        final temp = runeSubstring(text, 0, 30);
        return '$temp...';
      }
    }
  }

  String atDescStr() {
    if (atDesc.length <= 30) {
      return atDesc;
    } else {
      final temp = runeSubstring(atDesc, 0, 30);
      return '$temp...';
    }
  }

  Future<String> getText() async {
    if (TcDocUtils.docUrlRegFull.hasMatch(text)) {
      final match = TcDocUtils.docUrlRegFull.firstMatch(text)?.group(0);
      if (match != null) {
        final String url = match.toString();
        final hostMatch = TcDocUtils.docUrlReg.firstMatch(url)?.group(0);
        if (hostMatch != null) {
          try {
            String fileId = url.substring(hostMatch.length);
            fileId = Uri.decodeComponent(fileId);

            final String replacement =
                await DocLinkPreviewController.to(fileId).getTitle();

            final int start = text.indexOf(match);
            final int end = start + match.length;
            return text.replaceRange(start, end, replacement);
          } catch (e) {
            print(e);
          }
        }
      }
    }
    return text;
  }

  static String runeSubstring(String input, int start, int end) {
    return String.fromCharCodes(input.runes.toList().sublist(start, end));
  }

  static String getAtString(String id, bool isRole) {
    return "\${@${isRole ? '&' : '!'}$id}";
  }

  static bool isAtString(String text) {
    const String s = r"${@";
    if (text != null && text.isNotEmpty) {
      return text.startsWith(s);
    }
    return false;
  }

  static String getChannelLinkString(String id) {
    return "\${#$id}";
  }

  static String getCommandString(String command) => "\${/$command}";
}

@JsonSerializable()
class ImageEntity extends MessageContentEntity {
  String url;
  int width;
  int height;
  String fileType;
  String localFilePath;
  String localIdentify;
  @JsonKey(ignore: true)
  Asset asset;
  bool thumb;

  ImageEntity({
    this.url,
    this.width,
    this.height,
    this.asset,
    this.fileType,
    this.localFilePath,
    this.localIdentify,
    this.thumb = true,
  }) : super(MessageType.image);

  String toNotificationString() => "[??????]".tr;

  factory ImageEntity.fromAsset(Asset asset) {
    return ImageEntity(
        asset: asset,
        width: asset.originalWidth?.toInt() ?? 0,
        height: asset.originalHeight?.toInt() ?? 0,
        fileType: asset.fileType,
        localFilePath: asset.filePath,
        localIdentify: asset.identifier);
  }

  factory ImageEntity.fromJson(Map<String, dynamic> srcJson) =>
      _$ImageEntityFromJson(srcJson);

  @override
  Map<String, dynamic> toJson() => _$ImageEntityToJson(this);

  Future compressAsset() async {
    final compressedAssets = await MultiImagePicker.requestMediaData(
        thumb: thumb, selectedAssets: [asset?.identifier ?? localIdentify]);
    asset = compressedAssets.first;

    if (asset == null || !File(asset.filePath).existsSync()) {
      throw Exception('??????????????????'.tr);
    }

    if (File(asset.filePath).lengthSync() > 100 * 1024 * 1024) {
      showToast('???????????????????????????100M'.tr);
      throw Exception('???????????????????????????100M???%s???'.trArgs(
          [(File(asset.filePath).lengthSync() / 1024 / 1024).toString()]));
    }
    height = asset.originalHeight.toInt();
    width = asset.originalWidth.toInt();
    localFilePath = asset.filePath;
  }

  @override
  Future startUpload({String channelId}) async {
    final startCheckTime = DateTime.now();

    await super.startUpload(channelId: channelId);
    if (url != null && url.isNotEmpty) {
      return;
    }

    Uint8List checkFileBytes;
    String path;
    if (kIsWeb) {
      path = asset.filePath;
      checkFileBytes = checkImageCache[asset.name];
    } else {
      path = asset.checkPath ?? asset.filePath;
      checkFileBytes = File(path).readAsBytesSync();
    }

    if (!await CheckUtil.startCheck(
        ImageCheckItem.fromBytes([U8ListWithPath(checkFileBytes, path)],
            getImageChatChannel(channelId: channelId)),
        toastError: false)) throw CheckRejectException.fromMessageContent(this);
    try {
      final put =
          await CosPutObject.create(asset.filePath, CosUploadFileType.image);
      url = await CosFileUploadQueue.instance.once(put);
      await CustomCacheManager.instance.putFileStream(
          url, XFile(asset.filePath).openRead(),
          fileExtension: url.substring(url.lastIndexOf('.') + 1));

      final endCheckTime = DateTime.now();
      final diff = endCheckTime.difference(startCheckTime);
      final fileLength = put.fileSize; // uploadFileBytes.lengthInBytes;
      logger.info(
          '??????????????????:${filesize(fileLength)}   ?????????????????????:   ${diff.inMilliseconds}??????');
      if (kIsWeb) {
        webSendImageCache[asset.name] = null;
        checkImageCache[asset.name] = null;
      }
    } catch (e) {
      print(e);
      rethrow;
    }
  }
}

@JsonSerializable()
class VideoEntity extends MessageContentEntity {
  String url;
  String videoName;
  int width;
  int height;
  String localPath;
  String thumbUrl;
  int thumbWidth;
  int thumbHeight;
  int duration = 0;
  String thumbName;
  String fileType;
  String localThumbPath;
  String localIdentify;
  @JsonKey(ignore: true)
  Asset asset;
  @JsonKey(ignore: true)
  bool thumb = true;

  VideoEntity({
    this.url,
    this.videoName,
    this.width,
    this.height,
    this.thumbUrl,
    this.thumbWidth,
    this.thumbHeight,
    this.duration = 0,
    this.asset,
    this.thumbName,
    this.fileType,
    this.localPath,
    this.localThumbPath,
    this.localIdentify,
  }) : super(MessageType.video);

  String toNotificationString() => "[??????]".tr;

  factory VideoEntity.fromAsset(Asset asset) {
    return VideoEntity(
        videoName: asset.name,
        duration: asset.duration?.toInt() ?? 0,
        width: asset.originalWidth?.toInt() ?? 0,
        height: asset.originalHeight?.toInt() ?? 0,
        localPath: asset.filePath ?? '',
        thumbUrl: asset.thumbFilePath ?? '',
        thumbWidth: asset.thumbWidth?.toInt() ?? 0,
        thumbHeight: asset.thumbHeight?.toInt() ?? 0,
        thumbName: asset.thumbName ?? '',
        fileType: asset.fileType,
        localIdentify: asset.identifier,
        localThumbPath: asset.thumbFilePath ?? '',
        asset: asset);
  }

  factory VideoEntity.fromJson(Map<String, dynamic> srcJson) =>
      _$VideoEntityFromJson(srcJson);

  @override
  Map<String, dynamic> toJson() => _$VideoEntityToJson(this);

  Future compressAsset() async {
    final compressedAssets = await MultiImagePicker.requestMediaData(
        thumb: thumb, selectedAssets: [asset?.identifier ?? localIdentify]);
    asset = compressedAssets.first;
    if (asset == null ||
        !File(asset.filePath).existsSync() ||
        !File(asset.thumbFilePath).existsSync()) {
      throw Exception('??????????????????'.tr);
    }

    if (File(asset.filePath).lengthSync() > 100 * 1024 * 1024) {
      showToast('?????????????????????????????????100M'.tr);
      throw Exception('???????????????????????????100M???%s???'.trArgs(
          [(File(asset.filePath).lengthSync() / 1024 / 1024).toString()]));
    }
    videoName = asset.name;
    duration = asset.duration.toInt();
    width = asset.originalWidth.toInt();
    height = asset.originalHeight.toInt();
    thumbHeight = asset.thumbHeight.toInt();
    thumbWidth = asset.thumbWidth.toInt();
    thumbName = asset.thumbName;
    localThumbPath = asset.thumbFilePath;
    localPath = asset.filePath;
  }

  @override
  Future startUpload({String channelId}) async {
    await super.startUpload(channelId: channelId);
    try {
      if (url != null && url.isNotEmpty) {
        return;
      }
      Uint8List thumbBytes;
      if (kIsWeb) {
        thumbBytes = await PickedFile(asset.thumbFilePath).readAsBytes();
      } else {
        thumbBytes = await File(asset.thumbFilePath).readAsBytes();
      }

      ///???????????????????????????????????????
      final res = await CheckUtil.startCheck(
          ImageCheckItem.fromBytes(
              [U8ListWithPath(thumbBytes, asset.thumbFilePath)],
              getImageChatChannel(channelId: channelId)),
          toastError: false);
      if (!res) {
        // showToast(defaultErrorMessage);
        throw CheckRejectException.fromMessageContent(this);
      }

      ///?????????????????????????????????[fileType]?????????[UploadType.image]
      // thumbUrl = await uploadFileIfNotExist(
      //     bytes: thumbBytes,
      //     filename: asset.thumbName,
      //     fileType: UploadType.image);
      thumbUrl = await CosFileUploadQueue.instance
          .onceForPath(asset.thumbFilePath, CosUploadFileType.image);
      await CustomCacheManager.instance.putFile(thumbUrl, thumbBytes,
          fileExtension: thumbUrl.substring(thumbUrl.lastIndexOf('.') + 1));

      // Uint8List bytes;
      // if (kIsWeb) {
      //   bytes = await PickedFile(asset.filePath).readAsBytes();
      // } else {
      //   bytes = await File(asset.filePath).readAsBytes();
      // }
      // final stopwatch2 = Stopwatch()..start();
      // url = await uploadFileIfNotExist(
      //     bytes: bytes, filename: asset.name, fileType: UploadType.video);
      // print("?????????????????????$url ---");
      // logger.info('hash executed in ${stopwatch2.elapsed}');
      // await CustomCacheManager.instance.putFile(url, bytes,
      //     fileExtension: url.substring(url.lastIndexOf('.') + 1));

      url = await CosFileUploadQueue.instance
          .onceForPath(asset.filePath, CosUploadFileType.video);
      await CustomCacheManager.instance.putFileStream(
          url, XFile(asset.filePath).openRead(),
          fileExtension: url.substring(url.lastIndexOf('.') + 1));
    } catch (e) {
      print(e);
      rethrow;
    }
  }
}

class MessageModificationEntity extends MessageContentEntity {
  final String messageId;
  final MessageContentEntity content;

  final ReplyMarkup replyMarkup;

  MessageModificationEntity({this.messageId, this.content, this.replyMarkup})
      : super(MessageType.upMsg);

  factory MessageModificationEntity.fromJson(Map<String, dynamic> json) =>
      MessageModificationEntity(
        messageId: json["message_id"],
        content: MessageEntity.contentFromString(json["content"]),
        replyMarkup: json["reply_markup"] == null
            ? null
            : ReplyMarkup.fromJson(json["reply_markup"]),
      );

  @override
  Map<String, dynamic> toJson() {
    final result = {
      "message_id": messageId,
      "type": typeInString,
      "content": jsonEncode(content.toJson()),
    };
    if (replyMarkup != null) {
      result["reply_markup"] = jsonEncode(replyMarkup.toJson());
    }
    return result;
  }
}

class RecallEntity extends MessageContentEntity {
  RecallEntity({this.id}) : super(MessageType.recall);

  final String id;

  factory RecallEntity.fromJson(Map<String, dynamic> json) => RecallEntity(
        id: json["id"],
      );

  @override
  Map<String, dynamic> toJson() => {
        "id": id,
        "type": typeInString,
      };

  Future<String> toNotificationString(String guildId, String channelId) async {
    final defaultString = "?????????????????????".tr;
    final m = InMemoryDb.getMessage(channelId, BigInt.parse(id));

    /// ????????????????????????????????????????????????????????????????????????
    if (m == null) return defaultString;

    switch (RecalledItem.getRecalledMessageFormat(m)) {
      case RecalledMessageFormat.IRecallMyMessage:
        return "????????????????????????".tr;
      case RecalledMessageFormat.someoneRecallHisMessage:
        return "%s ?????????????????????".trArgs(
            [(await UserInfo.get(m.recall))?.showName(guildId: guildId) ?? ""]);
      case RecalledMessageFormat.IRecallSomeonesMessage:
        return "???????????? %s ??????????????????".trArgs(
            [(await UserInfo.get(m.userId))?.showName(guildId: guildId) ?? ""]);
      case RecalledMessageFormat.someoneRecallMyMessage:
        return "%s ??????????????????????????????".trArgs(
            [(await UserInfo.get(m.recall))?.showName(guildId: guildId) ?? ""]);
      case RecalledMessageFormat.someoneRecallAnotherOnesMessage:
        return "%s ????????? %s ??????????????????".trArgs([
          (await UserInfo.get(m.recall))?.showName(guildId: guildId) ?? "",
          (await UserInfo.get(m.userId))?.showName(guildId: guildId) ?? ""
        ]);
    }
    return defaultString;
  }
}

class TopicShareEntity extends MessageContentEntity {
  final String messageId;
  final String channelId;
  final String userId;

  TopicShareEntity(
    this.messageId,
    this.channelId,
    this.userId,
  ) : super(MessageType.topicShare);

  @override
  Map<String, dynamic> toJson() => {
        "messageId": messageId,
        "channelId": channelId,
        "userId": userId,
        "type": typeInString,
      };

  factory TopicShareEntity.fromJson(Map<String, dynamic> json) =>
      TopicShareEntity(
        json["messageId"],
        json["channelId"],
        json["userId"],
      );

  Future<String> toNotificationString() async {
    return "[%s]???????????????".trArgs([(await UserInfo.get(userId)).nickname]);
  }
}

///??????
class StickerEntity extends MessageContentEntity {
  final String id;
  final String name;
  final String url;
  final double width;
  final double height;

  StickerEntity(this.id, this.name, this.url, {this.width, this.height})
      : super(MessageType.stickerEntity);

  @override
  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "url": url,
        "type": typeInString,
        "width": width,
        "height": height,
      };

  factory StickerEntity.fromJson(Map<String, dynamic> json) => StickerEntity(
        json["id"],
        json["name"],
        json["url"],
        width: json["width"]?.toDouble(),
        height: json["height"]?.toDouble(),
      );

  Future<String> toNotificationString() async {
    return '[$name]';
  }
}

///??????????????????
class CircleShareEntity extends MessageContentEntity {
  final CirclePostDataModel data;
  final String id;

  CircleShareEntity({this.data, this.id})
      : super(MessageType.circleShareEntity);

  @override
  Map<String, dynamic> toJson() =>
      {'type': typeInString, 'data': data?.toJsonByModel() ?? {}};

  factory CircleShareEntity.fromJson(Map<String, dynamic> json) =>
      CircleShareEntity(
        data: CirclePostDataModel.fromJson(json['data']),
      );

  Future<String> toNotificationString({String userId}) async {
    final userInfo = data?.userDataModel;
    final userName = userInfo?.userName;
    final localUser = Db.userInfoBox.get(userInfo?.userId ?? '');
    String shareUser = '';
    if (userId != null) {
      shareUser = Db.userInfoBox.get(userId)?.showName() ?? '';
    }
    return '%s????????????[%s?????????]'
        .trArgs([shareUser, localUser?.showName() ?? userName]);
  }

  ///????????????????????????????????????????????????
  Future<String> toReplyNotificationString() async {
    final userInfo = data?.userDataModel;
    final userName = userInfo?.userName;
    final localUser = Db.userInfoBox.get(userInfo?.userId ?? '');
    return '?????????[%s'.trArgs([localUser?.showName() ?? userName]);
  }
}

class GoodsShareEntity extends MessageContentEntity {
  final String goodsId;
  final String goodsName;
  final String originalPrice;
  final String price;
  final String icon;
  final String detailUrl;

  /// ???????????????????????????????????????????????????
  String _lowPrice;

  String get lowPrice => _lowPrice ?? '';

  /// ???????????????????????????
  bool _isMultiSpecification;

  bool get isMultiSpecification => _isMultiSpecification ?? false;

  /// ?????????????????????????????????
  bool _isValidPrice;

  bool get isValidPrice => _isValidPrice ?? false;

  GoodsShareEntity({
    this.goodsId,
    this.goodsName,
    this.originalPrice,
    this.price,
    this.icon,
    this.detailUrl,
  }) : super(MessageType.goodsShareEntity) {
    _lowPrice = _parseLowPrice();
    _isMultiSpecification = _lowPrice.hasValue;
    _isValidPrice = isNumeric(price) || _isMultiSpecification;
  }

  String toNotificationString() => detailUrl;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': typeInString,
      'goodsId': goodsId,
      'goodsName': goodsName,
      'originalPrice': originalPrice,
      'price': price,
      'icon': icon,
      'detailUrl': detailUrl
    };
  }

  factory GoodsShareEntity.fromJson(Map<String, dynamic> json) =>
      GoodsShareEntity(
        goodsId: json['goodsId'],
        goodsName: json['goodsName'],
        originalPrice: json['originalPrice'],
        price: json['price'],
        icon: json['icon'],
        detailUrl: json['detailUrl'],
      );

  String _parseLowPrice() {
    if (!price.hasValue) return '';
    if (isNumeric(price)) return '';
    final prices = price.split('-');
    if (prices == null || prices.length != 2) return '';
    return (isNumeric(prices[0]) && isNumeric(prices[1])) ? prices[0] : '';
  }

  /// ?????????????????????????????????,??????88.9-99.9

  bool isValid() {
    return goodsId.hasValue &&
        goodsName.hasValue &&
        _isValidPrice &&
        icon.hasValue &&
        detailUrl.hasValue;
  }
}

/// ??????????????????
class ExternalShareEntity extends MessageContentEntity {
  final String shareContentType;
  final String desc;
  String imageUrl;
  String imageLocalPath;
  Uint8List imageBytes; //??????json????????????????????????
  final String link;
  final String state;
  final String clientId;
  final String guildId;
  final String packageName;
  final String inviteCode;
  final String appName;
  final String appAvatar;

  ExternalShareEntity(
      {this.shareContentType,
      this.desc,
      this.imageUrl,
      this.imageLocalPath,
      this.imageBytes,
      this.link,
      this.state,
      this.clientId,
      this.guildId,
      this.packageName,
      this.inviteCode,
      this.appName,
      this.appAvatar})
      : super(MessageType.externalShareEntity);

  String toNotificationString() =>
      appName.hasValue ? "??????$appName?????????" : "?????????????????????".tr;

  @override
  Future startUpload({String channelId}) async {
    final startCheckTime = DateTime.now();
    await super.startUpload(channelId: channelId);

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return;
    }

    if (!imageLocalPath.hasValue &&
        (imageBytes == null || imageBytes.isEmpty)) {
      // imageBytes imageLocalPath ??????????????????????????????
      return;
    }

    // // ?????????????????????????????????????????????????????????
    // if (imageLocalPath == null) {
    //   if (imageBytes != null && imageBytes.isNotEmpty) {
    //     final String tempFileKey = "tempFile-${imageBytes.hashCode}";
    //     final file =
    //         await CustomCacheManager.instance.putFile(tempFileKey, imageBytes);
    //     imageLocalPath = file.path;
    //   } else {
    //     // ??????url,?????????????????????????????????????????????????????????
    //     print("start upload");
    //     return;
    //   }
    // }

    try {
      imageBytes ??= await File(imageLocalPath).readAsBytes();
    } catch (e) {
      // ?????????????????????????????????????????????
      return;
    }

    if (!await CheckUtil.startCheck(
        ImageCheckItem.fromBytes([U8ListWithPath(imageBytes, imageLocalPath)],
            getImageChatChannel(channelId: channelId)),
        toastError: false)) throw CheckRejectException.fromMessageContent(this);

    try {
      // imageUrl = await uploadFileIfNotExist(
      //     bytes: imageBytes, filename: "share_link_image", fileType: "image");
      imageUrl = await CosFileUploadQueue.instance
          .onceForBytes(imageBytes, CosUploadFileType.image);

      //??????????????????
      // await CustomCacheManager.instance.putFile(imageUrl, imageBytes,
      //     fileExtension: imageUrl.substring(imageUrl.lastIndexOf('.') + 1));
      //????????????????????????????????????
      final String tempFileKey = "tempFile-${imageBytes.hashCode}";
      await CustomCacheManager.instance.removeFile(tempFileKey);

      final endCheckTime = DateTime.now();
      final diff = endCheckTime.difference(startCheckTime);
      final fileLength = imageBytes.lengthInBytes;
      logger.info(
          '??????????????????:${filesize(fileLength)}   ?????????????????????:   ${diff.inMilliseconds}??????');
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': typeInString,
      'shareContentType': shareContentType,
      'desc': desc,
      'imageUrl': imageUrl,
      'imageLocalPath': imageLocalPath,
      'link': link,
      'state': state,
      'clientId': clientId,
      'guildId': guildId,
      'packageName': packageName,
      'inviteCode': inviteCode,
      'appName': appName,
      'appAvatar': appAvatar
    };
  }

  factory ExternalShareEntity.fromJson(Map<String, dynamic> json) =>
      ExternalShareEntity(
        shareContentType: json['shareContentType'],
        desc: json['desc'],
        imageUrl: json['imageUrl'],
        imageLocalPath: json['imageLocalPath'],
        link: json['link'],
        state: json['state'],
        clientId: json['clientId'],
        guildId: json['guildId'],
        packageName: json['packageName'],
        inviteCode: json['inviteCode'],
        appName: json['appName'],
        appAvatar: json['appAvatar'],
      );
}

class PinEntity extends MessageContentEntity {
  final String action;
  final String id;

  PinEntity({this.action, this.id}) : super(MessageType.pinned);

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': typeInString,
      'action': action,
      'id': id,
    };
  }

  factory PinEntity.fromJson(Map<String, dynamic> json) => PinEntity(
        action: json["action"],
        id: json["id"],
      );
}

class ReactionEntity2 extends MessageContentEntity {
  ReactionEntity2({
    this.action,
    this.emoji,
    this.id,
  }) : super(MessageType.reaction);

  String action;
  String id;
  ReactionEntity emoji;

  factory ReactionEntity2.fromJson(Map<String, dynamic> json) =>
      ReactionEntity2(
        action: json["action"],
        id: json["id"],
        emoji: ReactionEntity.fromMap(json["emoji"]),
      );

  @override
  Map<String, dynamic> toJson() => {
        "type": typeInString,
        "id": id,
        "action": action,
        "emoji": emoji.toJson(),
      };

  String toNotificationString() {
    try {
      return "[${Uri.decodeComponent(emoji.name)}]";
    } catch (e) {
      return "[${emoji.name}]";
    }
  }
}

@JsonSerializable()
class WelcomeEntity extends MessageContentEntity {
  static final _welcomeSentences = [
    "%% ?????????".tr,
    "%% ????????????".tr,
    "?????? %% ????????????~".tr,
    "????????????%% ???????????????".tr,
    "????????????%%???".tr,
    "%% ???????????????????????????".tr,
    "TA??????~TA??????~????????? %%???".tr,
    "??????????????? %%???".tr,
    "?????????????????? %%???".tr,
  ];

  int index;
  @JsonKey(ignore: true)
  final String text;

  WelcomeEntity({this.index = 0})
      : text = _welcomeSentences[(index ?? 0) % _welcomeSentences.length],
        super(MessageType.newJoin);

  factory WelcomeEntity.fromJson(Map<String, dynamic> srcJson) =>
      _$WelcomeEntityFromJson(srcJson);

  @override
  Map<String, dynamic> toJson() => _$WelcomeEntityToJson(this);

  Future<String> toNotificationString(String userId) async =>
      text.replaceFirst("%%", (await UserInfo.get(userId)).nickname);
}

@JsonSerializable()
class CallEntity extends MessageContentEntity {
  static const statusBeCalled = 0; // ?????????
  static const statusCalledPartyAccepted = 1; // ???????????????
  static const statusCalledPartyNoResponse = 2; // ??????????????????
  static const statusCalledPartyDenied = 3; // ???????????????
  static const statusCallingPartyCanceled = 4; // ?????????????????????
  static const statusUnnamed = 5; // ??????????????? todo ???????????????????????????
  static const statusFinished = 6; // ????????????

  int status;
  int duration;
  int video;
  int objectId;

  CallEntity({
    this.duration,
    this.status,
    this.objectId,
    this.video,
  }) : super(MessageType.call);

  factory CallEntity.fromJson(Map<String, dynamic> srcJson) =>
      _$CallEntityFromJson(srcJson);

  @override
  Map<String, dynamic> toJson() => _$CallEntityToJson(this);

  String toNotificationString() => "[??????]".tr;
}

@JsonSerializable()
class VoiceEntity extends MessageContentEntity {
  String url;
  String path;
  int second;
  bool isRead;

  VoiceEntity({
    this.url,
    this.path,
    this.second,
    this.isRead = true,
  }) : super(MessageType.voice);

  String toNotificationString() => "[??????]".tr;

  factory VoiceEntity.fromJson(Map<String, dynamic> srcJson) =>
      _$VoiceEntityFromJson(srcJson);

  VoiceEntity clone() =>
      VoiceEntity(url: url, path: path, second: second, isRead: isRead);

  @override
  Map<String, dynamic> toJson() => _$VoiceEntityToJson(this);

  @override
  Future startUpload({String channelId}) async {
    await super.startUpload(channelId: channelId);

    try {
      // final bytes = await File(path).readAsBytes();
      // url = await uploadFileIfNotExist(
      //     bytes: bytes,
      //     filename: path.substring(path.lastIndexOf('/')),
      //     fileType: UploadType.video);
      url = await CosFileUploadQueue.instance
          .onceForPath(path, CosUploadFileType.audio);
    } catch (e) {
      print(e);
      rethrow;
    }
  }
}

class RichTextEntity extends MessageContentEntity {
  static const version = 2;
  final Document document;
  final String title;
  final int v;
  List<String> _mentions;
  List<String> _mentionRoles;
  List<String> _links;

  RichTextEntity({
    @required this.document,
    this.v = version,
    this.title = '',
  }) : super(MessageType.richText) {
    final docStr = jsonEncode(document.toDelta());
    final matches = TextEntity.atPattern.allMatches(docStr);
    if (matches.isNotEmpty) {
      matches.forEach((match) {
        if (match.group(1) == '!') {
          _mentions ??= [];
          _mentions.add(match.group(2));
        } else {
          _mentionRoles ??= [];
          _mentionRoles.add(match.group(2));
        }
      });

      ///??????
      if (_mentions != null) {
        _mentions = _mentions.toSet().toList();
      }
      if (_mentionRoles != null) {
        _mentionRoles = _mentionRoles.toSet().toList();
      }
    }
    final urlMatches = TextEntity.urlPattern.allMatches(docStr);
    if (urlMatches.isNotEmpty) {
      urlMatches.forEach((match) {
        _links ??= [];
        _links.add(match.group(0));
      });
    }
  }

  factory RichTextEntity.fromJson(Map<String, dynamic> srcJson) {
    // ?????????????????????????????????
    final jsonString = RichEditorUtils.toCompatibleJson(
        srcJson['v2'] ?? srcJson['document'] ?? '');
    final json = (jsonDecode(jsonString) as List).cast<Map<String, dynamic>>();
    RichEditorUtils.transformAToLink(json);
    return RichTextEntity(
        v: srcJson['v'] ?? 1, // ?????? v ?????????????????????????????????
        title: srcJson['title'] ?? '',
        document: Document.fromJson(json));
  }

  @override

  ///?????????????????????????????????:
  /// ??? document???????????????????????????200
  /// ??? v2: ??????????????????
  Map<String, dynamic> toJson() {
    final value = StringBuffer();
    final operationList =
        RichEditorUtils.formatDelta(document.toDelta()).toList();
    for (final o in operationList) {
      if (o.isImage) {
        value.write('[??????]'.tr);
      } else if (o.isVideo) {
        value.write('[??????]'.tr);
      } else if (o.value is String) {
        value.write(o.value);
      } else if (o.value is Map) {
        value.write(o.value['mention'] != null
            ? (o.value['mention']['value'] ?? '')
            : '');
      }
    }
    final tempDocument = Document();
    String value2 = value.toString().replaceAll(RegExp(r'\n+$'), '');
    if (value2.length > 200) {
      value2 = value2.substring(0, 200);
    }
    tempDocument.insert(0, value2);

    final map = {
      'type': typeInString,
      'title': title,
      'document': jsonEncode(tempDocument.toDelta()),
      'v2': jsonEncode(document.toDelta()),
      'v': v,
    };
    return map;
  }

  Future<String> toNotificationString(String guildId, String userId,
      {bool entire = false}) async {
    if (!entire && isNotNullAndEmpty(title)) {
      return title;
    }
    String value = '';
    value += isNotNullAndEmpty(title) ? '$title\n' : '';
    final operationList =
        RichEditorUtils.formatDelta(document.toDelta()).toList();
    for (final o in operationList) {
      if (o.isImage) {
        value += '[??????]'.tr;
      } else if (o.isVideo) {
        value += '[??????]'.tr;
      } else if (o.value is String) {
        final String res = await TextEntity.fromString(o.value)
            .toNotificationString(guildId, userId);
        value += res;
      }
    }
    return value.replaceAll(RegExp(r'\n+$'), '');
  }

  @override
  Tuple2<List<String>, List<String>> get mentions =>
      Tuple2(_mentionRoles, _mentions);

  List<String> get links => _links;

  ///??????????????????????????????????????????????????????
  String toSearchTextString() {
    final StringBuffer value = StringBuffer();
    value.write(isNotNullAndEmpty(title) ? title : '');
    final operationList =
        RichEditorUtils.formatDelta(document.toDelta()).toList();
    for (final o in operationList) {
      if (o.isImage || o.isVideo) {
        continue;
      } else if (o.value is String) {
        value.write(o.value);
      }
    }
    return value.toString().trimEmptyEnd();
  }
}

///?????????????????????(????????????????????????)
class CirclePostNewsEntity extends MessageContentEntity {
  String circleType;
  String postId;
  BigInt commentId;

  //???desc????????????????????????
  String msg;

  ///????????????-?????????
  String desc;

  ///0 ?????????(??????); 1 ?????????
  int atMe;

  ///?????????0 ??????; 1 ?????????
  int status;

  ///????????????
  String name;

  ///??????icon
  String icon;

  ///????????????ID(type=5)
  String channelId;

  CirclePostNewsEntity({
    this.circleType,
    this.postId,
    this.commentId,
    this.msg,
    this.desc,
    this.atMe = 0,
    this.status = 0,
    this.name,
    this.icon,
    this.channelId,
  }) : super(MessageType.circle) {
    if (circleType == 'comment_delete') {
      status = 1;
    }
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': typeInString,
      };

  factory CirclePostNewsEntity.fromJson(Map<String, dynamic> data) {
    BigInt cId;
    if (data['comment_id'] is int) {
      cId = BigInt.from(data['comment_id']);
    } else {
      cId = (data['comment_id'] as String).hasValue
          ? BigInt.parse(data['comment_id'])
          : BigInt.from(0);
    }
    String cName;
    if (data['name'] != null && data['name'] is String) {
      cName = MessageUtil.trimEmptyEnd(data['name']);
    } else {
      cName = '';
    }
    return CirclePostNewsEntity(
      circleType: data['circle_type'],
      postId: data['post_id'],
      commentId: cId,
      msg: data['msg'],
      desc: data['desc'],
      atMe: data['at_me'] ?? 0,
      name: cName,
      icon: data['icon'],
      channelId: data['channel_id'],
    );
  }

  bool updateAtMe(List<String> mentionList) {
    if (mentionList != null && mentionList.contains(Global.user.id)) {
      atMe = 1;
    } else {
      atMe = 0;
    }
    return atMe == 1;
  }
}
