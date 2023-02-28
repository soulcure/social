import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:im/api/entity/circle_detail_list_bean.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/widgets/app_bar/web_appbar.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../common.dart';
import 'reply_page_logic.dart';

/// - 回复详情页面
class ReplyPage extends StatefulWidget {
  final ReplyDetailBean replyDetailBean;

  const ReplyPage({Key key, this.replyDetailBean}) : super(key: key);

  @override
  _ReplyPageState createState() => _ReplyPageState();
}

class _ReplyPageState extends State<ReplyPage> {
  final _StateDelegate _stateDelegate = _StateDelegate();
  ReplyPageModel _model;

  @override
  void initState() {
    _stateDelegate._refreshCallback = _refresh;
    _model = ReplyPageModel(_stateDelegate, widget.replyDetailBean);
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
    _model.context ??= context;
    final logic = _model.logic;
    const bgColor = Colors.white;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: OrientationUtil.portrait
          ? CustomAppbar(
              backgroundColor: bgColor,
              elevation: 0.5,
              title: '回复详情'.tr,
            )
          : WebAppBar(
              title: '回复详情'.tr,
              height: 68,
            ),
      body: GestureDetector(onTap: () {}, child: logic.buildLayout()),
    );
  }
}

class ReplyPageModel {
  final _StateDelegate stateDelegate;
  ReplyPageLogic logic;
  BuildContext context;

  final RefreshController controller = RefreshController();

  final ScrollController scrollController = ScrollController();

  double curOff = 0;

  final ReplyDetailBean replyDetailBean;

  CircleDetailBean circleDetailBean;

  ReplyPageModel(this.stateDelegate, this.replyDetailBean) {
    logic = ReplyPageLogic(this);
  }

  void initState() {
    logic.initState();
    changeNum = 0;
  }

  void dispose() {
    context = null;
    controller.dispose();
    scrollController.dispose();
  }

  bool isLoading = false;

  bool initialLoading = true;

  bool initialError = false;

  bool noMoreData = false;

  RequestType requestType = RequestType.normal;

  void refresh() => stateDelegate?.refresh();

  int get totalLikes =>
      circleDetailBean?.item?.comment?.likeTotal ??
      replyDetailBean.comment.likeTotal;

  bool get likeByMyself => replyDetailBean.comment.liked == '1';

  int get totalReplyNum =>
      circleDetailBean?.item?.comment?.commentTotal ??
      replyDetailBean.comment.commentTotal;

  String get channelId => replyDetailBean.comment.channelId;

  String get topicId => replyDetailBean.comment.topicId;

  String get postId => replyDetailBean.comment.postId;

  String get commentId => replyDetailBean.comment.commentId;

  set listId(String commentId) => circleDetailBean?.listId = commentId;

  String get listId => circleDetailBean?.listId?.toString() ?? '0';

  void addTotalReplyNum() {
    int num = totalReplyNum ?? 1;
    num++;
    changeNum++;
    replyDetailBean.comment?.commentTotal = num;
    circleDetailBean.item?.comment?.commentTotal = num;
  }

  void removeTotalReplyNum() {
    int num = totalReplyNum ?? 1;
    if (num > 1) {
      num--;
      changeNum--;
    }
    replyDetailBean.comment?.commentTotal = num;
    circleDetailBean.item?.comment?.commentTotal = num;
  }

  List<ReplyDetailBean> get replyList =>
      circleDetailBean?.replys ??
      replyDetailBean.comment.replayList
          .map((e) => ReplyDetailBean(e.comment, e.user))
          .toList();
}

class _StateDelegate {
  VoidCallback _refreshCallback;

  void refresh() => _refreshCallback?.call();
}

///用于计算当前页面新增、减少的回复数
int changeNum = 0;
