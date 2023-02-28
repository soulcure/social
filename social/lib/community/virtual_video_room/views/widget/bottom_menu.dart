import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:websafe_svg/websafe_svg.dart';

import '../../../../svg_icons.dart';

enum ArrowState {
  unVisible,
  on,
  off,
}

enum FullState {
  unVisible,
  toFull,
  toMin,
}

class BottomMenu extends StatelessWidget {
  final bool isHideAll;
  final bool isVideoOn;
  final ArrowState leftState;
  final ArrowState rightState;
  final FullState fullState;
  final Function(bool isVideoOn) onVideoClick;
  final Function() onLeftClick;
  final Function() onRightClick;
  final Function(FullState fullState) onFullClick;
  final Function(bool isHideAll) onHideAllClick;

  const BottomMenu({
    Key key,
    this.isHideAll = false,
    this.isVideoOn = true,
    this.leftState = ArrowState.unVisible,
    this.rightState = ArrowState.unVisible,
    this.fullState = FullState.unVisible,
    this.onVideoClick,
    this.onLeftClick,
    this.onRightClick,
    this.onFullClick,
    this.onHideAllClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        alignment: Alignment.center,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            children: [
              ..._buildAll(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAll() {
    final List<Widget> allWidgets = [];
    // allWidgets.add(InkWell(
    //   onTap: () => onVideoClick?.call(isVideoOn),
    //   child: SizedBox(
    //     width: 48,
    //     child: Center(
    //         child: WebsafeSvg.asset(
    //             isVideoOn ? SvgIcons.virtualVideoOn : SvgIcons.virtualVideoOff,
    //             width: 16,
    //             height: 16)),
    //   ),
    // ));

    allWidgets.add(_buildLine());
    allWidgets.add(
      InkWell(
        onTap: () => onHideAllClick?.call(isHideAll),
        child: SizedBox(
          width: 48,
          child: Center(
              child: WebsafeSvg.asset(SvgIcons.virtualHideAll,
                  width: 16, height: 16)),
        ),
      ),
    );

    if (leftState == ArrowState.on) {
      allWidgets.add(_buildLine());
      allWidgets.add(InkWell(
        onTap: () => onLeftClick?.call(),
        child: SizedBox(
          width: 48,
          child: Center(
              child: WebsafeSvg.asset(SvgIcons.virtualPreOn,
                  width: 16, height: 16)),
        ),
      ));
    } else if (leftState == ArrowState.off) {
      allWidgets.add(_buildLine());
      allWidgets.add(SizedBox(
        width: 48,
        child: Center(
            child: WebsafeSvg.asset(SvgIcons.virtualPreOff,
                width: 16, height: 16)),
      ));
    }

    if (rightState == ArrowState.on) {
      allWidgets.add(_buildLine());
      allWidgets.add(InkWell(
        onTap: () => onRightClick?.call(),
        child: SizedBox(
          width: 48,
          child: Center(
              child: WebsafeSvg.asset(SvgIcons.virtualNextOn,
                  width: 16, height: 16)),
        ),
      ));
    } else if (rightState == ArrowState.off) {
      allWidgets.add(_buildLine());
      allWidgets.add(SizedBox(
        width: 48,
        child: Center(
            child: WebsafeSvg.asset(SvgIcons.virtualNextOff,
                width: 16, height: 16)),
      ));
    }

    if (fullState == FullState.toFull) {
      allWidgets.add(_buildLine());
      allWidgets.add(InkWell(
        onTap: () => onFullClick?.call(FullState.toFull),
        child: SizedBox(
          width: 48,
          child: Center(
              child: WebsafeSvg.asset(SvgIcons.virtualSwitchFull,
                  width: 16, height: 16)),
        ),
      ));
    } else if (fullState == FullState.toMin) {
      allWidgets.add(_buildLine());
      allWidgets.add(InkWell(
        onTap: () => onFullClick?.call(FullState.toMin),
        child: SizedBox(
          width: 48,
          child: Center(
              child: WebsafeSvg.asset(SvgIcons.virtualSwitchMin,
                  width: 16, height: 16)),
        ),
      ));
    }

    return allWidgets;
  }

  Widget _buildLine() => SizedBox(
        width: 1,
        height: 36,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1)),
        ),
      );
}
