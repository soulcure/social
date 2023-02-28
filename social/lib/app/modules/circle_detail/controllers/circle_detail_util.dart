import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_detail/entity/circle_detail_message.dart';
import 'package:im/app/modules/circle_detail/views/widget/image_video_view.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/db/db.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/global.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/circle_page.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/image_operator_collection/cached_image_refresher.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:tuple/tuple.dart';

/// * 圈子详情工具类
class CircleDetailUtil {
  static DateTime entryTime;

  static bool fromDmList(ExtraData extraData) {
    return extraData?.extraType == ExtraType.fromDmList;
  }

  static bool fromPush(ExtraData extraData) {
    return extraData?.extraType == ExtraType.fromPush;
  }

  static bool fromCircleList(ExtraData extraData) {
    return extraData?.extraType == ExtraType.fromCircleList;
  }

  /// * 圈子详情埋点-开始
  static void dLogStart({ExtraData extra}) {
    if (fromDmList(extra) || fromPush(extra) || fromCircleList(extra)) {
      exitCircleDetailEvent(
          visitSourcePage: fromDmList(extra)
              ? 'page_message_list'
              : (fromPush(extra) ? 'page_message_push' : 'page_circle_list'),
          isIn: true,
          extra: extra);
    }
  }

  /// * 圈子详情埋点-结束
  static void dLogEnd({ExtraData extra}) {
    if (fromDmList(extra) || fromPush(extra) || fromCircleList(extra)) {
      exitCircleDetailEvent(
          visitSourcePage: fromDmList(extra)
              ? 'page_message_list'
              : (fromPush(extra) ? 'page_message_push' : 'page_circle_list'),
          isIn: false,
          extra: extra);
    }
  }

  /// * 圈子详情埋点-浏览时长
  static void exitCircleDetailEvent(
      {String guildId,
      String postId,
      String visitSourcePage,
      bool isIn,
      ExtraData extra}) {
    int sec = 0;
    if (isIn)
      entryTime = DateTime.now();
    else
      sec = DateTime.now().difference(entryTime).inSeconds;

    int visitSourceParam = 0;
    if ((fromDmList(extra) || fromPush(extra)) &&
        extra.lastCircleType.hasValue) {
      visitSourceParam = getVisitSourceParam(extra.lastCircleType);
    }
    // debugPrint('getChat dlog guildId: $guildId');
    DLogManager.getInstance()
        .extensionEvent(logType: 'dlog_app_page_view_fb', extJson: {
      'visit_action_type': isIn ? 1 : 2,
      'page_catefory': 'page_circle',
      'page_id': 'page_circle_post',
      'page_param': postId ?? '',
      'visit_duration': sec,
      'guild_id': guildId ?? '',
      'visit_source_page': visitSourcePage,
      if (fromDmList(extra) || fromPush(extra))
        'visit_source_param': visitSourceParam,
    });
  }

  /// * 获取上报的 VisitSourceParam 参数值
  static int getVisitSourceParam(String lastCircleType) {
    int value = 0;
    switch (lastCircleType) {
      case 'post_at':
      case 'post_comment_at':
      case 'comment_comment_at':
        value = 2;
        break;
      case 'post_comment':
      case 'comment_comment':
        value = 3;
        break;
      case 'post_like':
      case 'comment_like':
        value = 4;
        break;
    }
    // debugPrint('getChat dlog visitSourceParam: $value - $lastCircleType');
    return value;
  }

  /// * 保存输入框记录
  static void updateInputRecord(String postId, String replyId, String value) {
    Db.textFieldInputRecordBox.put(
      postId,
      InputRecord(
        replyId: replyId,
        content: value,
      ),
    );
  }

  /// * 普通文本转成富文本
  static List<Map<String, dynamic>> content2Document(String content) {
    content = content.trim();
    final List<Operation> _operations = [];
    final match = TextEntity.atPattern.allMatches(content);
    if (match.isEmpty) {
      _operations.add(Operation.insert(content));
    } else {
      for (int i = 0; i < match.length; i++) {
        final element = match.elementAt(i);
        // 添加左边字符
        final leftStr = content.substring(
            i == 0 ? 0 : match.elementAt(i - 1).end, element.start);
        if (leftStr.isNotEmpty) _operations.add(Operation.insert(leftStr));
        // 添加at
        _operations
            .add(Operation.insert('', AtAttribute(element.group(0)).toJson()));
        // 添加右边字符
        if (i == match.length - 1) {
          final rightStr = content.substring(element.end, content.length);
          if (rightStr.isNotEmpty) _operations.add(Operation.insert(rightStr));
        }
      }
    }
    // 换行结尾
    if (!(_operations.last.value is String &&
        (_operations.last.value as String).endsWith('\n'))) {
      _operations.add(Operation.insert('\n'));
    }
    return _operations.map((e) => e.toJson()).toList();
  }

  /// * 图片转成富文本
  static Future<Tuple2<Document, Document>> image2Document(
      List<String> assets, bool thumb) async {
    List<Asset> assetList;
    final List<String> fileSizeList = [];
    try {
      assetList = await MultiImagePicker.requestMediaData(
          thumb: thumb, selectedAssets: assets);
      assetList.forEach((element) {
        fileSizeList.add("${File(element.filePath).lengthSync()}");
      });
    } catch (e) {
      logger.severe('image2Document requestMediaData error: $e');
    }

    final List<Embeddable> embedList = [], embedList2 = [];
    for (int i = 0; i < assetList.length; i++) {
      final e = assetList[i];
      final fileSize = double.parse(fileSizeList[i] ?? '0');
      if (fileSize > 1024 * 1024 * 100) {
        showToast('文件: %s 超出大小限制'.trArgs([e.name]));
        return null;
      }
      if (e?.filePath != null && e.fileType.startsWith('image/')) {
        final checkPath = e.checkPath.hasValue
            ? e.checkPath.substring(e.checkPath.lastIndexOf('/') + 1)
            : e.name;
        embedList.add(ImageEmbed(
          name: '',
          source: e.name,
          width: e.originalWidth,
          height: e.originalHeight,
          checkPath: checkPath,
        ));
        embedList2.add(ImageEmbed(
          name: '',
          source: '${Global.deviceInfo.thumbDir}${e.name}',
          width: e.originalWidth,
          height: e.originalHeight,
          checkPath: checkPath,
        ));
      }
    }
    try {
      return Tuple2(Document.fromJson(medias2OperationList(embedList)),
          Document.fromJson(medias2OperationList(embedList2)));
    } catch (e) {
      logger.severe('image2Document error: $e');
    }
    return null;
  }

  /// * ImageEmbed 转成 富文本格式
  static List<Map<String, dynamic>> medias2OperationList(
      List<Embeddable> embedList) {
    final List<Operation> _operations = [];
    embedList.forEach((element) {
      _operations.add(Operation.insert(element.toJson()));
      _operations.add(Operation.insert('\n'));
    });
    // 换行结尾
    if (!(_operations.last.value is String &&
        (_operations.last.value as String).endsWith('\n'))) {
      _operations.add(Operation.insert('\n'));
    }
    return _operations.map((e) => e.toJson()).toList();
  }

  /// 缓存圈子回复引用消息
  static final Map<String, CommentMessageEntity> _commentCacheMap = {};

  /// * 获取圈子的回复消息 - 用于引用类型
  static Future<CommentMessageEntity> getCommentMessage(
      String postId, String quoteId) async {
    ///第一步，从内存中读取
    CommentMessageEntity res = _commentCacheMap[quoteId];
    if (res != null) return res;

    final c = CircleDetailController.to(postId: postId, videoFirst: true);
    final res2 = c?.getCommentMessage(BigInt.parse(quoteId));
    if (res2 != null) return _commentCacheMap[quoteId] = res2;

    ///第二步，从服务端拿
    try {
      res = await CircleApi.getComment(postId, quoteId, topicId: c.topicId);
      if (res != null) {
        _commentCacheMap[quoteId] = res;
      } else {
        //返回空，表示已经被删除
        res = CommentMessageEntity();
        res.deleted = 1;
        _commentCacheMap[quoteId] = res;
      }
    } catch (_) {}
    return res;
  }

  /// * 删除回复消息后，deleted改为1
  static void deleteCommentFromCache(String id) {
    if (_commentCacheMap.containsKey(id)) {
      _commentCacheMap[id].deleted = 1;
    }
  }

  /// * 获取引用消息缓存的回复消息
  static CommentMessageEntity getCommentFromCache(String id) {
    return _commentCacheMap[id];
  }

  /// * 引用消息赋值
  static void setReplyMessage(MessageEntity message, MessageEntity reply) {
    if (reply != null) {
      if (reply.quoteL1.noValue && reply.quoteL2.noValue) {
        message.quoteL1 = reply.messageId;
      } else {
        final cacheComment = getCommentFromCache(reply.quoteL1);
        //检查引用消息是否被删除
        if (cacheComment.deleted == 1) {
          message.quoteL1 = reply.messageId;
        } else {
          message.quoteL1 = reply.quoteL1;
          message.quoteL2 = reply.messageId;
        }
      }
    }
  }

  /// * 提前加载图片，放入圈子图片缓存中
  static Future proLoadImage(List<ImageVideo> imageList) async {
    if (imageList.noValue) return;
    try {
      for (int i = 0; i < imageList.length; i++) {
        final srcUrl = imageList[i].getSrcUrl();
        if (srcUrl.noValue) return;
        final url = ContainerImage.getThumbUrl(srcUrl,
            thumbWidth: CircleController.circleThumbWidth);
        if (isLoadedImage(url)) return;
        final file = await CircleCachedManager.instance.getSingleFile(url);
        //加载成功后，加入 CachedImageRefresher 缓存中
        if (file != null) addLoadedImage(url);
      }
    } catch (_) {}
  }

  // * 提取图片主要颜色，用于背景展示
  // static void getImageMainColor(File file, ImageVideo item) {
  //   try {
  //     PaletteGenerator.fromImageProvider(
  //       Image.file(file, height: 100, width: 100).image,
  //       maximumColorCount: 2,
  //     ).then((p) {
  //       if (p?.paletteColors?.isNotEmpty ?? false) {
  //         item.bgColor1.value = p.paletteColors[0].color;
  //         if (p.paletteColors.length > 1)
  //           item.bgColor2.value = p.paletteColors[1]?.color;
  //         item.bgColor2.value ??= item.bgColor1.value;
  //         imageColorMap[item.getSrcUrl()] =
  //             Tuple2(item.bgColor1.value, item.bgColor2.value);
  //       }
  //     });
  //   } catch (_) {}
  // }

  /// * 订阅和取消订阅
  /// * flag: 1 关注，0 取消关注
  static Future<String> postFollow(
      String channelId, String postId, String flag) async {
    final res = await CircleApi.circleFollow(channelId, postId, flag)
        .catchError((e) {});
    if (res == null) return null;
    if (flag == '1') {
      unawaited(HapticFeedback.lightImpact());
    }
    return flag;
  }
}

//圈子图片的背景色缓存
// Map<String, Tuple2<Color, Color>> imageColorMap = {};
