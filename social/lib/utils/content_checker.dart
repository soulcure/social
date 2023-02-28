import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:get/get.dart' as get_x;
import 'package:http/http.dart' as http;
import 'package:im/api/check_api.dart';
import 'package:im/api/check_info_api.dart';
import 'package:im/api/entity/check_post_bean.dart';
import 'package:im/api/entity/check_result.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/db/db.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/friend/relation.dart';
import 'package:im/pages/friend/widgets/relation_utils.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:oktoast/oktoast.dart';

typedef VoidCallback = void Function();

///审核调用工具
class CheckUtil {
  static Future<bool> startCheck(CheckItem checkItem,
      {bool toastError = true}) async {
    final startCheckTime = DateTime.now();
    final result = await checkItem.startCheck(toastError: toastError);
    final endCheckTime = DateTime.now();
    final diff = endCheckTime.difference(startCheckTime);
    final isImage = checkItem is ImageCheckItem;
    final isVideo = checkItem is VideoCheckItem;
    final sizeString =
        isImage ? (checkItem as ImageCheckItem).getFileSizeList() : '';
    if (!isVideo)
      logger.finer(
          'Item:$checkItem $sizeString 检测所消耗时间为: ${diff.inMilliseconds}毫秒');
    return result;
  }
}

class TextChannelType {
  ///群聊
  static const String GROUP_MESSAGE = 'GROUP_MESSAGE';

  ///好友私聊
  static const String FRIEND_MESSAGE = 'FRIEND_MESSAGE';

  ///陌生人私聊
  static const String STRANGER_MESSAGE = 'STRANGER_MESSAGE';

  ///频道分类名字
  static const String CHANNEL_CLASSIFICATION_NAME =
      'CHANNEL_CLASSIFICATION_NAME';

  ///频道标题
  static const String CHANNEL_TITLE = 'CHANNEL_TITLE';

  ///频道名字
  static const String CHANNEL_NAME = 'CHANNEL_NAME';

  ///服务器名字
  static const String SERVICE_NAME = 'SERVICE_NAME';

  ///签名
  static const String SIGNATURE = 'SIGNATURE';

  ///用户昵称
  static const String NICKNAME = 'NICKNAME';

  ///帖子文本
  static const String FB_CIRCLE_POST_TEXT = 'fbCirclePostText';

  ///帖子评论
  static const String FB_CIRCLE_POST_COMMENT = 'fbCirclePostComment';

  ///圈子话题
  static const String FB_CIRCLE_TOPIC = 'fbCircleTopic';

  ///圈子名称
  static const String FB_CIRCLE_TITLE = 'fbCircleTitle';

  ///圈子描述
  static const String FB_CIRCLE_DESC = 'fbCircleDesc';

  ///直播文本聊天
  static const String FB_LIVE_TEXT_MSG = 'fbLiveTextMsg';

  ///直播主题描述
  static const String FB_LIVE_DESC = 'fbLiveDesc';

  ///创建文档标题（或者修改文档标题）
  static const String FB_WD_TITLE = 'fbWDTitle';
}

///FIXME:数美提供的图片审核channel字段风格不统一，并且不规范，猜想他们中途换人了？
class ImageChannelType {
  ///群聊图片
  static const String groupMessage = 'groupMessage';

  ///好友私聊图片
  static const String friendMessage = 'friendmessage';

  ///陌生人私聊图片
  static const String strangerMessage = 'strangermessage';

  ///用户头像
  static const String headImage = 'headImage';

  ///服务器头像
  static const String serviceImage = 'seviceImage';

  ///帖子图片
  static const String FB_CIRCLE_POST_PIC = 'fbCirclePostPic';

  ///圈子头像
  static const String FB_CIRCLE_AVATAR = 'fbCircleAvatar';

  ///圈子背景图
  static const String FB_CIRCLE_BACKGROUND_PIC = 'fbCircleBackgroundPic';

  ///直播封面
  static const String FB_LIVE_COVER = 'fbLiveCover';
}

String defaultErrorMessage = '此内容包含违规信息,请修改后重试'.tr;
String defaultErrorImage = '此图片含违规信息,请修改后重试'.tr;

abstract class CheckItem {
  Future<bool> startCheck({bool toastError = true});

  final Function(String text) showCheckReject;
  final VoidCallback onCheckPass;

  CheckItem({this.onCheckPass, this.showCheckReject});
}

///文字审核
class TextCheckItem extends CheckItem {
  final String text;
  final String channel;
  final CheckType checkType;

  @override
  Future<bool> startCheck({bool toastError = true}) async {
    final before = beforeText(channel, checkType);
    if (!before) return true;

    ///FIXME:这里由于数美对于包含@的信息，会判断为灌水行为，所以应他们要求，发送给他们的审核信息，去掉@
    final data = await CheckApi.postCheckText(
      text.replaceAll('@', ''),
      channel,
      showDefaultErrorToast: toastError,
    );
    if (data == null) return false;
    if (data['riskLevel'] == 'REJECT') {
      if (toastError) showToast(defaultErrorMessage);
      showCheckReject?.call(data['message'] ?? defaultErrorMessage);
      return false;
    }
    onCheckPass?.call();
    return true;
  }

  TextCheckItem(
    this.text,
    this.channel, {
    Function(String text) showCheckReject,
    VoidCallback onCheckPass,
    this.checkType = CheckType.defaultType,
  }) : super(showCheckReject: showCheckReject, onCheckPass: onCheckPass);

  @override
  String toString() {
    return 'TextCheckItem{text: $text, channel: $channel}';
  }
}

///图片审核
class ImageCheckItem extends CheckItem {
  Future<List<ImgData>> imgData;
  List<ImgData> _tempImgData;
  final String channel;
  final CheckType checkType;
  final bool needCompress;

  @override
  Future<bool> startCheck({bool toastError = true}) async {
    final before = beforeImage(channel, checkType);
    if (!before) return true;
    _tempImgData = await imgData;
    final data = await CheckApi.postCheckImage(_tempImgData, channel,
        showDefaultErrorToast: toastError);
    if (data == null) return true;
    final ImageCheckResult checkResult = ImageCheckResult.fromMap(data);
    for (final img in checkResult.imgs) {
      if (img?.riskLevel == 'REJECT') {
        if (toastError) showToast(defaultErrorImage);
        showCheckReject?.call(img.message ?? defaultErrorImage);
        return false;
      }
    }
    return true;
  }

  ImageCheckItem.fromAsset(
    List<Asset> assets,
    this.channel, {
    Function(String text) showCheckReject,
    VoidCallback onCheckPass,
    this.checkType = CheckType.defaultType,
    this.needCompress = false,
  }) : super(showCheckReject: showCheckReject, onCheckPass: onCheckPass) {
    imgData = ImgData.fromAssets(assets, needCompress: needCompress);
  }

  ImageCheckItem.fromFile(
    List<File> files,
    this.channel, {
    Function(String text) showCheckReject,
    VoidCallback onCheckPass,
    this.checkType = CheckType.defaultType,
    this.needCompress = false,
  }) : super(showCheckReject: showCheckReject, onCheckPass: onCheckPass) {
    imgData = ImgData.fromFiles(files, needCompress: needCompress);
  }

  ImageCheckItem.fromBytes(
    List<U8ListWithPath> bytesList,
    this.channel, {
    Function(String text) showCheckReject,
    VoidCallback onCheckPass,
    this.checkType = CheckType.defaultType,
    this.needCompress = false,
  }) : super(showCheckReject: showCheckReject, onCheckPass: onCheckPass) {
    imgData = ImgData.fromBytes(bytesList, needCompress: needCompress);
  }

  @override
  String toString() {
    return 'ImageCheckItem{obj: ${imgData?.hashCode}   channel: $channel}';
  }

  String getFileSizeList() {
    final size = _tempImgData?.map((e) => e.fileSize)?.join();
    return size != null ? '【审核图片大小:%s】'.trArgs([size]) : '【为获取到图片大小】'.tr;
  }
}

class U8ListWithPath {
  final Uint8List uint8list;
  final String path;

  U8ListWithPath(this.uint8list, this.path);
}

///视频审核
///视频审核使用的不是类似数美这样的即时审核方式
///是通过在cdn上传视频后再由cdn审核，是一种异步的处理方式
///所以这个[VideoCheckItem]的相关方法会略不同于其他的Item
class VideoCheckItem extends CheckItem {
  final String url;

  ///0表示不通过，1表示通过
  final int useCachedCheckResult;

  @override
  Future<bool> startCheck({bool toastError = true}) async {
    if (useCachedCheckResult == VideoCheckResult.unPassed && isError(url))
      return false;
    final result = await http.head(Uri.parse(url));
    if (result.statusCode == HttpStatus.forbidden) {
      _addError(url);
      return false;
    }
    await Db.rejectVideoBox.put(url, VideoCheckResult.passed);
    return true;
  }

  VideoCheckItem.fromUrl(this.url,
      {this.useCachedCheckResult = VideoCheckResult.passed});

  ///记录审核不通过的视频[url]
  static final Set<String> _errorUrls = {};

  static bool isError(String url) {
    final localResult =
        Db.rejectVideoBox.get(url, defaultValue: VideoCheckResult.passed);
    return _errorUrls.contains(url) || localResult == VideoCheckResult.unPassed;
  }

  void _addError(String url) {
    Db.rejectVideoBox.put(url, VideoCheckResult.unPassed);
    _errorUrls.add(url);
  }

  @override
  String toString() {
    return 'VideoCheckItem{url: $url}';
  }
}

class VideoCheckResult {
  static const int unPassed = 0;
  static const int passed = 1;
}

class CheckRejectException implements Exception {
  MessageContentEntity errorMessage;
  MessageEntity entity;

  CheckRejectException.fromMessageContent(this.errorMessage);

  @override
  String toString() {
    return 'CheckRejectException{errorMessage: $errorMessage, entity: $entity}';
  }
}

class CheckTypeException extends DioError {
  final String errorMes;

  CheckTypeException(
    this.errorMes, {
    RequestOptions requestOptions,
    Response response,
    DioErrorType type = DioErrorType.cancel,
    error,
  }) : super(
            requestOptions: requestOptions,
            response: response,
            type: type,
            error: error);
}

enum CheckType { defaultType, circle }

bool isFriend(String channelId) {
  final userId = DirectMessageController.to.channels
      .firstWhere((element) => element.id == channelId, orElse: () => null)
      ?.guildId;
  if (userId == null) return false;
  return RelationUtils.getRelation(userId) == RelationType.friend;
}

bool isPrivateChat(String channelId) {
  return DirectMessageController.to.channels
          .indexWhere((element) => element.id == channelId) >
      -1;
}

String getTextChatChannel({String channelId}) {
  final isPrivate = channelId != null && isPrivateChat(channelId);
  final isFriendChat = isFriend(channelId);
  return isPrivate
      ? (isFriendChat
          ? TextChannelType.FRIEND_MESSAGE
          : TextChannelType.STRANGER_MESSAGE)
      : TextChannelType.GROUP_MESSAGE;
}

String getImageChatChannel({String channelId}) {
  final isPrivate = channelId != null && isPrivateChat(channelId);
  final isFriendChat = isFriend(channelId);
  return isPrivate
      ? (isFriendChat
          ? ImageChannelType.friendMessage
          : ImageChannelType.strangerMessage)
      : ImageChannelType.groupMessage;
}

bool beforeText(String channel, CheckType checkType) {
  bool result = true;
  switch (checkType) {
    case CheckType.defaultType:
      result = beforeDefaultTextCheck(channel);
      break;
    case CheckType.circle:
      result = beforeCircleTextCheck(channel);
      break;
  }
  return result;
}

bool beforeCircleTextCheck(String channel) {
  final bean = auditInfoBean?.permission?.circleChannelBean;
  if (bean == null) return true;
  return (bean.text ?? '1') == '1';
}

bool beforeDefaultTextCheck(String channel) {
  final bean = auditInfoBean?.permission;
  if (bean == null) return true;
  switch (channel) {
    case TextChannelType.STRANGER_MESSAGE:
      return (bean?.singleChatStranger?.text ?? '1') == '1';
      break;
    case TextChannelType.FRIEND_MESSAGE:
      return (bean?.singleChatFriend?.text ?? '1') == '1';
      break;
    case TextChannelType.GROUP_MESSAGE:
      return (bean?.publicChannelChat?.text ?? '1') == '1';
      break;
  }
  return true;
}

bool beforeImage(String channel, CheckType checkType) {
  bool result = true;
  switch (checkType) {
    case CheckType.defaultType:
      result = beforeDefaultImageCheck(channel);
      break;
    case CheckType.circle:
      result = beforeCircleImageCheck(channel);
      break;
  }
  return result;
}

bool beforeCircleImageCheck(String channel) {
  final bean = auditInfoBean?.permission?.circleChannelBean;
  if (bean == null) return true;
  return (bean.image ?? '1') == '1';
}

bool beforeDefaultImageCheck(String channel) {
  final bean = auditInfoBean?.permission;
  if (bean == null) return true;
  switch (channel) {
    case ImageChannelType.strangerMessage:
      return (bean?.singleChatStranger?.image ?? '1') == '1';
      break;
    case ImageChannelType.groupMessage:
      return (bean?.publicChannelChat?.image ?? '1') == '1';
      break;
    case ImageChannelType.friendMessage:
      return (bean?.singleChatFriend?.image ?? '1') == '1';
      break;
  }
  return true;
}
