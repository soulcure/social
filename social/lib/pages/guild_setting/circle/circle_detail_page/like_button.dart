import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/task/introduction_ceremony/open_task_introduction_ceremony.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/icon_font.dart';
import 'package:like_button/like_button.dart' as lb;
import 'package:oktoast/oktoast.dart';

class PostData {
  String guildId;
  String channelId;
  String topicId;
  String postId;
  String t;
  String commentId;
  String likeId;

  ///增加的点赞数，用于动画显示
  int increaseLike;

  PostData(
      {this.guildId,
      this.channelId,
      this.topicId,
      this.postId,
      this.t,
      this.commentId,
      this.likeId,
      this.increaseLike = 0});
}

typedef OnLikeChange<T, V> = void Function(T t, V v);

class LikeButton extends StatelessWidget {
  final bool isLike;
  final bool showText;
  final int count;
  final double iconSize;
  final double fontSize;
  final FontWeight fontWeight;
  final VoidCallback onPress;
  final Color unLikeColor;
  final Color likeColor;
  final EdgeInsets padding;
  final Widget textWidget;
  final WidgetBuilder gestureWrapper;
  final IconData likeIconData;
  final IconData unlikeIconData;

  const LikeButton({
    Key key,
    this.isLike = false,
    this.showText = true,
    this.count,
    this.onPress,
    this.iconSize = 24,
    this.fontSize = 13,
    this.fontWeight = FontWeight.normal,
    this.unLikeColor,
    this.likeColor,
    this.padding,
    this.textWidget,
    this.gestureWrapper,
    this.likeIconData,
    this.unlikeIconData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    IconData iconData;
    Color color;
    if (isLike) {
      iconData = likeIconData ?? IconFont.buffCircleLike2New;
      color = likeColor ?? _theme.primaryColor;
    } else {
      iconData = unlikeIconData ?? IconFont.buffCircleUnlike2New;
      color = unLikeColor ?? const Color(0xff8f959e);
    }
    final isShowCount = (count ?? 0) > 0;
    final child = Padding(
      padding: padding ?? const EdgeInsets.only(left: 20, right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildMobileLikeIcon(iconData, color, iconSize),
          if (isShowCount)
            Padding(
              padding: const EdgeInsets.only(left: 3),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              ),
            ),
          if (textWidget != null) textWidget
        ],
      ),
    );
    return GestureDetector(
      onTap: onPress,
      behavior: HitTestBehavior.opaque,
      child: gestureWrapper?.call(child) ?? child,
    );
  }
}

class AnimatedLikeButton extends StatelessWidget {
  final bool isLike;
  final int count;
  final double iconSize;
  final double fontSize;
  final Color fontColor;
  final FontWeight fontWeight;
  final lb.LikeButtonTapCallback onTap;
  final EdgeInsets padding;
  final bool showText;
  final Color unLikeColor;
  final Color likeColor;
  final Widget textWidget;
  final WidgetBuilder gestureWrapper;
  final lb.TapController tabController;
  final IconData likeIconData;
  final IconData unlikeIconData;

  const AnimatedLikeButton({
    Key key,
    this.isLike = false,
    this.count,
    this.onTap,
    this.iconSize = 24,
    this.fontSize = 13,
    this.fontColor,
    this.fontWeight = FontWeight.normal,
    this.padding,
    this.showText = true,
    this.unLikeColor,
    this.likeColor,
    this.textWidget,
    this.gestureWrapper,
    this.tabController,
    this.likeIconData,
    this.unlikeIconData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    IconData iconData;
    Color color;
    if (isLike) {
      iconData = likeIconData ?? IconFont.buffCircleLike2New;
      color = likeColor ?? _theme.primaryColor;
    } else {
      iconData = unlikeIconData ?? IconFont.buffCircleUnlike2New;
      color = unLikeColor ?? const Color(0xff8f959e);
    }

    final isShowCount = (count ?? 0) > 0;
    final child = Padding(
      padding: padding ?? const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          lb.LikeButton(
            isLiked: isLike,
            likeBuilder: (liked) {
              return buildMobileLikeIcon(iconData, color, iconSize);
            },
            padding: const EdgeInsets.only(left: 4),
            size: iconSize,
            onTap: onTap,
            tapController: tabController,
          ),
          if (isShowCount)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: fontColor ?? color,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              ),
            ),
          if (textWidget != null) textWidget
        ],
      ),
    );
    return GestureDetector(
      onTap: () {
        tabController?.tap();
      },
      behavior: HitTestBehavior.opaque,
      child: gestureWrapper?.call(child) ?? child,
    );
  }
}

class ReplyAnimatedLikeButton extends StatelessWidget {
  final bool isLike;
  final int count;
  final double iconSize;
  final double fontSize;
  final Color fontColor;
  final FontWeight fontWeight;
  final lb.LikeButtonTapCallback onTap;
  final EdgeInsets padding;
  final IconData likeIconData;
  final IconData unlikeIconData;

  const ReplyAnimatedLikeButton({
    Key key,
    this.isLike = false,
    this.count,
    this.onTap,
    this.iconSize = 24,
    this.fontSize = 13,
    this.fontColor,
    this.fontWeight = FontWeight.normal,
    this.padding,
    this.likeIconData,
    this.unlikeIconData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);

    IconData iconData;
    Color color;
    if (isLike) {
      iconData = likeIconData ?? IconFont.buffCircleLike2New;
      color = _theme.primaryColor;
    } else {
      iconData = unlikeIconData ?? IconFont.buffCircleUnlike2New;
      color = const Color(0xff8f959e);
    }

    final isShowCount = (count ?? 0) > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isShowCount)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: fontColor ?? color,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ),
        SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: lb.LikeButton(
              isLiked: isLike,
              size: iconSize,
              likeBuilder: (liked) {
                return buildMobileLikeIcon(iconData, color, iconSize);
              },
              onTap: onTap,
            ),
          ),
        ),
        const SizedBox(width: 0)
      ],
    );
  }
}

class CircleAniLikeButton extends StatefulWidget {
  final Color defaultColor;
  final double iconSize;
  final double fontSize;
  final Color fontColor;
  final bool liked;
  final bool showText;
  final Widget textWidget;
  final OnLikeChange<bool, String> onLikeChange;
  final PostData postData;
  final int count;
  final EdgeInsets padding;
  final OnRequestError requestError;
  final Color unLikeColor;
  final Color likeColor;
  final bool userReplyButton;
  final WidgetBuilder gestureWrapper;
  final IconData likeIconData;
  final IconData unlikeIconData;
  final ValueNotifier<bool> likeNotifier;
  final FontWeight fontWeight;

  /// 是否有点赞权限
  final bool hasPermission;

  const CircleAniLikeButton(
      {Key key,
      this.defaultColor,
      this.iconSize = 24,
      this.liked = false,
      this.onLikeChange,
      @required this.postData,
      this.count,
      this.fontSize = 13,
      this.fontColor,
      this.fontWeight = FontWeight.normal,
      this.padding,
      this.requestError,
      this.showText = true,
      this.textWidget,
      this.unLikeColor,
      this.likeColor,
      this.userReplyButton = false,
      this.gestureWrapper,
      this.unlikeIconData,
      this.likeIconData,
      this.hasPermission = true,
      this.likeNotifier})
      : super(key: key);

  @override
  CircleAniLikeButtonState createState() => CircleAniLikeButtonState();
}

class CircleAniLikeButtonState extends State<CircleAniLikeButton> {
  bool liked;
  int count;
  bool isLoading = false;
  lb.TapController _tabController = lb.TapController();

  @override
  void initState() {
    liked = widget.liked;
    count = widget.count;
    widget.likeNotifier?.addListener(() {
      if (!liked && widget.likeNotifier.value) {
        onToggleLike();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabController = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CircleAniLikeButton oldWidget) {
    liked = widget.liked;
    count = widget.count;
    widget.likeNotifier?.addListener(() {
      if (!liked && widget.likeNotifier.value) {
        onToggleLike();
      }
    });
    super.didUpdateWidget(oldWidget);
  }

  Future<bool> onToggleLike() async {
    // 先判断是否有权限进行点赞
    if (!widget.hasPermission) {
      showToast('你没有此动态的点赞权限'.tr);
      return false;
    }

    if (OpenTaskIntroductionCeremony.openTaskInterface())
      return Future.value(false);

    final data = widget.postData;
    String likeId = '';
    if (isLoading) return liked;
    isLoading = true;
    try {
      if (liked) {
        await CircleApi.circleDelReaction(
          data.channelId,
          data.postId,
          data.topicId,
          data.t,
          data.likeId,
          data.commentId,
        );
      } else {
        final res = await CircleApi.circleAddReaction(data.channelId,
            data.postId, data.topicId, data.t, data.commentId ?? '');
        if (res.containsKey('id')) {
          likeId = res['id'];
        }
        await HapticFeedback.lightImpact();
      }
      liked = !liked;
      widget.likeNotifier?.value = liked;
      setState(() {});

      widget.onLikeChange?.call(liked, likeId);
    } catch (e) {
      if (e is RequestArgumentError) {
        widget.requestError?.call(e.code);
      }
    }
    isLoading = false;
    return liked;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userReplyButton)
      return ReplyAnimatedLikeButton(
        fontSize: widget.fontSize,
        fontColor: widget.fontColor,
        isLike: liked,
        count: count,
        iconSize: widget.iconSize,
        onTap: (value) => onToggleLike(),
        padding: widget.padding,
        likeIconData: widget.likeIconData,
        unlikeIconData: widget.unlikeIconData,
        fontWeight: widget.fontWeight,
      );
    else if (widget.postData != null && widget.postData.increaseLike > 0)
      return AnimatedIncreaseLikeButton(
        fontSize: widget.fontSize,
        fontColor: widget.fontColor,
        isLike: liked,
        count: count,
        iconSize: widget.iconSize,
        onTap: (value) => onToggleLike(),
        padding: widget.padding,
        showText: widget.showText,
        textWidget: widget.textWidget,
        likeColor: widget.likeColor,
        unLikeColor: widget.unLikeColor,
        gestureWrapper: widget.gestureWrapper,
        tabController: _tabController,
        likeIconData: widget.likeIconData,
        unlikeIconData: widget.unlikeIconData,
        increaseLike: widget.postData.increaseLike,
        fontWeight: widget.fontWeight,
      );
    else
      return AnimatedLikeButton(
        fontSize: widget.fontSize,
        fontColor: widget.fontColor,
        isLike: liked,
        count: count,
        iconSize: widget.iconSize,
        onTap: (value) => onToggleLike(),
        padding: widget.padding,
        showText: widget.showText,
        textWidget: widget.textWidget,
        likeColor: widget.likeColor,
        unLikeColor: widget.unLikeColor,
        gestureWrapper: widget.gestureWrapper,
        tabController: _tabController,
        likeIconData: widget.likeIconData,
        unlikeIconData: widget.unlikeIconData,
        fontWeight: widget.fontWeight,
      );
  }
}

Widget buildMobileLikeIcon(IconData iconData, Color color, double iconSize) {
  return Icon(iconData, color: color, size: iconSize);
}

typedef WidgetBuilder = Widget Function(Widget child);

///带点赞数增加的动画
// ignore: must_be_immutable
class AnimatedIncreaseLikeButton extends StatefulWidget {
  final bool isLike;
  final int count;
  final double iconSize;
  final double fontSize;
  final Color fontColor;
  final FontWeight fontWeight;
  final lb.LikeButtonTapCallback onTap;
  final EdgeInsets padding;
  final bool showText;
  final Color unLikeColor;
  final Color likeColor;
  final Widget textWidget;
  final WidgetBuilder gestureWrapper;
  final lb.TapController tabController;
  final IconData likeIconData;
  final IconData unlikeIconData;

  ///从消息列表打开动态详情时，增加的点赞数，用于动画显示
  int increaseLike;

  AnimationController controller;
  Animation<double> scales;
  Animation<Offset> positions;

  @override
  _AnimatedIncreaseLikeButtonState createState() =>
      _AnimatedIncreaseLikeButtonState();

  AnimatedIncreaseLikeButton({
    Key key,
    this.isLike = false,
    this.count,
    this.onTap,
    this.iconSize = 24,
    this.fontSize = 13,
    this.fontColor,
    this.fontWeight = FontWeight.normal,
    this.padding,
    this.showText = true,
    this.unLikeColor,
    this.likeColor,
    this.textWidget,
    this.gestureWrapper,
    this.tabController,
    this.likeIconData,
    this.unlikeIconData,
    this.increaseLike,
  }) : super(key: key);
}

class _AnimatedIncreaseLikeButtonState extends State<AnimatedIncreaseLikeButton>
    with TickerProviderStateMixin {
  AnimationController controller;
  Animation<double> scales1, scales2;
  Animation<Offset> positions;
  Animation<double> opacity, turns1, turns2;
  int animateCount = 0;

  @override
  void initState() {
    super.initState();
    animateCount = widget.count - widget.increaseLike;
    if (animateCount < 0) animateCount = 0;
    controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    scales1 = Tween<double>(
      begin: 1.5,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(
        0,
        0.25,
      ),
    ));
    turns1 = Tween<double>(
      begin: 0,
      end: -0.13,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(
        0.25,
        0.5,
      ),
    ));
    turns2 = Tween<double>(
      begin: 0,
      end: 0.13,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(
        0.5,
        0.75,
      ),
    ));
    positions = Tween(
      begin: const Offset(0, -0.8),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(
        0.75,
        1,
      ),
    ));
    scales2 = Tween<double>(
      begin: 1.5,
      end: 0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(
        0.75,
        1,
      ),
    ));
    opacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(
        0.75,
        1,
      ),
    ));

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          animateCount += widget.increaseLike;
        });
      }
    });
    //启动动画
    controller.forward();
  }

  @override
  void dispose() {
    controller?.stop();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    final primaryColor = Theme.of(context).primaryColor;
    IconData iconData;
    Color color;
    if (widget.isLike) {
      iconData = widget.likeIconData ?? IconFont.buffCircleLike2New;
      color = widget.likeColor ?? _theme.primaryColor;
    } else {
      iconData = widget.unlikeIconData ?? IconFont.buffCircleUnlike2New;
      color = widget.unLikeColor ?? const Color(0xff8f959e);
    }

    final child = Padding(
      padding: widget.padding ?? const EdgeInsets.only(left: 20, right: 16),
      child: Stack(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              lb.LikeButton(
                isLiked: widget.isLike,
                likeBuilder: (liked) {
                  return buildMobileLikeIcon(iconData, color, widget.iconSize);
                },
                size: widget.iconSize,
                onTap: widget.onTap,
                tapController: widget.tabController,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: AnimatedFlipCounter(
                  duration: const Duration(milliseconds: 500),
                  value: animateCount,
                  textStyle: TextStyle(
                    color: widget.fontColor ?? color,
                    fontSize: widget.fontSize,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
          ScaleTransition(
            scale: scales1,
            child: FadeTransition(
              opacity: opacity,
              child: ScaleTransition(
                scale: scales2,
                child: SlideTransition(
                    position: positions,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            width: widget.increaseLike < 10 ? 27 : 31,
                            height: 16,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RotationTransition(
                                  turns: turns1,
                                  child: RotationTransition(
                                    turns: turns2,
                                    child: const Icon(
                                        IconFont.buffCircleLikeSelect,
                                        color: Colors.white,
                                        size: 9),
                                  ),
                                ),
                                const SizedBox(width: 1),
                                Text(
                                  '+${widget.increaseLike > 99 ? '99' : widget.increaseLike}',
                                  style: const TextStyle(
                                      fontSize: 7, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            )),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 15, 3, 0),
                          child: Icon(IconFont.buffCircleLikeArrow,
                              color: primaryColor, size: 5),
                        ),
                      ],
                    )),
              ),
            ),
          ),
        ],
      ),
    );
    return GestureDetector(
      onTap: () {
        widget.tabController?.tap();
      },
      behavior: HitTestBehavior.opaque,
      child: widget.gestureWrapper?.call(child) ?? child,
    );
  }
}
