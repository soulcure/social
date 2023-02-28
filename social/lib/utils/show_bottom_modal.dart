import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/web/widgets/slider_sheet/show_slider_sheet.dart';
import 'package:im/widgets/buttom_sheet_darg_tag.dart';
import 'package:pedantic/pedantic.dart';
import 'package:sliding_sheet/sliding_sheet.dart';

Future<T> showBottomModal<T>(
  BuildContext context, {
  @required SheetBuilder builder,
  SheetBuilder headerBuilder,
  SheetBuilder footerBuilder,
  Color backgroundColor,
  bool showTopCache = true,
  bool resizeToAvoidBottomInset = true,
  double maxHeight = 0.9,
  ScrollSpec scrollSpec = const ScrollSpec(physics: ClampingScrollPhysics()),
  bool useOriginal = false, // 用来强制弹窗
  EdgeInsets margin,
  RouteSettings routeSettings,
  double cornerRadius = 12,
  Duration animationDuration =
      const Duration(milliseconds: 350), // 自定义弹出动画时间,默认350ms
  bool bottomInset = true,
  bool maintainBottomViewPadding = false,
  bool showHalf = false, //是否显示半屏，然后拖拽显示全部.
}) async {
  // 断言成功但是控制台不会打印错误，可能是异步嵌套执行导致捕获不到错误
  assert(maxHeight > 0 && maxHeight <= 1.0);
  unawaited(HapticFeedback.selectionClick());
  if (!useOriginal)
    return showSlidingBottomSheet(context,
        routeSettings: routeSettings,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset, builder: (context) {
      return SlidingSheetDialog(
        color: backgroundColor,
        // elevation: 8,
        cornerRadius: cornerRadius,
        padding: EdgeInsets.zero,
        duration: animationDuration,
        scrollSpec: scrollSpec,
        avoidStatusBar: true,
        margin: margin ??
            (OrientationUtil.portrait
                ? const EdgeInsets.all(0)
                : EdgeInsets.only(
                    left: MediaQuery.of(context).size.width - 480)),
        snapSpec: SnapSpec(
          snappings:
              (showHalf && maxHeight > 0.66) ? [0.66, maxHeight] : [maxHeight],
          onSnap: (state, snap) {},
        ),
        headerBuilder: (context, state) {
          if (!showTopCache) return const SizedBox();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BottomSheetDragTag(),
              if (headerBuilder != null) headerBuilder(context, state),
            ],
          );
        },
        builder: (context, state) {
          return Material(
              color: backgroundColor,
              child: SafeArea(
                maintainBottomViewPadding: maintainBottomViewPadding,
                top: false,
                bottom: resizeToAvoidBottomInset && bottomInset,
                child: builder?.call(context, state),
              ));
        },
        footerBuilder: footerBuilder,
      );
    });
  else
    return showSliderModal(
      context,
      body: builder?.call(context, null),
      direction: SliderDirection.rightDown,
    );
//   return showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: backgroundColor ?? _theme.backgroundColor,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(10),
//     ),
//     builder: (_) {
//       return CacheWidget(
//         builder: () {
//           return ConstrainedBox(
//             constraints:
//                 BoxConstraints(maxHeight: Global.mediaInfo.size.height * 0.8),
//             child: ListView(
//               physics: const BouncingScrollPhysics(),
//               shrinkWrap: true,
//               children: <Widget>[
//                 if (showTopCache)
//                   Container(
//                     height: 16,
//                     alignment: Alignment.topCenter,
//                     child: Container(
//                       margin: const EdgeInsets.fromLTRB(0, 8, 0, 0),
//                       width: 48,
//                       height: 4,
//                       decoration: BoxDecoration(
//                         color: _theme.textTheme.bodyText1.color,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ),
//                   )
//                 else
//                   const SizedBox(width: 0, height: 0),
//                 body,
//                 if (Platform.isAndroid) bottomViewInset(),
//               ],
//             ),
//           );
// //
//         },
//       );
//     },
//   );
}
