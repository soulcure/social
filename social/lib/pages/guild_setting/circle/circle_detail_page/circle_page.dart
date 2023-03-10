import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:get/get.dart';
import 'package:im/api/entity/circle_detail_list_bean.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_item.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/web/widgets/app_bar/web_appbar.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'circle_page_logic.dart';
import 'common.dart';
import 'menu_button/menu_button.dart';
import 'show_landscape_circle_reply_popup.dart';

class CirclePage extends StatefulWidget {
  final CirclePostDataModel circlePostDataModel;
  final ExtraData extraData;
  final String circleOwnerId;
  final Function(Map info) modifyCallBack;

  const CirclePage({
    Key key,
    this.circlePostDataModel,
    this.extraData,
    this.circleOwnerId,
    this.modifyCallBack,
  }) : super(key: key);

  @override
  _CirclePageState createState() => _CirclePageState();
}

class _CirclePageState extends State<CirclePage> {
  final _StateDelegate _stateDelegate = _StateDelegate();
  CirclePageModel _model;

  @override
  void initState() {
    needRefreshWhenPop = false;
    _stateDelegate._refreshCallback = _refresh;
    _model = CirclePageModel(
      _stateDelegate,
      widget.circlePostDataModel,
      widget.extraData,
      widget.circleOwnerId,
    );
    _model.initState();
    super.initState();
  }

  @override
  void dispose() {
    _stateDelegate._refreshCallback = null;
    _model.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
    model.context ??= context;
    final logic = model.logic;
    const bgColor = Colors.white;

    return WillPopScope(
      onWillPop: () {
        /// ????????????????????????????????????????????????
        Navigator.of(context).pop(needRefreshWhenPop);
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: OrientationUtil.portrait
            ? CustomAppbar(
                title: '????????????'.tr,
                elevation: 0.5,
                backgroundColor: bgColor,
                leadingCallback: () =>
                    Navigator.of(context).pop(needRefreshWhenPop),
                actions: [
                  if (model.data != null)
                    AppbarCustomButton(
                      child: MenuButton(
                        postData: model.data,
                        onRequestSuccess: (type, {param}) {
                          if (type == MenuButtonType.del) {
                            Navigator.of(context).pop(true);
                          } else {
                            widget.modifyCallBack?.call({
                              "refresh": "true",
                              "modify_type": type.toString()
                            });
                            needRefreshWhenPop = true;
                          }
                        },
                        iconAlign: Alignment.center,
                        size: 24,
                        padding: const EdgeInsets.only(right: 16),
                        onRequestError: (code, type) {
                          onRequestError(RequestArgumentError(code), context,
                              deletePost: true);
                        },
                        callbackBuilder: CallbackBuilder(onModifyCallback: (v) {
                          if (v != null) {
                            logic.refreshContent();
                          }
                        }),
                      ),
                    )
                ],
              )
            : WebAppBar(
                title: '????????????'.tr,
                height: 68,
                backAction: () {
                  Navigator.of(context).pop(needRefreshWhenPop);
                },
              ),
        body: GestureDetector(
          onTap: () {},
          child: logic.buildLayout(),
        ),
      ),
    );
  }
}

class CirclePageModel {
  final _StateDelegate stateDelegate;
  CirclePageLogic logic;
  BuildContext context;

  final String circleOwnerId;

  final RefreshController refreshController = RefreshController();

  final ScrollController controller = ScrollController();

  double curOff = 0;

  ///???[data]??????null???????????????????????????????????????
  CirclePostDataModel data;

  ///???[extraData]??????null?????????????????????????????????????????????????????????
  ExtraData extraData;

  ///key???commentId, value?????????list????????????
  final Map<String, int> commentMap = {};

  ///?????????????????????comment_id
  String quoteId = '';

  bool initialLoading = true;

  bool initialError = false;

  int requestCode = 0;

  bool isLoading = false;

  ///??????????????????????????????????????????,???????????????index?????????index??????????????????????????????????????????,[tempList]??????index???????????????
  bool needLoadHeadRest = false;

  bool noMoreData = false;

  RequestType requestType = RequestType.normal;

  List<ReplyDetailBean> tempList;

  ///?????????????????????????????????
  List<Operation> contentList;

  ///??????????????????
  List<IndexMedia> imageList = [];

  CircleDetailBean circleDetailBean;

  QuillController quillController;

  CirclePageModel(
      this.stateDelegate, this.data, this.extraData, this.circleOwnerId) {
    logic = CirclePageLogic(this);
    final content = data?.postInfoDataModel?.postContent() ??
        RichEditorUtils.defaultDoc.encode();
    final document = Document.fromJson(jsonDecode(content));
    quillController = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0));
  }

  void initState() {
    logic.initState();
    controller.addListener(_onScroll);

    ///??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
    if (CircleController.to == null)
      CircleController(guildId, channelId).initFromNet();
    needRefreshWhenPop = false;
  }

  void dispose() {
    logic.dispose();
    context = null;
    data = null;
    refreshController.dispose();
    controller.dispose();
    if (!needRefreshWhenPop) {
      final replySame =
          totalReplyNum == data?.postSubInfoDataModel?.commentTotal;
      final likeSame = totalLikes == data?.postSubInfoDataModel?.likeTotal;
      if (!replySame || likeSame) needRefreshWhenPop = true;
    }
  }

  void _onScroll() {
    ///????????????????????????????????????????????????????????????????????????????????????
    if (curOff == controller.offset) return;
    curOff = controller.offset;
    if (UniversalPlatform.isAndroid || UniversalPlatform.isIOS) return;
    if (controller.offset == controller.position.maxScrollExtent &&
        !refreshController.isLoading) {
      refreshController.requestLoading();
    }
  }

  void refresh() => stateDelegate?.refresh();

  String get createdAt => data.postInfoDataModel.createdAt;

  String get updatedAt => data.postInfoDataModel.updatedAt;

  CirclePostUserDataModel get headUser => data.userDataModel;

  String get totalReplyNum =>
      circleDetailBean?.post?.subInfo?.commentTotal?.toString() ??
      data?.postSubInfoDataModel?.commentTotal ??
      '0';

  void addTotalReplyNum({int value = 0}) {
    int num = 0;
    if (totalReplyNum.isNotEmpty) num = int.parse(totalReplyNum);
    if (value == 0)
      num++;
    else
      num += value;
    data?.postSubInfoDataModel?.commentTotal = '$num';
    circleDetailBean?.post?.subInfo?.commentTotal = num;
    postInfoMap[postId]?.setData(commentTotal: '$num', needRefresh: false);
  }

  void removeTotalReplyNum({int value = 0}) {
    int num = 1;
    if (totalReplyNum.isNotEmpty) num = int.parse(totalReplyNum);
    if (num > 0) num--;
    if (num > value) num -= value;
    data?.postSubInfoDataModel?.commentTotal = '$num';
    circleDetailBean?.post?.subInfo?.commentTotal = num;
    postInfoMap[postId]?.setData(commentTotal: '$num', needRefresh: false);
  }

  String get totalLikes =>
      circleDetailBean?.post?.subInfo?.likeTotal?.toString() ??
      data?.postSubInfoDataModel?.likeTotal ??
      '';

  int get totalLikeNum {
    try {
      return int.parse(totalLikes);
    } catch (e) {
      return 0;
    }
  }

  void addTotalLike() {
    int num = 0;
    if (totalLikes.isNotEmpty) num = int.parse(totalLikes);
    num++;
    data?.postSubInfoDataModel?.likeTotal = '$num';
    circleDetailBean?.post?.subInfo?.likeTotal = num;
    postInfoMap[postId]
        ?.setData(likeTotal: '$num', liked: likeByMyself, needRefresh: false);
  }

  void removeTotalLike() {
    int num = 1;
    if (totalLikes.isNotEmpty) num = int.parse(totalLikes);
    if (num > 0) num--;
    data?.postSubInfoDataModel?.likeTotal = '$num';
    circleDetailBean?.post?.subInfo?.likeTotal = num;
    postInfoMap[postId]
        ?.setData(likeTotal: '$num', liked: likeByMyself, needRefresh: false);
  }

  bool get likeByMyself {
    if (circleDetailBean?.post?.subInfo?.liked != null)
      return circleDetailBean.post.subInfo.liked == 1;
    return data?.postSubInfoDataModel?.iLiked == '1';
  }

  bool get isFloorsEmpty => replyList?.isEmpty ?? true;

  String get guildId => data?.postInfoDataModel?.guildId ?? extraData?.guildId;

  String get channelId =>
      data?.postInfoDataModel?.channelId ?? extraData?.channelId;

  String get topicId => data?.postInfoDataModel?.topicId ?? extraData?.topicId;

  String get postId =>
      data?.postInfoDataModel?.postId ?? extraData?.postId ?? '';

  String get title => data?.postInfoDataModel?.title ?? '';

  String get content => data?.postInfoDataModel?.content;

  String get contentV2 => data?.postInfoDataModel?.contentV2;

  String get postType => data?.postInfoDataModel?.postType ?? '';

  String get postContent {
    if (postType.isEmpty) {
      return content;
    } else if (postType == CirclePostDataType.article) {
      return contentV2;
    } else {
      return null;
    }
  }

  bool get postTypeAvailable =>
      data?.postInfoDataModel?.postTypeAvailable ?? false;

  String get topicName => data.postInfoDataModel?.topicName ?? '';

  String get likeId =>
      circleDetailBean?.post?.subInfo?.likeId ??
      data.postSubInfoDataModel?.likeId ??
      '';

  List<ReplyDetailBean> get replyList => circleDetailBean?.replys ?? [];

  set listId(String commentId) => circleDetailBean?.listId = commentId;

  String get listId => circleDetailBean?.listId ?? '';
}

bool needRefreshWhenPop = false;

class _StateDelegate {
  VoidCallback _refreshCallback;

  void refresh() => _refreshCallback?.call();
}

class ExtraData {
  ///????????????(type=5)
  final String channelId;

  final String topicId;
  final String postId;
  String commentId;
  final String guildId;
  ExtraType extraType;

  ///??????????????????(type=13)
  String circleNewsChannelId;

  ///????????????id
  final String circleNewsMessageId;

  ///?????????????????????????????? (??????????????????)
  String lastCircleType;

  ExtraData({
    this.channelId,
    this.topicId,
    this.postId,
    this.guildId,
    this.commentId,
    this.circleNewsChannelId,
    this.circleNewsMessageId,
    this.lastCircleType,
    this.extraType = ExtraType.postComment,
  });
}

enum ExtraType {
  postComment,
  postLike,
  commentComment,
  commentLike,
  postAt,
  postCommentAt,
  commentCommentAt,
  fromPush, //??????push
  fromDmList, //????????????
  fromChatView, //????????????
  fromLink, //????????????????????????
  fromCircleList, //?????????????????????
  fromSearch, //?????????????????????
}
