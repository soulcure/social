import 'package:flutter/material.dart';

import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/show_right_dialog.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget/view/dialog_top_bar.dart';

typedef GoodsWidgetsBuilder = List<Widget> Function(
    BuildContext context, StateSetter setState);

Future showGoodsDialog(
  BuildContext context, {
  GoodsWidgetsBuilder? builder,
  Widget? child,
  double? rateValue,
}) {
  final double rate = rateValue ?? (609 / 821);
  return showBottomSheetCommonDialog(
    context,

    /// 修复键盘被顶起
    resizeToAvoidBottomInset: false,
    height: rate,
    child: Container(
      height: FrameSize.maxValue() * rate,
      width: FrameSize.winWidth(),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: SafeArea(
        top: false,
        child: ShowGoodsDialog(builder, child),
      ),
    ),
  );
}

class ShowGoodsDialog extends StatefulWidget {
  final GoodsWidgetsBuilder? builder;
  final Widget? child;

  const ShowGoodsDialog(this.builder, this.child);

  @override
  _ShowGoodsDialogState createState() => _ShowGoodsDialogState();
}

class _ShowGoodsDialogState extends State<ShowGoodsDialog> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 【2021 12.02】加对话框拖拽效果后需要显示
        /// 取消底部弹出对话框头部横条
        DialogTopBar(),
        Space(height: 8.px),
        if (widget.builder != null) ...widget.builder!(context, setState),
        widget.child ?? Container(),
      ],
    );
  }
}
