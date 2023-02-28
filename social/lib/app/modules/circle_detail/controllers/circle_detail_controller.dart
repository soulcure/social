import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:fanbook_circle_detail_list/scrollable_positioned_list/item_positions_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/api/entity/circle_detail_list_bean.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/circle_post_data_model.dart';
import 'package:im/app/modules/circle/models/circle_post_data_type.dart';
import 'package:im/app/modules/circle/models/circle_post_user_data_model.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_util.dart';
import 'package:im/app/modules/circle_detail/entity/circle_detail_message.dart';
import 'package:im/app/modules/circle_detail/factory/abstract_circle_detail_factory.dart';
import 'package:im/app/modules/circle_detail/views/widget/circle_like_view.dart';
import 'package:im/app/modules/circle_detail/views/widget/image_video_view.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_page_controller.dart';
import 'package:im/app/modules/direct_message/controllers/direct_message_controller.dart';
import 'package:im/app/modules/task/introduction_ceremony/open_task_introduction_ceremony.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/list_extension.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/db/chat_db.dart';
import 'package:im/db/cicle_news_table.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/circle_page.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/common.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/menu_button/menu_button.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/menu_button/model.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/position_button_controller.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_item.dart';
import 'package:im/pages/home/json/text_chat_json.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/routes.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/disk_util.dart';
import 'package:im/utils/im_utils/channel_util.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/storage_util.dart';
import 'package:im/utils/tc_doc_utils.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/web/widgets/web_video_player/web_video_player.dart';
import 'package:im/ws/ws.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rxdart/rxdart.dart' as rx_stream;
import 'package:tuple/tuple.dart';

import '../../../../loggers.dart';

///圈子动态详情页-参数对象
class CircleDetailData {
  CirclePostDataModel circlePostDataModel;
  final ExtraData extraData;
  final Function(Map info) modifyCallBack;
  bool toComment;
  final String topicName;

  ///圈子消息-顶部定位对象
  CirclePostNewsPositionObj topPositionObj;

  ///沉浸式视频使用
  final List<CirclePostDataModel> circlePostDataModels;
  final String circleListTopicId;

  ///页面关闭时调用
  final Function(Object data) onBack;

  CircleDetailData(
    this.circlePostDataModel, {
    this.extraData,
    this.modifyCallBack,
    this.toComment = false,
    this.topicName = '',
    this.topPositionObj,
    this.circlePostDataModels,
    this.circleListTopicId,
    this.onBack,
  });

  String get postId =>
      circlePostDataModel?.postInfoDataModel?.postId ?? extraData?.postId;
}

///圈子动态详情页-Controller
class CircleDetailController extends GetxController
    with GetTickerProviderStateMixin {
  /// * 获取 CircleDetailController
  /// * videoFirst：沉浸式页面使用时为true，优先获取
  static CircleDetailController to({String postId, bool videoFirst = false}) {
    CircleDetailController c;
    try {
      final videoTag = '$postId$VideoTag';
      if (videoFirst &&
          Get.isRegistered<CircleDetailController>(tag: videoTag)) {
        c = Get.find<CircleDetailController>(tag: videoTag);
      }
      c ??= Get.find<CircleDetailController>(tag: postId);
    } catch (_) {}
    return c;
  }

  ///沉浸式视频加载Controller的Tag值
  static const String VideoTag = 'video';
  static int idLikeView = 2;

  final CircleDetailData circleDetailData;

  /// * 沉浸式视频的tag
  final String videoTag;

  /// * 沉浸式视频 tabController
  TabController tabController;
  PinNotifier pinNotifier;
  ScrollController scrollController;

  /// 列表顶部和底部 UI 的 key，用来计算内容是否超出了列表最大高度，即可滚动
  /// 本来通过 ScrollController 是可以算出来的，不过这里要求在列表尺寸变化前计算
  /// 此时 ScrollController 取出的 dimension 是不够即时的，因此使用 RenderObject 计算
  GlobalKey topUiKey = GlobalKey();
  GlobalKey bottomUiKey = GlobalKey();

  /// item1 是键盘展开的列表高度
  double listMaxViewportDimension = 0;

  /// item2 是键盘收起的列表高度
  double listMinViewportDimension = double.infinity;

  BottomPositionController brController;
  TopPositionController trController;

  /// * 滚动后是否可以更新
  /// * false：防止滚动触发了列表样式修改和加载上一页下一页
  bool isUpdateByScroll = false;

  ///跳转到某条回复时，展示动画的回复ID
  String jumpTargetId;
  Rx<Color> jumpAnimColor = Colors.white.obs;

  /// * 圈子所属的频道 (guildCircle)
  ChatChannel channel;

  /// * 圈子动态消息频道 (circlePostNews)
  ChatChannel postChannel;

  final RefreshController refreshController = RefreshController();

  /// * 回复总数-String
  String get totalReplyNum => data?.postSubInfoDataModel?.commentTotal ?? '0';

  /// * 回复总数
  int get totalReplySize => int.parse(totalReplyNum);

  /// * [_list]的回复数量
  int get bottomListSize => _list.length;

  /// * 当前回复列表 size
  int get replySize => dataIsCommon ? _list.length : _middleList.length;

  /// * 界面显示的列表size: replySize + headerSize + 菊花
  int get itemCount => replySize + headerSize + 1;

  String get guildId => data?.postInfoDataModel?.guildId ?? extraData?.guildId;

  /// * 圈子频道ID (guildCircle)
  String get channelId =>
      data?.postInfoDataModel?.channelId ?? extraData?.channelId;

  String get topicId => data?.postInfoDataModel?.topicId ?? extraData?.topicId;

  String get postId =>
      data?.postInfoDataModel?.postId ?? extraData?.postId ?? '';

  String get title => data?.postInfoDataModel?.title ?? '';

  String get content => data?.postInfoDataModel?.content ?? '';

  String get contentV2 => data?.postInfoDataModel?.contentV2 ?? '';

  String get postType => data?.postInfoDataModel?.postType ?? '';

  String get listId => circleDetailBean?.listId ?? '';

  ///回复列表-每页多少
  final pageSize = 50;

  ///回复列表-头部长度(包括标题内容、喜欢、回复总数)
  final headerSize = 1;

  int get totalLikeNum {
    try {
      return int.parse(totalLikes);
    } catch (e) {
      return 0;
    }
  }

  String get totalLikes => data?.postSubInfoDataModel?.likeTotal ?? '';

  /// * 点赞列表状态
  LikeStatus likeStatus = LikeStatus.Expand;

  /// * 点赞列表显示的个数
  int likeShowSize = 0;

  String get postContent {
    if (postType.isEmpty) {
      return content;
    } else if (postType == CirclePostDataType.article ||
        postType == CirclePostDataType.image ||
        postType == CirclePostDataType.video) {
      return contentV2;
    } else {
      return null;
    }
  }

  bool get postTypeAvailable =>
      data?.postInfoDataModel?.postTypeAvailable ?? false;

  bool get likeByMyself => data?.postSubInfoDataModel?.iLiked == '1';

  ///当关闭当前页面时，pop返回的结果
  bool needRefreshWhenPop = false;

  ///onBack方法的参数
  int onBackResult = 0;

  ///动态的数据
  CirclePostDataModel data;

  ///来自跳转页面的参数
  ExtraData extraData;

  ///页面初始化中
  bool initialing = true;

  ///加载动态内容是否失败
  bool initialError = false;

  ///加载动态的错误码：0 正常
  int requestCode = 0;

  ///加载或跳转回复列表中
  bool isLoading = false;

  ///回复列表-到最后一条了
  bool get reachEnd => footerMode?.value == LoadStatus.noMore;

  ///回复列表-到第一条了
  bool get reachStart => headerMode?.value == LoadStatus.noMore;

  ///楼主内容被转换后的数据
  List<Operation> contentList;

  CirclePostUserDataModel get headUser => data?.userDataModel;

  ///是否关注
  bool get isFollow => data?.postSubInfoDataModel?.isFollow ?? false;

  CircleDetailBean circleDetailBean;
  QuillController quillController;

  /// * 内容中的图片视频列表
  List<ImageVideo> imageVideoList = [];

  /// * 底部未显示的消息数
  int numBottomInvisible;

  /// * 可视范围内的顶部索引
  int topIndex;

  /// * 可视范围内的底部索引：回复看不到时为空
  int bottomIndex;

  /// * 列表初始化索引
  int initialIndex = 0;

  /// * 列表初始化方向: 从上; 从下
  double initialAlignment = 0;

  ValueKey<int> listKey = const ValueKey(0);
  ItemPositionsNotifier itemPositionsNotifier;

  ///回复列表-底部加载状态
  RefreshNotifier<LoadStatus> footerMode = RefreshNotifier(LoadStatus.noMore);

  ///回复列表-顶部加载状态
  RefreshNotifier<LoadStatus> headerMode = RefreshNotifier(LoadStatus.noMore);

  /// * 数据是否普通模式:
  /// * true 默认 使用 [_list] ;
  /// * false 艾特跳转到列表中间页，列表数据使用 [_middleList]
  bool dataIsCommon = true;

  ///是否从消息列表跳转过来
  bool get fromDmList => extraData?.extraType == ExtraType.fromDmList;

  ///是否从push跳转过来
  bool get fromPush => extraData?.extraType == ExtraType.fromPush;

  /// * 是否从圈子列表跳转过来
  bool get fromCircleList => extraData?.extraType == ExtraType.fromCircleList;

  /// 判断列表内容在键盘收起时的有没有超出，没有超出时列表不需要滚动
  bool listContentExceedKeyboardlessViewport(double compare) {
    if (topUiKey.currentContext == null || bottomUiKey.currentContext == null)
      return true;

    final topBox = topUiKey.currentContext.findRenderObject() as RenderBox;
    if (topBox == null) return true;

    final bottomBox =
        bottomUiKey.currentContext.findRenderObject() as RenderBox;
    if (bottomBox == null) return true;

    final contentHeight =
        bottomBox.localToGlobal(Offset(0, bottomBox.size.height)).dy -
            topBox.localToGlobal(Offset.zero).dy;

    return contentHeight > compare;
  }

  /// * 右上角菜单model
  MenuButtonModel menuModel;

  //输入框的key
  GlobalKey inputKey = GlobalKey();

  /// * 回复列表list
  final SplayTreeMap<BigInt, CommentMessageEntity> _list = SplayTreeMap();

  /// * 回复列表-中间页list
  final SplayTreeMap<BigInt, CommentMessageEntity> _middleList = SplayTreeMap();

  /// 回复列表数据
  List<CommentMessageEntity> get replyList => dataIsCommon
      ? _list.values.toList(growable: false)
      : _middleList.values.toList(growable: false);

  List<CommentMessageEntity> get bottomList =>
      _list.values.toList(growable: false);

  /// 中间区域高度: Get.height - (顶部高度 + 底部高度)
  double scrollHeight = Get.height - 153;

  bool get replyListIsEmpty =>
      dataIsCommon ? _list.isEmpty : _middleList.isEmpty;

  /// * 圈子回复的事件流
  final rx_stream.PublishSubject eventStream = rx_stream.PublishSubject();

  /// * 是否已经订阅ws推送
  bool isJoinWs = false;
  StreamSubscription _wsSubscription;

  /// * 图片轮播的索引
  RxInt imageIndex = 0.obs;

  /// * Controller的tag
  String tag;

  ///回复列表是否加载完成
  Completer hasInitialized;

  /// * 是否显示加载态
  RxBool showLoading = false.obs;

  /// * 是否显示蒙层(键盘或其他弹起时)
  RxBool showLayer = false.obs;

  /// * 圈子内容(非空)
  String get circleContent =>
      data?.postInfoDataModel?.postContent() ??
      RichEditorUtils.defaultDoc.encode();

  CircleDetailController(this.circleDetailData, {this.videoTag = ''}) {
    tag = '${circleDetailData.postId}$videoTag';
    brController = BottomPositionController.to(tagId: tag);
    trController = TopPositionController.to(
        obj: circleDetailData.topPositionObj, tagId: tag);
    hasInitialized ??= Completer();
  }

  StreamSubscription<bool> _keyboardSubscription;

  @override
  void onInit() {
    pinNotifier = PinNotifier(initialIndex > 0);
    scrollController = ScrollController();
    itemPositionsNotifier = ItemPositionsNotifier();

    _changeListAlignmentAsKeyboardSwitch();

    super.onInit();
    _init();
  }

  @override
  void onClose() {
    _keyboardSubscription.cancel();
    itemPositionsNotifier.itemPositions.dispose();
    scrollController.dispose();
    pinNotifier.dispose();
    sendWsMessage(0);
    callOnBack();
    CircleDetailUtil.dLogEnd(extra: extraData);
    eventStream?.close();
    _close();
    if (!needRefreshWhenPop) {
      final replySame =
          totalReplyNum == data?.postSubInfoDataModel?.commentTotal;
      final likeSame = totalLikes == data?.postSubInfoDataModel?.likeTotal;
      if (!replySame || likeSame) needRefreshWhenPop = true;
    }
    Get.delete<BottomPositionController>(tag: tag);
    Get.delete<TopPositionController>(tag: tag);
    tabController?.dispose();
    _wsSubscription?.cancel();
    AbstractCircleDetailFactory.destroy();
    ChannelUtil.instance.upLastReadSend();
    super.onClose();
  }

  void updateListViewDimension(double maxHeight) {
    listMinViewportDimension = min(listMinViewportDimension, maxHeight);
    listMaxViewportDimension = max(listMaxViewportDimension, maxHeight);
  }

  void _changeListAlignmentAsKeyboardSwitch() {
    _keyboardSubscription =
        KeyboardVisibilityController().onChange.listen((visible) async {
      int newIndex = initialIndex;
      double newAligment = initialAlignment;

      // 此监听器和 UI 做出响应之间存在间隔
      if (listMinViewportDimension == listMaxViewportDimension) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // 键盘弹出时
      if (visible) {
        // 如果内容本来就超出键盘隐藏时的高度，那肯定超出键盘显示时的高度
        if (listContentExceedKeyboardlessViewport(listMaxViewportDimension)) {
          // 如果列表到底部了，键盘弹出时，列表依然在底部
          if (bottomIndex == replySize - 1) {
            newIndex = itemCount - 1;
            newAligment = 1;
          }
        }
        // 如果内容在键盘收起时没有超出，那要判断键盘展开时是否超出
        else {
          if (listContentExceedKeyboardlessViewport(listMinViewportDimension)) {
            newIndex = itemCount - 1;
            newAligment = 1;
          }
        }
      }
      // 键盘收回时
      else {
        if (!listContentExceedKeyboardlessViewport(listMaxViewportDimension)) {
          newIndex = 0;
          newAligment = 0;
        }
      }

      if (newIndex != initialIndex || newAligment != initialAlignment) {
        // 使用 jumpTo 消耗掉物理惯性
        scrollController.jumpTo(0);
        initialIndex = newIndex;
        initialAlignment = newAligment;
        update();
      }
    });
  }

  Future _init() async {
    _initNew();
    if (videoTag.hasValue) _initVideo();
    CircleDetailUtil.dLogStart(extra: extraData);
    if (fromCircleList) {
      //从圈子列表进来，延迟网络请求调用，防止动画掉帧
      await Future.delayed(400.milliseconds);
    }
    await refreshAll();
    onWsConnect();
  }

  void _initNew() {
    data = circleDetailData?.circlePostDataModel;
    extraData = circleDetailData?.extraData;
    channel = ChatChannel(
      guildId: guildId,
      id: topicId,
      type: ChatChannelType.guildCircle,
      recipientId: postId,
    );
    ChannelUtil.instance.putCircleChannelInMemory(channel);
    likeShowSize = min(totalLikeNum, likeInitSize);
    //从私信列表或push跳转进来，显示加载圈圈
    if (fromDmList || fromPush) showLoading.value = true;

    needRefreshWhenPop = false;
    _setQuillController();
  }

  /// 获取最终显示的富文本内容 和 顶部轮播图片
  void _setQuillController() {
    final decodeContent = _getDecodeContent(circleContent);

    ///判断内容是否为空
    if (decodeContent == null ||
        decodeContent.isEmpty ||
        (decodeContent.length == 1 && decodeContent[0]['insert'] == '')) {
      logger.info('circle content empty');
      quillController = null;
    } else {
      quillController = QuillController(
          document: getDocument(decodeContent),
          selection: const TextSelection.collapsed(offset: 0));
    }
  }

  ///解析动态内容，并找到其中的图片视频
  List _getDecodeContent(String content) {
    List list = jsonDecode(content);
    if (postType == CirclePostDataType.image ||
        postType == CirclePostDataType.video ||
        postType == CirclePostDataType.article) {
      final tuple2 = _getRichImageList(content);
      imageVideoList = tuple2.item2;
      list = tuple2.item1;
    }
    return list;
  }

  Tuple2<List, List<ImageVideo>> _getRichImageList(String content) {
    final List listAll = jsonDecode(content);
    final richList = [];
    final List<ImageVideo> imageOrVideoList = [];
    //是否有内容(非换行)
    bool hasValue = false;
    listAll.forEach((e) {
      final bool isMedia = e['insert'] is Map && e['insert']['_type'] != null;
      if (isMedia) {
        ///顶部图片或者视频，最多显示9张
        if (imageOrVideoList.length < 9)
          imageOrVideoList.add(ImageVideo.fromJson(e['insert']));
        if (postType == CirclePostDataType.article) {
          hasValue = true;
          richList.add(e);
        }
      } else {
        if (!hasValue && (e is! Map || e['insert'] != '\n')) {
          hasValue = true;
        }
        richList.add(e);
      }
    });
    return Tuple2(hasValue ? richList : null, imageOrVideoList);
  }

  Document getDocument(List decodeContentList) {
    final contentJson = List<Map<String, dynamic>>.from(decodeContentList);
    //旧版动态有链接属性a时，需要处理
    RichEditorUtils.transformAToLink(contentJson);
    Document document;
    try {
      // 结尾需要有换行
      final last = contentJson.last['insert'];
      if (!(last is String && last.endsWith('\n'))) {
        contentJson.add({'insert': '\n'});
      }
      document = Document.fromJson(contentJson);
    } catch (e, s) {
      logger.severe('圈子详情页解析错误', e, s);
      document = RichEditorUtils.defaultDoc;
    }
    return document;
  }

  /// * 加载动态内容和评论列表
  /// * showLoading: 是否显示加载态
  Future refreshAll({bool showLoadingStatus = false}) async {
    initialing = true;
    if (showLoadingStatus) {
      initialError = false;
      showLoading.value = true;
      update();
    }
    await refreshContent();
    if (!initialError) {
      setPostChannel();
      sendWsMessage(1);
      await loadList(isInit: initialing);
    } else {
      _hideLoading();
      update();
    }
    initialing = false;
    if (!initialError) {
      if (fromDmList || fromPush) {
        doFromDmList();
      } else {
        doFromCommon();
      }
    }
  }

  /// * 长按图片-显示保存图片选项
  Future onLongPressImage(ImageVideo indexItem) async {
    final List<String> items = ['保存图片'.tr];
    final index = await showCustomActionSheet(items.map((e) {
      return Text(e, style: appThemeData.textTheme.bodyText2);
    }).toList());
    if (index == null) return;
    if (index == 0) {
      if (await DiskUtil.availableSpaceGreaterThan(200)) {
        unawaited(saveGalleryImage(indexItem));
      } else {
        final bool isConfirm = await showConfirmDialog(
          title: '存储空间不足，清理缓存可释放存储空间'.tr,
        );
        if (isConfirm != null && isConfirm == true) {
          unawaited(Routes.pushCleanCachePage(Get.context));
        }
      }
    }
  }

  /// * 保存图片到本地
  Future<void> saveGalleryImage(ImageVideo item) async {
    final permission = await checkSystemPermissions(
      context: Get.context,
      permissions: [
        if (UniversalPlatform.isIOS) Permission.photos,
        if (UniversalPlatform.isAndroid) Permission.storage
      ],
    );
    if (permission != true) return;
    await saveImageToLocal(localFilePath: "", url: item.getSrcUrl());
  }

  /// * 点击视频-点击跳转沉浸式
  Future onTapVideo(ImageVideo indexItem) async {
    if (indexItem.sType == 'video') {
      final source = indexItem.source;
      final vList = imageVideoList.where((e) => e.sType == 'video').toList();
      final offsetIndex = vList.indexWhere((e) {
        return e.source == source;
      });
      unawaited(Routes.pushCircleVideo(
        Get.context,
        CircleVideoPageControllerParam(
          model: data,
          offset: max(offsetIndex, 0),
          topicId: circleDetailData?.circleListTopicId,
          circlePostDateModels: circleDetailData?.circlePostDataModels,
        ),
      ));
    }
  }

  /// * 从服务端获取最新的内容
  Future refreshContent() async {
    try {
      data = await getModelFromNet(topicId, channelId, postId);
      channel.id = topicId;
      channel.guildId = guildId;
      channel.recipientId = postId;
      ChannelUtil.instance.putCircleChannelInMemory(channel);
      menuModel = MenuButtonModel(
        data: data,
        onRequestSuccess: onRequestSuccess,
        onRequestError: (code, type) {
          onRequestError(RequestArgumentError(code), Get.context,
              deletePost: true);
        },
        updateLoading: update,
      );

      likeShowSize = min(totalLikeNum, likeInitSize);

      _setQuillController();

      initialError = false;
    } catch (e) {
      logger.severe('load circle content error: $e');
      initialError = true;
      if (e is RequestArgumentError && postIsDelete(e.code)) {
        postInfoMap[postId]?.setData(deleted: true);
        requestCode = e.code;
        needRefreshWhenPop = true;
      }
    }
  }

  /// * 订阅/取消订阅-该动态的ws消息
  /// * join: 1 订阅; 0 取消订阅
  void sendWsMessage(int join) {
    if (initialError) return;

    /// 沉浸式视频-回复列表-暂时不做IM功能
    if (videoTag.hasValue) return;
    if (join == 1 && isJoinWs) return;
    final msg = {
      "action": 'circlePost',
      "post_id": postId,
      "join": join,
      "channel_id": channelId,
    };
    try {
      Ws.instance.send(msg).then((value) {
        isJoinWs = true;
      });
    } catch (e) {
      logger.severe('ws send circlePost error: $e');
    }
  }

  /// * 监听ws的连接状态：重连后需要重新发送订阅通知
  void onWsConnect() {
    /// 沉浸式视频-回复列表-暂时不做IM功能
    if (videoTag.hasValue) return;
    _wsSubscription?.cancel();
    _wsSubscription = Ws.instance.on().listen((event) async {
      if (event is Connected) {
        isJoinWs = false;
        sendWsMessage(1);
      }
    });
  }

  /// * 发送文本
  /// * 文本转成富文本格式
  Future<void> sendText(String text, {MessageEntity reply}) async {
    CommentMessageEntity message;
    RichTextEntity richTextEntity;
    try {
      if (text.length > 5000) {
        showToast('回复内容的长度超出限制'.tr);
        return;
      }
      final oList = CircleDetailUtil.content2Document(text);
      final doc = Document.fromJson(oList);
      richTextEntity = RichTextEntity(document: doc);
      richTextEntity.deferredEnterWaitingState();
      final localId = ChatTable.generateLocalMessageId(null);
      message = CommentMessageEntity(
        topicId: topicId,
        postId: postId,
        commentId: localId,
        guildId: guildId,
        userId: Global.user.id,
        time: DateTime.now(),
        content: richTextEntity,
        contentType: CommentType.richText,
      );

      CircleDetailUtil.setReplyMessage(message, reply);

      addCommentMessage(message, addToList: true);
      final isUpdateUI = jumpToBottom(delay: 100.milliseconds);
      if (!isUpdateUI) update();

      final passed = await _checkText(text);
      if (!passed) throw CheckTypeException(defaultErrorMessage);

      final res = await CircleApi.createComment(guildId, channelId, topicId,
          doc.encode(), postId, message.quoteL1, message.quoteL2,
          mentions: richTextEntity.mentions?.item2, contentType: 'richText');
      //发送成功后，更新ID和时间
      message.setCommentId(res['comment_id'] as String);
      message.time = timeFromJson(res);
      message.content.messageState = MessageState.sent.obs;
      updateCommentMessage(BigInt.parse(localId), message);
    } on CheckTypeException catch (_) {
      message.content.messageState = MessageState.sent.obs;
      message.localStatus = MessageLocalStatus.illegal;
      logger.severe("getChat sendText check reject", e);
    } catch (e) {
      message?.content?.messageState?.value = MessageState.timeout;
      logger.severe("getChat sendText Error", e);
    }
    update();

    saveAtUser(richTextEntity);
  }

  /// * 上报检查文本
  Future<bool> _checkText(String text) async {
    final checkText = text.replaceAll(TextEntity.atPattern, '');
    final passed = await CheckUtil.startCheck(
        TextCheckItem(checkText, TextChannelType.FB_CIRCLE_POST_COMMENT,
            checkType: CheckType.circle),
        toastError: false);
    return passed;
  }

  /// * 发送图片
  /// * 图片也转富文本格式
  Future<void> sendImages(List<String> identifier, bool thumb,
      {MessageEntity reply}) async {
    CommentMessageEntity message;
    RichTextEntity richTextEntity;
    Tuple2<Document, Document> tuple2;
    try {
      tuple2 = await CircleDetailUtil.image2Document(identifier, thumb);
      if (tuple2 == null) return;
      richTextEntity = RichTextEntity(document: tuple2.item2);
      richTextEntity.deferredEnterWaitingState();
      final localId = ChatTable.generateLocalMessageId(null);

      message = CommentMessageEntity(
        topicId: topicId,
        postId: postId,
        commentId: localId,
        guildId: guildId,
        userId: Global.user.id,
        time: DateTime.now(),
        content: richTextEntity,
        contentType: CommentType.image,
      );
      CircleDetailUtil.setReplyMessage(message, reply);

      addCommentMessage(message, addToList: true);
      final isUpdateUI = jumpToBottom(delay: 200.milliseconds);
      if (!isUpdateUI) update();

      //图片送审
      await RichEditorUtils.uploadFileInDoc(tuple2.item1);
      final content = Document.fromJson(
          CircleDetailUtil.content2Document('当前版本暂不支持查看此回复类型'.tr));
      final res = await CircleApi.createComment(guildId, channelId, topicId,
          content.encode(), postId, message.quoteL1, message.quoteL2,
          mentions: richTextEntity.mentions?.item2,
          contentV2: tuple2.item1.encode(),
          contentType: 'image');
      message.content = RichTextEntity(document: tuple2.item1);
      message.content.messageState = MessageState.sent.obs;
      message.setCommentId(res['comment_id'] as String);
      message.time = timeFromJson(res);
      updateCommentMessage(BigInt.parse(localId), message);
    } on CheckTypeException catch (_) {
      message.content.messageState = MessageState.sent.obs;
      message.localStatus = MessageLocalStatus.illegal;
      logger.severe("getChat sendImages check reject", e);
    } catch (e) {
      message.content.messageState = MessageState.timeout.obs;
      message.tuple2 = tuple2;
      logger.severe("getChat sendImages Error", e);
    }
    update();
  }

  /// * 重发回复
  Future<void> resend(CommentMessageEntity message) async {
    RichTextEntity richTextEntity;
    try {
      final localId = message.messageIdBigInt;
      Map res;
      if (message.contentType == CommentType.richText) {
        richTextEntity = message.content as RichTextEntity;
        richTextEntity.deferredEnterWaitingState();
        final doc = richTextEntity.document;
        final text = doc.toPlainText();
        final passed = await _checkText(text);
        if (!passed) throw CheckTypeException(defaultErrorMessage);
        res = await CircleApi.createComment(guildId, channelId, topicId,
            doc.encode(), postId, message.quoteL1, message.quoteL2,
            mentions: richTextEntity.mentions?.item2, contentType: 'richText');
      } else if (message.contentType == CommentType.image) {
        richTextEntity = message.content as RichTextEntity;
        richTextEntity.deferredEnterWaitingState();
        final tuple2 = message.tuple2;
        await RichEditorUtils.uploadFileInDoc(tuple2.item1);
        final content = Document.fromJson(
            CircleDetailUtil.content2Document('当前版本暂不支持查看此回复类型'.tr));
        res = await CircleApi.createComment(guildId, channelId, topicId,
            content.encode(), postId, message.quoteL1, message.quoteL2,
            mentions: richTextEntity.mentions?.item2,
            contentV2: tuple2.item1.encode(),
            contentType: 'image');
      }

      if (res != null) {
        //发送成功后，更新ID、时间、状态
        message.setCommentId(res['comment_id'] as String);
        message.time = timeFromJson(res);
        message.content.messageState = MessageState.sent.obs;
        updateCommentMessage(localId, message);
      }
    } on CheckTypeException catch (_) {
      message.content.messageState = MessageState.sent.obs;
      message.localStatus = MessageLocalStatus.illegal;
      logger.severe("getChat resend check reject", e);
    } catch (e) {
      message?.content?.messageState?.value = MessageState.timeout;
      logger.severe("getChat resend error", e);
    }
    update();

    saveAtUser(richTextEntity);
  }

  /// * 保存艾特的ID
  void saveAtUser(RichTextEntity richTextEntity) {
    if (richTextEntity != null) {
      try {
        if (richTextEntity?.mentions?.item2 != null) {
          ChannelUtil.instance
              .addGuildAtUserId(guildId, richTextEntity.mentions.item2);
        }
      } catch (_) {}
    }
  }

  /// * 跳转到列表底部
  bool jumpToBottom({Duration delay = Duration.zero}) {
    if (!dataIsCommon) {
      dataIsCommon = true;
      setLoadStatus(footer: LoadStatus.noMore);
      return true;
    }

    void jump() {
      if (listContentExceedKeyboardlessViewport(
          scrollController.position.viewportDimension)) {
        jumpToIndex(replySize + 1, 1);
      }
    }

    if (delay == null || delay == Duration.zero)
      jump();
    else
      Future.delayed(delay, jump);
    return false;
  }

  void jumpToIndex(int index, double alignment) {
    listKey = ValueKey(listKey.value + 1);
    initialIndex = index;
    initialAlignment = alignment;
    update();
  }

  /// * 设置向下或向上的加载状态
  void setLoadStatus({LoadStatus header, LoadStatus footer}) {
    if (header != null) {
      if (header == LoadStatus.noMore) {
        pinNotifier.enabled = false;
        pinNotifier.value = false;
      }
      headerMode.value = header;
    }
    if (footer != null) footerMode.value = footer;
  }

  /// * 从服务端加载: 回复列表 (按时间升序)
  /// * loadMore: true 向下 ；false 向上
  /// * isInit: 是否初始化加载
  Future loadList({bool loadMore = false, bool isInit = false}) async {
    if (isLoading) return;
    initialAlignment = 0;
    isLoading = true;
    setLoadStatus(
      header: loadMore ? null : LoadStatus.loading,
      footer: loadMore ? LoadStatus.loading : null,
    );
    if (!isInit) update();

    try {
      String requestListId = '0';
      if (!isInit && !replyListIsEmpty) {
        requestListId =
            loadMore ? replyList.last.commentId : replyList.first.commentId;
      }
      final dataList = await getCommentListV2(
          behavior: loadMore, requestCommentId: requestListId);
      if (isInit) _list.clear();
      addCommentMessageList(dataList);
      if (isInit) hasInitialized.complete();

      /// 根据返回列表模式和数量，设置加载状态
      if (loadMore) {
        if (dataList.length < pageSize) {
          setLoadStatus(footer: LoadStatus.noMore);
        } else {
          setLoadStatus(footer: LoadStatus.loading);
        }
        //向下加载时，如果和_list有交集，则合并为一个
        if (!dataIsCommon) {
          final firstItem = _list[_list.firstKey()];
          if (replyList.last.messageIdBigInt >= firstItem.messageIdBigInt) {
            dataIsCommon = true;
            mergeList();
          }
        }
      } else {
        if (dataList.length < pageSize) {
          setLoadStatus(header: LoadStatus.noMore);
        } else {
          // if (isInit && (fromDmList || fromPush)) listIsCommon = false;
          setLoadStatus(header: LoadStatus.loading);
        }
      }

      /// 设置索引和对齐
      if (!isInit && dataList.isNotEmpty) {
        if (!loadMore) {
          initialIndex = dataList.length + headerSize;
          listKey = ValueKey(listKey.value + 1);
        }
      }

      /// 沉浸式：第一次进来，数量不小于10，定位在底部
      if (isInit && videoTag.hasValue && dataList.length >= 10) {
        initialIndex = itemCount - 1;
        initialAlignment = 1;
        listKey = ValueKey(listKey.value + 1);
      }
    } catch (e, s) {
      logger.severe('回复列表加载错误:$e', s);
      if (loadMore) {
        setLoadStatus(footer: LoadStatus.failed);
      } else {
        setLoadStatus(header: LoadStatus.failed);
      }
    }
    isLoading = false;
    update();
  }

  /// * 删除回复
  Future<void> deleteComment(CommentMessageEntity message) async {
    try {
      if (message.isNormal)
        await CircleApi.deleteReply(message.commentId, postId, '1');
      removeCommentMessage(message);

      if (videoTag.hasValue) {
        //沉浸式删除回复：如果该动态的圈子详情也打开，需要同步删除
        final otherC = CircleDetailController.to(postId: message.postId);
        if (otherC?.postId == postId) otherC.removeCommentMessage(message);
      }
    } catch (e) {
      if (e is RequestArgumentError && postIsDelete(e.code)) {
        removeCommentMessage(message);
      }
    }
  }

  ///从服务端获取回复列表
  Future<List<CommentMessageEntity>> getCommentListV2(
      {bool behavior = true, String requestCommentId}) async {
    final list = await CircleApi.getCommentListV2(channelId, postId, pageSize,
        commentId: requestCommentId,
        topicId: topicId,
        behavior: behavior,
        showToast: false);
    return list;
  }

  ///从服务端获取-跳转的回复列表
  Future<Tuple3<List<CommentMessageEntity>, int, int>> getAroundCommentListV2(
          String requestCommentId) async =>
      CircleApi.getAroundCommentListV2(channelId, postId, requestCommentId,
          topicId: topicId, showToast: false);

  ///关闭页面时的操作
  void callOnBack() {
    if (circleDetailData != null && circleDetailData.onBack != null) {
      if (fromDmList) {
        if (postIsDelete(requestCode)) {
          circleDetailData.onBack(11);
        } else if (onBackResult > 0) {
          circleDetailData.onBack(onBackResult);
        } else {
          circleDetailData.onBack(data);
        }
      } else {
        circleDetailData.onBack(data);
      }
      return;
    }

    if (fromCircleList && needRefreshWhenPop) {
      Future.delayed(const Duration(milliseconds: 300)).then((_) {
        try {
          if (postIsDelete(requestCode)) {
            CircleController.to.removeItem(topicId, postId);
          } else {
            CircleController.to
              ..updateItem(topicId, data)
              ..updateSubscriptionItem(data);
          }
        } catch (_) {}
      });
    }
  }

  void _close() {
    if (OrientationUtil.landscape) clearVideoCache();
    final likeTotal = totalLikeNum.toString();
    final liked = likeByMyself;
    final commentTotal = totalReplyNum;
    final content = postContent ?? RichEditorUtils.defaultDoc.encode();
    final postInfo = postInfoMap[postId];
    if (postInfo == null) {
      postInfoMap[postId] = PostInfo(
        ValueNotifier(commentTotal),
        ValueNotifier(likeTotal),
        ValueNotifier(title),
        ValueNotifier(content),
        ValueNotifier(liked),
        ValueNotifier(false),
        postId,
        followListener: ValueNotifier(isFollow),
      );
    } else
      Future.delayed(
          const Duration(milliseconds: 200),
          () => postInfo.setData(
                commentTotal: commentTotal,
                liked: liked,
                likeTotal: likeTotal,
                followed: isFollow,
              ));
  }

  ///右上角按钮点击后的回调；编辑动态，删除动态等
  void onRequestSuccess(MenuButtonType type, {List param}) {
    if (type == MenuButtonType.del) {
      if (fromDmList) {
        onBackResult = 12;
        Get.back();
      } else {
        needRefreshWhenPop = true;
        Get.back();
      }
    } else {
      circleDetailData?.modifyCallBack
          ?.call({"refresh": "true", "modify_type": type.toString()});
      needRefreshWhenPop = true;
      if (type == MenuButtonType.modify) {
        refreshContent();
      } else if (type == MenuButtonType.modifyTopic) {
        /// 修改所属频道
        if (param != null && param.isNotEmpty) {
          data?.postInfoDataModel?.topicId = param[0] as String;
          data?.postInfoDataModel?.topicName = param[1] as String;
          update();
        }
      }
    }
  }

  /// 是否点赞操作中
  bool liking = false;

  /// * 点赞或取消点赞
  Future changeLike() async {
    if (liking) return;
    liking = true;
    if (OpenTaskIntroductionCeremony.openTaskInterface()) {
      liking = false;
      return;
    }
    final iLiked = data.postSubInfoDataModel.iLiked == '1';
    String likeId = '';
    try {
      const type = 'post';
      if (iLiked) {
        await CircleApi.circleDelReaction(channelId, postId, topicId, type,
            data.postSubInfoDataModel.likeId, '');
      } else {
        final res = await CircleApi.circleAddReaction(
            channelId, postId, topicId, type, '');
        if (res.containsKey('id')) {
          likeId = res['id'];
        }
        await HapticFeedback.lightImpact();
      }
      onLikeChange(!iLiked, likeId);
    } catch (e) {
      onRequestError(e, null);
    }
    liking = false;
  }

  /// 点赞状态改变
  void onLikeChange(bool value, String likeId) {
    if (value) {
      data.modifyLikedState('1', likeId, postId: postId);
      likeShowSize++;
    } else {
      data.modifyLikedState('0', likeId, postId: postId);
      if (likeShowSize > 0) likeShowSize--;
    }
    needRefreshWhenPop = true;
    update([idLikeView]);
  }

  bool updateLiking = false;

  /// * 点赞列表：展开(获取下一页 或 全部) 或者 收起
  Future updateLikeList(int size, bool isExpand) async {
    if (updateLiking) return;
    updateLiking = true;
    try {
      final likeList = data.postSubInfoDataModel.likeList;
      if (!isExpand) {
        likeStatus = LikeStatus.Fold;
        likeShowSize = likeInitSize;
        updateLiking = false;

        /// 收起点赞列表时，定位到全部回复的上方，如果内容不足一页，则定位到顶部
        /// **最佳方案其实是点赞列表下面的 UI 不变，上面的内容移下来
        /// 但是这需要对齐为底部，但此时对齐不一定是底部，而且重新设置对齐会导致滚动位置变化**
        if (listContentExceedKeyboardlessViewport(listMaxViewportDimension)) {
          initialAlignment = 1;
          initialIndex = 1;
          pinNotifier.value = false;
        } else {
          initialAlignment = 0;
          initialIndex = 0;
        }
        listKey = ValueKey(listKey.value + 1);
        update();
        return;
      } else {
        if (likeList.length >= totalLikeNum) {
          //已经加载所有的情况下，展开下一页
          likeStatus = LikeStatus.Expand;
          likeShowSize = min(likeShowSize + size, totalLikeNum);
          updateLiking = false;
          update();
          return;
        }
      }

      final lastListId = likeList.last.reactionId;
      final nextList = await CirclePostLikeListDataModel.getNextList(
        postId: postId,
        listId: lastListId,
        size: '$size',
      );
      likeList.addAll(nextList);
      likeStatus = LikeStatus.Expand;
      likeShowSize = likeList.length;
    } catch (e) {
      onRequestError(e, null);
    }
    updateLiking = false;
    update();
  }

  ///查找回复ID在当前列表的索引
  int commentIndexOfList(String commentId) {
    if (replyListIsEmpty) return -1;
    final index = replyList.indexWhere((e) => commentId == e.commentId);
    return index;
  }

  /// * 跳转到某条回复
  /// * delay: 延迟跳转的时间
  /// * toDown: 是否向下跳转
  Future goToComment(String commentId,
      {Duration delay, bool toDown = false}) async {
    logger.info('getChat goToComment - commentId: $commentId, toDown: $toDown');

    if (isLoading || commentId == null || commentId == '0') return;
    isLoading = true;
    if (delay != null) await Future.delayed(delay);
    if (toDown) {
      final index = bottomList.indexWhere((e) => commentId == e.commentId);
      if (index > -1) {
        jumpToIndex(index + headerSize + 1, 1);
        isLoading = false;
        return;
      }
    } else {
      final index = commentIndexOfList(commentId);
      if (index > -1) {
        final toIndex = index + headerSize;
        jumpToIndex(toIndex, 0);
        isLoading = false;
        return;
      }
    }

    try {
      final tuple3 = await getAroundCommentListV2(commentId);
      final beforeSize = tuple3.item2;
      final afterSize = tuple3.item3;
      final halfSize = pageSize / 2;

      setLoadStatus(
        header: beforeSize < halfSize ? LoadStatus.noMore : LoadStatus.loading,
      );
      setLoadStatus(
        footer: afterSize < halfSize ? LoadStatus.noMore : LoadStatus.loading,
      );

      if (!toDown && tuple3.item1.hasValue) {
        final firstItem = _list[_list.firstKey()];
        if (tuple3.item1.last.messageIdBigInt < firstItem.messageIdBigInt) {
          ///如果跳转的list和原list没有交集，需要分离，列表使用middleList
          dataIsCommon = false;
          _middleList.clear();
        } else {
          setLoadStatus(footer: LoadStatus.noMore);
        }
      }

      addCommentMessageList(tuple3.item1);
      initialAlignment = 1;
      initialIndex = beforeSize + headerSize + 1;
      listKey = ValueKey(listKey.value + 1);
    } catch (e) {
      logger.severe('回复列表跳转错误: $e');
    }
    update();
    isLoading = false;
  }

  /// * 设置圈子消息频道
  void setPostChannel() {
    if (extraData?.circleNewsChannelId?.hasValue ?? false) {
      postChannel = Db.channelBox.get(extraData.circleNewsChannelId);
    } else {
      //查找私信列表中，是否有对应的圈子频道
      postChannel = DirectMessageController.to.getCircleChannel(postId);
    }
    if (postChannel != null) {
      brController.postChannelId = postChannel.id;
      //获取圈子频道的未读数
      CircleNewsTable.queryCircleNews(postChannel.id,
              firstId: Db.firstMessageIdBox.get(postChannel.id))
          .then((value) {
        brController?.positionObj = value;
      });
    }
  }

  /// * 主界面私信列表的圈子频道置顶
  void channelToTop() {
    //不是作者且没关注，不会收到ws的circle_push
    if (headUser?.userId != Global.user.id && !isFollow) return;
    postChannel ??= DirectMessageController.to.getCircleChannel(postId);
    if (postChannel != null)
      DirectMessageController.to.bringChannelToTop(postChannel);
  }

  /// * 频道未读数清零
  void clearUnread({bool upNow = true}) {
    postChannel ??= DirectMessageController.to.getCircleChannel(postId);
    if (postChannel != null) {
      CommentMessageEntity uploadLast;
      if (!replyListIsEmpty) {
        final last = replyList.last;
        //用于上报已读的消息
        uploadLast = CommentMessageEntity(
          topicId: postChannel.id,
          commentId: last.commentId,
          guildId: guildId,
        );
      }
      ChannelUtil.instance
          .clearUnreadById(postChannel.id, last: uploadLast, upNow: upNow);
    }
  }

  /// * 延迟设置 [isUpdateByScroll] 为true
  void delaySet(Duration delay, VoidCallback callback) {
    Future.delayed(delay).then((_) {
      isUpdateByScroll = true;
      callback?.call();
    });
  }

  /// * 从圈子主页跳转过来：
  void doFromCommon() {
    _hideLoading();
    delaySet(400.milliseconds, () {
      if (brController?.hasUnread ?? false) {
        if (bottomIndex != null && !replyListIsEmpty)
          brController?.updateLastBean(lastComment: replyList[bottomIndex]);
        else
          brController?.updateLastBean(forceCount: true);
      }
    });
  }

  /// * 从消息列表或push跳转进来
  void doFromDmList() {
    clearUnread();
    if (!replyListIsEmpty) {
      Future.delayed(100.milliseconds).then((_) {
        jumpToBottom();
        _hideLoading();
      });
    } else {
      _hideLoading();
    }
    delaySet(400.milliseconds, () {
      if (!replyListIsEmpty &&
          (trController?.hasAt ?? false) &&
          topIndex != null)
        trController?.updateFirstBean(firstComment: replyList[topIndex]);
    });
  }

  ///防止重复点击
  bool followRunning = false;

  ///关注和取消关注
  ///flag 1:关注，0：取消关注
  Future<bool> postFollow(String flag) async {
    if (followRunning) return false;
    followRunning = true;
    final result = await CircleDetailUtil.postFollow(channelId, postId, flag);
    if (result == null) {
      followRunning = false;
      return false;
    }
    if (result == '1') {
      data?.postSubInfoDataModel?.isFollow = true;
    } else {
      data?.postSubInfoDataModel?.isFollow = false;
    }
    followRunning = false;
    return true;
  }

  /// * 添加回复消息到内存
  /// * isUpdate: 是否更新UI
  /// * fromWs: 是否来自ws推送
  /// * addToList：是否加入到[_list]
  /// * isUpdateTotal: 是否更新总数
  void addCommentMessage(CommentMessageEntity message,
      {bool isUpdate = false,
      bool fromWs = false,
      bool addToList = false,
      bool isUpdateTotal = true}) {
    if (!fromWs && !addToList && !dataIsCommon) {
      _middleList[message.messageIdBigInt] = message;
    } else {
      _list[message.messageIdBigInt] = message;
    }
    if (isUpdateTotal)
      data?.postSubInfoDataModel?.commentTotal = '${totalReplySize + 1}';

    if (isUpdate) {
      // if (!isCanScroll()) listKey = ValueKey(listKey.value + 1);
      update();
    }
    Future.delayed(300.milliseconds).then((_) {
      if (fromWs && message.userId != Global.user.id) {
        if (listContentExceedKeyboardlessViewport(listMaxViewportDimension)) {
          brController.addUnRead(message,
              isAtMe: message.mentions?.contains(Global.user.id) ?? false);
        } else {
          clearUnread(upNow: false);
        }
      }
    });
  }

  /// * 添加回复集合到内存
  void addCommentMessageList(List<CommentMessageEntity> list) {
    list?.forEach((e) {
      addCommentMessage(e, isUpdateTotal: false);
    });
  }

  /// * 合并两个回复集合
  void mergeList() {
    _list.addAll(_middleList);
  }

  /// * 从内存里删除回复消息
  void removeCommentMessage(CommentMessageEntity message,
      {bool fromWs = false}) {
    if (!fromWs && !dataIsCommon) {
      _middleList.remove(message.messageIdBigInt);
    } else {
      _list.remove(message.messageIdBigInt);
    }

    final total = totalReplySize > 0 ? totalReplySize - 1 : 0;
    data?.postSubInfoDataModel?.commentTotal = '$total';

    initialAlignment = 0;
    update();

    if (fromWs && message.userId != Global.user.id) {
      brController.removeUnRead(message);
    }
    CircleDetailUtil.deleteCommentFromCache(message.messageId);
  }

  /// * 发送成功后，更新该回复
  void updateCommentMessage(BigInt oldMessageId, CommentMessageEntity message) {
    _list.remove(oldMessageId);
    _list[message.messageIdBigInt] = message;

    if (videoTag.hasValue) {
      //沉浸式发回复：如果该动态的圈子详情也打开，需要同步增加
      final otherC = CircleDetailController.to(postId: message.postId);
      if (otherC?.postId == postId) {
        otherC.addCommentMessage(message, isUpdate: true);
      }
    }
    channelToTop();
  }

  /// * 获取单条回复
  CommentMessageEntity getCommentMessage(BigInt messageId) {
    CommentMessageEntity entity;
    if (dataIsCommon)
      entity = _list[messageId] ?? _middleList[messageId];
    else
      entity = _middleList[messageId] ?? _list[messageId];
    return entity;
  }

  /// * ws增加表态
  void addReaction(BigInt messageId, String name, bool me, int count) {
    final message = getCommentMessage(messageId);
    message?.reactionModel?.append(name, me, count: count);
  }

  /// * ws取消表态
  void delReaction(BigInt messageId, String name, bool me, int count) {
    final message = getCommentMessage(messageId);
    message?.reactionModel?.remove(name, me, count: count);
  }

  void _initVideo() {
    tabController = TabController(length: 2, vsync: this);
  }

  /// * 腾讯文档-点击跳转
  void onDocClick() {
    if (data?.docItem?.fileId?.hasValue ?? false) {
      TcDocUtils.toDocPage(data.docItem.url);
    }
  }

  /// * showLoading 改为 false
  void _hideLoading() {
    if (showLoading.value) showLoading.value = false;
  }

  void reset() {
    // 使用 jumpTo 消耗掉物理滑动
    scrollController.jumpTo(0);
    jumpToIndex(0, 0);
    pinNotifier.reset();
  }
}
