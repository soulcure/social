import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:future_or/future_or.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/utils.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

Type typeOf<X>() => X;

/// 通用底部选项列表弹窗
///
/// [T]只支持[int]和[ValueKey]<int>两种返回格式，不传默认返回[int]
///
/// [actions] Widget选项列表
///
/// 当[T]为[int]时，返回当前点击的选项索引，取消返回-1，点击空白处返回null
///
/// 当[T]为[ValueKey]<int>时，每个action组件必须传入ValueKey，
/// 返回当前点击的选项的key，取消返回ValueKey(-1)，点击空白处返回null，
/// 示例：
/// final actions = [Text('选项A',key: const ValueKey(1))];
/// showCustomActionSheet<ValueKey<int>>(actions);
///
/// [footerFixed] 是否固定底部取消按钮，当列表可以滚动时需固定
Future<T> showCustomActionSheet<T>(
  List<FutureOr<Widget>> actions, {
  bool footerFixed = false,
  String title,
  Function onCancel,
  Function onConfirm,
  double firstDividerHeight = 1,
  Duration routeDuration = const Duration(milliseconds: 300),
  String cancelText = '取消',
  TextStyle cancelStyle,
}) {
  assert(typeOf<T>() == typeOf<ValueKey<int>>() ||
      typeOf<T>() == typeOf<int>() ||
      typeOf<T>() == typeOf<dynamic>());

  final returnValueKey = typeOf<T>() == typeOf<ValueKey<int>>();
  Widget _cancelButton(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: FadeBackgroundButton(
        backgroundColor: Theme.of(context).backgroundColor,
        tapDownBackgroundColor: CustomColor(context).backgroundColor7,
        onTap: onCancel ??
            () => Navigator.of(context)
                .pop(returnValueKey ? const ValueKey(-1) : -1),
        child: Text(
          cancelText.tr,
          style: cancelStyle ??
              Theme.of(context).textTheme.bodyText2.copyWith(fontSize: 16),
        ),
      ),
    );
  }

  final backgroundColor = Get.theme.backgroundColor;

  return showSlidingBottomSheet<T>(Get.context, resizeToAvoidBottomInset: false,
      builder: (context) {
    // final controller = SheetController();
    return SlidingSheetDialog(
      axisAlignment: 1,
      color: CustomColor(context).backgroundColor7,
      extendBody: true,
      elevation: 8,
      // controller: controller,
      cornerRadius: 12,
      padding: EdgeInsets.zero,
      duration: routeDuration,
      scrollSpec: const ScrollSpec(physics: ClampingScrollPhysics()),
      avoidStatusBar: true,
      snapSpec: SnapSpec(
        snappings: const [0.9],
        onSnap: (state, snap) {},
      ),
      footerBuilder: (context, state) {
        return !footerFixed
            ? const SizedBox()
            : Material(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    sizeHeight8,
                    _cancelButton(context),
                  ],
                ),
              );
      },
      builder: (_, state) {
        final theme = Theme.of(context);
        return Material(
          child: Column(
            children: [
              if (title != null)
                Container(
                  width: MediaQuery.of(context).size.width,
                  constraints: const BoxConstraints(minHeight: 75),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    color: theme.backgroundColor,
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(50, 22, 50, 22),
                    alignment: Alignment.center,
                    child: Text(
                      title.tr,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              if (title != null)
                Divider(
                  color: theme.scaffoldBackgroundColor,
                ),
              for (var i = 0; i < actions.length; i++) ...[
                FutureOrBuilder(
                    futureOr: actions[i],
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done)
                        return const SizedBox();

                      if (snapshot.data is SizedBox &&
                          (snapshot.data as SizedBox).height == null)
                        return snapshot.data;

                      SheetController.of(context).expand();
                      // SheetController.of(context).scrollTo(100000, duration: Duration(seconds: 2));

                      if (actions[i] == null)
                        return Divider(
                          color: theme.scaffoldBackgroundColor,
                          height: 8,
                          thickness: firstDividerHeight > 1 ? 0.0 : 8,
                        );
                      return ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: FadeBackgroundButton(
                          backgroundColor: backgroundColor,
                          tapDownBackgroundColor:
                              CustomColor(context).backgroundColor7,
                          onTap: onConfirm ??
                              () async {
                                ValueKey key;
                                if (actions[i] is Widget) {
                                  key = (actions[i] as Widget).key;
                                } else {
                                  key = (await actions[i]).key;
                                }
                                Navigator.of(context)
                                    .pop(returnValueKey ? key : i);
                              },
                          child: snapshot.data is Widget
                              ? snapshot.data
                              : actions[i],
                        ),
                      );
                    }),
                if (i != actions.length - 1)
                  FutureOrBuilder(
                      futureOr: actions[i],
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done)
                          return const SizedBox();
                        return Divider(
                          color: theme.scaffoldBackgroundColor,
                          height: firstDividerHeight,
                        );
                      })
              ],
              Divider(
                color: theme.scaffoldBackgroundColor,
                height: 8,
                thickness: firstDividerHeight > 1 ? 0.0 : 8,
              ),
              if (!footerFixed) _cancelButton(context),
              Container(
                color: theme.backgroundColor,
                height: getBottomViewInset(),
              )
            ],
          ),
        );
      },
    );
  });
}
