// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/modules/circle_search/controllers/circle_search_controller.dart';
import 'package:im/common/permission/permission.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/universal_platform.dart';

import '../../../../icon_font.dart';
import '../../../../routes.dart';

const kNavigationBarHeight = 44.0;

class CircleFlexibleSpaceBar extends StatefulWidget {
  final CircleInfoDataModel circleInfo;
  final int nuReadNewsNum;
  final double ignoreMoveHeight;

  /// Creates a flexible space bar.
  ///
  /// Most commonly used in the [AppBar.flexibleSpace] field.
  const CircleFlexibleSpaceBar({
    Key key,
    this.background,
    this.collapseMode = CollapseMode.parallax,
    this.stretchModes = const <StretchMode>[StretchMode.zoomBackground],
    this.circleInfo,
    this.nuReadNewsNum,
    this.ignoreMoveHeight = 0,
  })  : assert(collapseMode != null),
        super(key: key);

  /// Shown behind the [title] when expanded.
  ///
  /// Typically an [Image] widget with [Image.fit] set to [BoxFit.cover].
  final Widget Function(double opacity, double ignoredOpacity) background;

  /// Collapse effect while scrolling.
  ///
  /// Defaults to [CollapseMode.parallax].
  final CollapseMode collapseMode;

  /// Stretch effect while over-scrolling.
  ///
  /// Defaults to include [StretchMode.zoomBackground].
  final List<StretchMode> stretchModes;

  @override
  _CircleFlexibleSpaceBarState createState() => _CircleFlexibleSpaceBarState();
}

class _CircleFlexibleSpaceBarState extends State<CircleFlexibleSpaceBar> {
  bool _hasCircleManagerPermission = false;
  int _nuReadNewsNum = 0;

  @override
  void initState() {
    super.initState();
    final GuildPermission gp = PermissionModel.getPermission(
        ChatTargetsModel.instance?.selectedChatTarget?.id);
    if (gp != null) {
      _hasCircleManagerPermission =
          PermissionUtils.oneOf(gp, [Permission.MANAGE_CIRCLES]);
    }

    _nuReadNewsNum = widget.nuReadNewsNum;
  }

  double _getCollapsePadding(double t, FlexibleSpaceBarSettings settings) {
    switch (widget.collapseMode) {
      case CollapseMode.pin:
        return -(settings.maxExtent - settings.currentExtent);
      case CollapseMode.none:
        return 0;
      case CollapseMode.parallax:
        final double deltaExtent = settings.maxExtent - settings.minExtent;
        return -Tween<double>(begin: 0, end: deltaExtent / 4.0).transform(t);
    }
    // ignore: avoid_returning_null
    return null;
  }

  @override
  Widget build(BuildContext context) {
    double redDotPositionX = 0;
    if (_nuReadNewsNum <= 0) {
      redDotPositionX = 0;
    } else if (_nuReadNewsNum < 10) {
      redDotPositionX = 23;
    } else if (_nuReadNewsNum < 100) {
      redDotPositionX = 23;
    } else {
      redDotPositionX = 15;
    }
    return LayoutBuilder(builder: (context, constraints) {
      final FlexibleSpaceBarSettings settings = context
          .dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
      assert(
        settings != null,
        'A FlexibleSpaceBar must be wrapped in the widget returned by FlexibleSpaceBar.createSettings().',
      );

      final List<Widget> children = <Widget>[];

      final double deltaExtent = settings.maxExtent - settings.minExtent;
      final double t =
          (1.0 - (settings.currentExtent - settings.minExtent) / deltaExtent)
              .clamp(0.0, 1.0) as double;
      // final buttonColor =
      //     ColorTween(begin: Colors.white, end: Colors.black).transform(t);
      // final double fadeStart = math.max(0, 1.0 - kToolbarHeight / deltaExtent);
      final fadeStart = (widget.ignoreMoveHeight / deltaExtent).abs();
      const double fadeEnd = 0.7;
      assert(fadeStart <= fadeEnd);
      final double opacity = 1.0 - Interval(fadeStart, fadeEnd).transform(t);
      final double ignoredOpacity = 1.0 - Interval(0, fadeStart).transform(t);

      // background
      if (widget.background != null) {
        double height = settings.maxExtent;

        // StretchMode.zoomBackground
        if (widget.stretchModes.contains(StretchMode.zoomBackground) &&
            constraints.maxHeight > height) {
          height = constraints.maxHeight;
        }
        final moveY = _getCollapsePadding(t, settings);
        children.add(Positioned(
          top: widget.ignoreMoveHeight < moveY
              ? 0
              : moveY - widget.ignoreMoveHeight,
          left: 0,
          right: 0,
          height: height,
          child: widget.background(opacity, ignoredOpacity),
        ));
      }

      final navigationBar = _buildMobileNavigationBar(opacity, redDotPositionX);
      children.add(
        Align(
            alignment: Alignment.topLeft,
            child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kNavigationBarHeight,
                  child: navigationBar,
                ))),
      );
      return Stack(children: children);
    });
  }

  Widget _buildMobileNavigationBar(double opacity, double redDotPositionX) {
    return NavigationToolbar(
        middle: Opacity(
          opacity: 1 - opacity,
          child: Text(
            widget.circleInfo?.circleName ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        leading: SizedBox(
          width: kNavigationBarHeight,
          child: _buildActionIconButton(
            IconFont.buffNavBarBackItemNew,
            Colors.white,
            () => Routes.pop(context),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionIconButton(
              IconFont.buffCommonSearchNew,
              Colors.white,
              () {
                // Get.toNamed(AppPages.Routes.CIRCLE_SEARCH);
                Routes.pushCircleSearchPage(context, widget.circleInfo.guildId,
                        widget.circleInfo.channelId)
                    .then((value) {
                  Get.delete<CircleSearchController>(
                      tag: widget.circleInfo.guildId);
                });
              },
            ),
            // 隐藏圈子消息中心入口
            if (!UniversalPlatform.isMobileDevice) const SizedBox(width: 4),
            if (!UniversalPlatform.isMobileDevice)
              RedDot(
                _nuReadNewsNum,
                offset: Offset(redDotPositionX, 4),
                child: _buildActionIconButton(
                  IconFont.buffCircleNotice,
                  Colors.white,
                  () async {
                    await Routes.pushCircleNewsPage(
                        context, widget.circleInfo.channelId);
                    final result = await CircleApi.circleUnreadNewsCount(
                        widget.circleInfo.channelId);
                    _nuReadNewsNum = int.tryParse(result['total'].toString());
                    setState(() {});
                  },
                ),
              ),
            const SizedBox(width: 4),
            Visibility(
              visible: _hasCircleManagerPermission,
              child: _buildActionIconButton(
                IconFont.buffSetting,
                Colors.white,
                () =>
                    Routes.pushCircleManagementPage(context, widget.circleInfo),
              ),
            ),
            sizeWidth4
          ],
        ));
  }

  Widget _buildActionIconButton(
      IconData icon, Color color, void Function() onPressed) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          height: kNavigationBarHeight,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          alignment: Alignment.centerLeft,
          child: Icon(icon, color: color, size: 24),
        ));
  }
}
