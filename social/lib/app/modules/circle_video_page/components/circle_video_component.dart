import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/circle_post_data_model.dart';
import 'package:im/app/modules/circle/models/circle_share_poster_model.dart';
import 'package:im/app/modules/circle_detail/controllers/circle_detail_controller.dart';
import 'package:im/app/modules/circle_video_page/components/circle_video_comment.dart';
import 'package:im/app/modules/circle_video_page/components/circle_video_tap_like.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_controller.dart';
import 'package:im/app/modules/circle_video_page/controllers/circle_video_page_controller.dart';
import 'package:im/app/modules/mute/views/mute_listener_widget.dart';
import 'package:im/app/modules/share_circle/controllers/share_circle_controller.dart';
import 'package:im/app/modules/share_circle/views/share_circle.dart';
import 'package:im/common/permission/permission.dart' as permission;
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/like_button.dart';
import 'package:im/pages/guild_setting/circle/circle_detail_page/menu_button/menu_button.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_widget.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/routes.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/disk_util.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/storage_util.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:websafe_svg/websafe_svg.dart';

import 'circle_video_loading_animation.dart';
import 'circle_video_post.dart';

class CircleVideoComponent extends StatefulWidget {
  const CircleVideoComponent(this.circlePostDataModel, this.proxyController,
      this.likeNotifier, this.onAddFavorite,
      {key})
      : super(key: key);
  final CirclePostDataModel circlePostDataModel;
  final VideoProxyController proxyController;
  final ValueNotifier<bool> likeNotifier;
  final VoidCallback onAddFavorite;

  @override
  _CircleVideoComponentState createState() => _CircleVideoComponentState();
}

class _CircleVideoComponentState extends State<CircleVideoComponent> {
  ///拖拽状态
  bool _dragging = false;

  ///显示全文
  bool _showAll = false;

  ///显示暂停按钮
  bool _showPause = false;

  ///拖拽进度条时的临时视频Position
  double _tempValue = 0;

  ///是否关注
  bool get isFollow =>
      widget.circlePostDataModel.postSubInfoDataModel?.isFollow ?? false;

  ///点赞icon
  final List<Offset> _icons = [];

  @override
  Widget build(BuildContext context) {
    final videoPlayerController = widget.proxyController.playerController;
    return Stack(
      children: [
        _buildLikeWidget(videoPlayerController),
        Positioned(
          bottom: 0,
          child: _postBackground(),
        ),
        if (_showAll) buildExpandBackground(),
        GetBuilder<CircleVideoPageController>(
            id: "components",
            builder: (_) =>
                widget.proxyController.banned ? _buildErrorNotice() : sizedBox),
        Positioned(
          bottom: 0,
          child: _buildBottomWidget(context, videoPlayerController),
        ),

        ///顶栏的三个按钮
        Positioned(
          top: 0,
          right: 0,
          child: Row(
            children: [
              _shareButton(context),
              const SizedBox(width: 12),
              _subscribeButton(),
              const SizedBox(width: 12),
              _moreButton(),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  ///显示全文的时候的加黑背景
  GestureDetector buildExpandBackground() {
    return GestureDetector(
      onTap: () => setShowAllState(false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        curve: Curves.ease,
        opacity: _showAll ? 1 : 0,
        child: Container(color: const Color.fromRGBO(0, 0, 0, .8)),
      ),
    );
  }

  ///构建错误提示组件
  Center _buildErrorNotice() {
    return Center(
      child: Text(
        '很抱歉，你想看的视频找不到了~'.tr,
        style: TextStyle(
          color: Colors.white.withOpacity(.7),
          fontSize: 14,
        ),
      ),
    );
  }

  ///点赞按钮和暂停按钮
  Widget _buildLikeWidget(VideoPlayerController controller) {
    final List<Widget> list = _icons
        .map<Widget>(
          (position) => TikTokFavoriteAnimationIcon(
            key: Key(position.toString()),
            position: position,
            onAnimationComplete: () {
              _icons.remove(position);
            },
          ),
        )
        .toList();
    list.insert(
      0,
      GetBuilder<CircleVideoPageController>(
        id: 'components',
        builder: (_) {
          return Center(
            child: (!controller.value.isPlaying && _showPause)
                ? DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: WebsafeSvg.asset(
                      SvgIcons.play,
                      color: const Color.fromRGBO(255, 255, 255, .8),
                      width: 59,
                    ),
                  )
                : const SizedBox(),
          );
        },
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (controller.value.isPlaying) {
          _showPause = true;
          controller.pause();
          setAwake(false);
        } else if (mounted) {
          controller.play();
          setAwake(true);
        }
      },
      onDoubleTap: () {},
      onDoubleTapDown: (detail) {
        setState(() {
          _icons.add(detail.localPosition);
        });
        widget.onAddFavorite?.call();
      },
      onLongPress: () =>
          showCustomActionSheet([const Text("保存视频")]).then((value) {
        if (value == 0) _saveVideoToGallery();
      }),
      child: Stack(
        children: list,
      ),
    );
  }

  ///帖子文字下的渐变背景
  Widget _postBackground() {
    return IgnorePointer(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 250, minWidth: Get.size.width),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }

  Widget _subscribeButton() {
    return SizedBox(
      height: 44,
      width: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(0, 0, 0, .1),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isFollow
                  ? IconFont.buffCircleSubscribeSelect
                  : IconFont.buffCircleSubscribeUnselect,
            ),
            padding: EdgeInsets.zero,
            color: Colors.white,
            onPressed: () async {
              final result = await postFollow(isFollow ? '0' : '1');
              if (result) {
                setState(() {});
                unawaited(CircleDetailController.to(
                  postId: widget.circlePostDataModel.postId,
                )?.refreshAll());
                if (Get.isRegistered<CircleController>())
                  CircleController.to.loadSubscriptionList();
              }
            },
          ),
        ],
      ),
    );
  }

  /// * 菜单按钮
  Widget _moreButton() {
    return SizedBox(
      height: 44,
      width: 32,
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color.fromRGBO(0, 0, 0, .1),
          ),
          child: MenuButton(
            size: 24,
            iconAlign: Alignment.center,
            iconColor: Colors.white,
            postData: widget.circlePostDataModel,
            onRequestSuccess: (type, {param}) {
              if (type == MenuButtonType.modify || type == MenuButtonType.del) {
                Get.back();
              } else if (type == MenuButtonType.modifyTopic) {
                // 修改所属频道
                if (param != null && param.isNotEmpty) {
                  widget.circlePostDataModel?.postInfoDataModel?.topicId =
                      param[0] as String;
                  widget.circlePostDataModel?.postInfoDataModel?.topicName =
                      param[1] as String;
                }
                setState(() {});
              }
            },
          ),
        ),
      ),
    );
  }

  ///时间指示器，进度条，评论框及点赞
  Widget _buildBottomWidget(
      BuildContext context, VideoPlayerController controller) {
    return Column(
      children: [
        if (_dragging)
          GetBuilder<CircleVideoPageController>(
            id: 'components',
            builder: (_) => _timeIndicator(controller),
          ),
        if (!_dragging) _videoPost(context),
        GetBuilder<CircleVideoPageController>(
          id: "components",
          builder: (_) => Visibility(
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            visible: !widget.proxyController.banned,
            child: _slider(controller),
          ),
        ),
        Container(
          height: 45,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.only(bottom: 6, left: 16, right: 16),
          child: Row(
            children: [
              Expanded(
                child: MuteListenerWidget(
                  builder: (isMuted, mutedTime) {
                    if (isMuted)
                      return _talkSomeButton('禁言中'.tr, isCenterAlign: true);
                    else
                      return permission.ValidPermission(
                        channelId: widget.circlePostDataModel.topicId,
                        permissions: [permission.Permission.CIRCLE_REPLY],
                        builder: (hasPermission, isOwner) {
                          if (hasPermission || isOwner) {
                            final gId = widget
                                .circlePostDataModel.postInfoDataModel.guildId;
                            final name = Db.userInfoBox
                                .get(widget
                                    .circlePostDataModel.userDataModel.userId)
                                ?.showName(guildId: gId);
                            return GestureDetector(
                              onTap: () {
                                _showComment();
                                _showPause = true;
                              },
                              child:
                                  _talkSomeButton('回复 %s'.trArgs([name ?? ''])),
                            );
                          } else
                            return _talkSomeButton('你没有回复权限'.tr);
                        },
                      );
                  },
                ),
              ),
              _like(),
              _replyButton(),
            ],
          ),
        )
      ],
    );
  }

  ///视频时间指示器
  Widget _timeIndicator(VideoPlayerController controller) {
    final position = controller.value.position.inSeconds;
    final duration = controller.value.duration.inSeconds;

    TextStyle textStyle(double opacity) {
      return TextStyle(
        color: Color.fromRGBO(255, 255, 255, opacity),
        fontSize: 24,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 60),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            Text("${formatCountdownTime(position)}/", style: textStyle(1)),
            Text(formatCountdownTime(duration), style: textStyle(.5)),
          ],
        ),
      ),
    );
  }

  void setShowAllState(bool show) {
    _showAll = show;
    setState(() {});
  }

  Widget _videoPost(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setShowAllState(!_showAll);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: CircleVideoPost(
          model: widget.circlePostDataModel,
          showAll: _showAll,
        ),
      ),
    );
  }

  ///进度条
  Widget _slider(VideoPlayerController controller) {
    final getController = CircleVideoPageController.to();
    final value = controller.value;
    final videoMaxDurationValue = value.duration.inMilliseconds.toDouble();
    final videoPositionDurationValue = value.position.inMilliseconds.toDouble();
    double safeDurationValue() {
      if (videoPositionDurationValue <= 0) return 0;
      if (videoMaxDurationValue <= videoPositionDurationValue)
        return videoMaxDurationValue;
      return videoPositionDurationValue;
    }

    if ((getController.buffering || !value.isInitialized) && !_dragging) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 7, top: 7),
        child: CircleVideoLoadingAnimation(
          spreadOffset: Get.width / 3,
          size: Size(Get.width, 1),
        ),
      );
    } else {
      return SliderTheme(
        data: const SliderThemeData().copyWith(
          trackShape: CustomTrackShape(),
          trackHeight: _dragging ? 2 : 1,
          thumbColor: const Color.fromRGBO(255, 255, 255, 1),
          thumbShape: RoundSliderThumbShape(
            disabledThumbRadius: _dragging ? 4 : 0,
            enabledThumbRadius: _dragging ? 4 : 0,
            elevation: 0,
            pressedElevation: 0,
          ),
          overlayColor: Colors.transparent,
          activeTrackColor: Color.fromRGBO(255, 255, 255, _dragging ? 1 : .5),
          inactiveTrackColor: const Color.fromRGBO(245, 245, 248, .3),
        ),
        child: Listener(
          onPointerDown: (event) {
            controller.pause();
            _dragging = true;
            setState(() {});
          },
          onPointerUp: (event) {
            controller.play();
            _dragging = false;
            setState(() {});
          },
          child: Container(
            height: 15,
            width: Get.width,
            alignment: Alignment.center,
            child: Slider(
              max: videoMaxDurationValue,
              value: _dragging ? _tempValue : safeDurationValue(),
              onChanged: (value) {
                _tempValue = value;
                controller.seekTo(Duration(milliseconds: value.floor()));
              },
            ),
          ),
        ),
      );
    }
  }

  ///点赞按钮
  Widget _like() {
    final postInfo = widget.circlePostDataModel.postInfoDataModel;
    final postSubInfo = widget.circlePostDataModel.postSubInfoDataModel;
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 2),
      child: permission.ValidPermission(
        channelId: postInfo.topicId,
        permissions: [permission.Permission.CIRCLE_ADD_REACTION],
        builder: (hasPermission, isOwner) {
          return CircleAniLikeButton(
            likeNotifier: widget.likeNotifier,
            likeColor: const Color(0xFFF32F56),
            fontColor: Colors.white,
            iconSize: 20,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            padding: EdgeInsets.zero,
            hasPermission: hasPermission || isOwner,
            likeIconData: IconFont.buffLikeSel,
            unlikeIconData: IconFont.buffLike,
            postData: PostData(
              channelId: postInfo.channelId,
              guildId: postInfo.guildId,
              postId: postInfo.postId,
              topicId: postInfo.topicId,
              likeId: postSubInfo.likeId,
              t: 'post',
            ),
            unLikeColor: Colors.white,
            count: int.parse(postSubInfo.likeTotal),
            liked: postSubInfo.iLiked == '1',
            onLikeChange: (t, v) {
              _modifyLiked(t, v);
              Future(() {
                // 更新详情页的点赞状态
                CircleDetailController.to(
                  postId: widget.circlePostDataModel.postId,
                )?.onLikeChange(t, v);
                // 更新圈子列表的点赞状态
                if (Get.isRegistered<CircleController>()) {
                  CircleController.to
                      .updateItem(postInfo.topicId, widget.circlePostDataModel);
                }
              });
            },
          );
        },
      ),
    );
  }

  void _modifyLiked(bool t, String v) {
    final postInfo = widget.circlePostDataModel.postInfoDataModel;
    widget.circlePostDataModel
        .modifyLikedState(t ? '1' : '0', v, postId: postInfo.postId);
    setState(() {});
  }

  /// * 回复图标
  Widget _replyButton() {
    final commentTotal =
        widget.circlePostDataModel.postSubInfoDataModel.commentTotal;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _showComment();
        _showPause = true;
      },
      child: SizedBox(
        height: 45,
        child: Row(
          children: [
            const Icon(
              IconFont.buffCircleReply,
              color: Colors.white,
              size: 23,
            ),
            if (commentTotal != '0') ...[
              sizeWidth4,
              Text(
                commentTotal,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ]
          ],
        ),
      ),
    );
  }

  /// * 分享按钮
  Widget _shareButton(BuildContext context) {
    final model = widget.circlePostDataModel;
    return SizedBox(
      width: 32,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(0, 0, 0, .1),
              ),
            ),
          ),
          InkWell(
              onTap: () {
                ShareCircle.showCircleShareDialog(
                  ShareBean(
                    data: model,
                    guildId: model.postInfoDataModel.guildId,
                    sharePosterModel: CircleSharePosterModel(
                        circleDetailData: CircleDetailData(model),
                        postVideo: widget.proxyController.postVideo),
                    // isFromList: false,
                  ),
                );
              },
              child: ShareButton(
                size: 20,
                data: model,
                color: Colors.white,
                alignment: Alignment.center,
                sharePosterModel: CircleSharePosterModel(
                    circleDetailData: CircleDetailData(model),
                    postVideo: widget.proxyController.postVideo),
                isFromList: false,
              )),
        ],
      ),
    );
  }

  Future<void> _saveVideoToGallery() async {
    final String url = widget.proxyController.postVideo.videoUrl;
    if (await DiskUtil.availableSpaceGreaterThan(200)) {
      final permission = await checkSystemPermissions(
        context: context,
        permissions: [
          if (UniversalPlatform.isIOS) Permission.photos,
          if (UniversalPlatform.isAndroid) Permission.storage
        ],
      );
      if (permission != true) {
        showToast('无权限获取相册，保存失败'.tr);
        return;
      }
      await saveImageToLocal(url: url, isImage: false);
    } else {
      final bool isConfirm = await showConfirmDialog(
        title: '存储空间不足，清理缓存可释放存储空间'.tr,
      );
      if (isConfirm != null && isConfirm == true) {
        unawaited(Routes.pushCleanCachePage(context));
      }
    }
  }

  ///防止重复点击
  bool followRunning = false;

  ///关注和取消关注
  ///flag 1:关注，0：取消关注
  Future<bool> postFollow(String flag) async {
    final model = widget.circlePostDataModel;
    if (followRunning) return false;
    followRunning = true;
    final res = await CircleApi.circleFollow(model.postInfoDataModel.channelId,
            model.postInfoDataModel.postId, flag)
        .catchError((e) {
      debugPrint('getChat post - circleFollow e:$e');
    });
    if (res == null) {
      followRunning = false;
      return false;
    }
    if (flag == '1') {
      model.postSubInfoDataModel?.isFollow = true;
      unawaited(HapticFeedback.lightImpact());
    } else {
      model?.postSubInfoDataModel?.isFollow = false;
    }
    followRunning = false;
    return true;
  }

  /// * 显示回复列表弹窗
  void _showComment() {
    showBottomModal(
      context,
      resizeToAvoidBottomInset: false,
      routeSettings: const RouteSettings(name: 'video_comment'),
      showTopCache: false,
      builder: (c, s) => CircleVideoComment(
        widget.circlePostDataModel,
        (total) {
          widget.circlePostDataModel.postSubInfoDataModel.commentTotal = total;
        },
      ),
    ).then(
      (_) {
        ///回复列表关闭后，更新底部的回复总数
        if (mounted) setState(() {});
      },
    );
  }
}

Widget loadingFakeWidget(BuildContext context) {
  return SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 10),
          child: _buildBackButton(),
        ),
        const Spacer(),
        CircleVideoLoadingAnimation(
          spreadOffset: MediaQuery.of(context).size.width / 3,
          size: Size(MediaQuery.of(context).size.width, 1),
        ),
        const SizedBox(height: 7),
        Container(
          height: 45,
          padding: const EdgeInsets.only(bottom: 6, left: 16, right: 16),
          child: Row(
            children: [
              Expanded(
                child: _talkSomeButton('说点什么…'),
              ),
              sizeWidth14,
              WebsafeSvg.asset(
                SvgIcons.circleUnlike2,
                color: Colors.white,
                width: 24,
              ),
              sizeWidth14,
              const Icon(
                IconFont.buffCircleReply,
                color: Colors.white,
                size: 20,
              ),
              sizeWidth14,
              SizedBox(
                width: 48,
                child: Row(
                  children: const [
                    Icon(
                      IconFont.buffChatForward,
                      color: Colors.white,
                      size: 20,
                    ),
                    sizeWidth4,
                    Text("分享",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    ),
  );
}

GestureDetector _buildBackButton() {
  return GestureDetector(
    onTap: Get.back,
    child: Container(
      width: 48,
      height: 48,
      alignment: Alignment.topLeft,
      child: const Icon(
        IconFont.buffNavBarBackItem,
        color: Colors.white,
      ),
    ),
  );
}

Widget _talkSomeButton(String text, {bool isCenterAlign = false}) {
  return Container(
    height: 40,
    decoration: BoxDecoration(
      color: const Color.fromRGBO(255, 255, 255, .1),
      borderRadius: BorderRadius.circular(5),
    ),
    padding: const EdgeInsets.only(left: 16),
    alignment: isCenterAlign ? Alignment.center : Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        color: Color.fromRGBO(255, 255, 255, .4),
      ),
    ),
  );
}

class CustomTrackShape extends RectangularSliderTrackShape {
  @override
  Rect getPreferredRect({
    @required RenderBox parentBox,
    Offset offset = Offset.zero,
    @required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
