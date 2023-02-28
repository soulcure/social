import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/home/views/components/chat_index/guild_banner/guild_banner.dart';
import 'package:im/app/modules/home/views/components/chat_index/guild_banner/guild_banner_title.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:simple_shadow/simple_shadow.dart';
import '../../../../../../../icon_font.dart';

const double kBannerMinHeight = kToolbarHeight;

class SliverGuildBanner extends StatefulWidget {
  static double collapsedHeight = kBannerMinHeight;

  final GuildTarget target;

  // banner高度
  final double height;

  // 当前列表滚动偏移量
  final RxDouble rxScrollOffset;

  const SliverGuildBanner({
    Key key,
    @required this.target,
    @required this.height,
    @required this.rxScrollOffset,
  }) : super(key: key);

  @override
  _SliverGuildBannerState createState() => _SliverGuildBannerState();
}

class _SliverGuildBannerState extends State<SliverGuildBanner> {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      primary: false,
      pinned: true,
      elevation: 0,
      titleSpacing: 0,
      collapsedHeight: SliverGuildBanner.collapsedHeight,
      title: IgnorePointer(
        child: ObxValue<RxDouble>((scrollOffset) {
          final titleAnimateProcess =
              _getTitleAnimateProcess(scrollOffset.value);
          Color titleBgColor;
          if (scrollOffset > (widget.height - kBannerMinHeight)) {
            titleBgColor = Get.theme.backgroundColor;
          } else {
            titleBgColor = null;
          }
          return _CollapseTitle(
            bannerMinHeight: kBannerMinHeight,
            backgroundColor: titleBgColor,
            animateProcess: titleAnimateProcess,
          );
        }, widget.rxScrollOffset),
      ),
      // ignore:avoid_redundant_argument_values
      toolbarHeight: kBannerMinHeight,
      expandedHeight: widget.height,
      backgroundColor: Colors.transparent,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.none,
        // ignore: prefer_const_literals_to_create_immutables
        stretchModes: [StretchMode.zoomBackground],
        background: GuildBanner(
          target: widget.target,
        ),
      ),
    );
  }

  double _getTitleAnimateProcess(double scrollOffset) {
    // 从下往上滚动时的动画起始和结束高度
    const animateStartHeight = 65;
    const animateEndHeight = 80;
    if (scrollOffset < animateStartHeight) {
      return 0;
    } else if (scrollOffset >= animateStartHeight &&
        scrollOffset <= animateEndHeight) {
      final o = (scrollOffset - animateStartHeight) /
          (animateEndHeight - animateStartHeight);
      return o;
    } else {
      return 1;
    }
  }
}

// 标题栏
class _CollapseTitle extends StatelessWidget {
  const _CollapseTitle({
    Key key,
    @required double bannerMinHeight,
    this.backgroundColor,
    this.animateProcess = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  })  : kBannerMinHeight = bannerMinHeight,
        super(key: key);

  final double kBannerMinHeight;
  final double animateProcess;
  final Color backgroundColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final titleColor = _getTitleColor(animateProcess);
    final titleShadows = _getTitleShadows(animateProcess);
    final moreIconOpacity = _getMoreIconOpacity(animateProcess);
    final moreIconSigma = _getMoreIconSigma(animateProcess);
    return Container(
      height: kBannerMinHeight,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: GuildBannerName(
              style: TextStyle(color: titleColor),
              textShadows: titleShadows,
            ),
          ),
          SimpleShadow(
            opacity: moreIconOpacity,
            sigma: moreIconSigma,
            offset: Offset.zero,
            child: Icon(
              IconFont.buffMoreHorizontal,
              size: 24,
              color: titleColor,
            ),
          )
        ],
      ),
    );
  }

  Color _getTitleColor(double process) {
    return ColorTween(begin: Colors.white, end: Get.textTheme.headline5.color)
        .transform(process);
  }

  List<BoxShadow> _getTitleShadows(double process) {
    final radius = IntTween(begin: 2, end: 0).transform(process).toDouble();
    final alpha = IntTween(begin: 126, end: 0).transform(process);
    return [
      BoxShadow(
        color: Colors.black.withAlpha(alpha),
        blurRadius: radius,
      )
    ];
  }

  double _getMoreIconOpacity(double process) {
    // 背景色最大alpha为126
    return (1 - animateProcess) * (126 / 255);
  }

  double _getMoreIconSigma(double process) {
    return IntTween(begin: 1, end: 0).transform(process).toDouble();
  }
}
