// import 'package:flutter/material.dart';
// import 'package:im/icon_font.dart';
// import 'package:im/themes/const.dart';
// import 'package:im/themes/default_theme.dart';
//
// enum WindowType { small, middle, large }
//
// Future<bool> showWebConfirmDialog(
//   BuildContext context, {
//   String title = '',
//
//   /// contentText or contentWidget, 只有一个能显示， 优先显示 contentWidget
//   String contentText,
//   Widget contentWidget,
//   String confirmText = '确定'.tr,
//   TextStyle confirmStyle,
//   String cancelText = '取消'.tr,
//   Function onCancel,
//   Function onConfirm,
//   bool showCancelButton = true,
//   bool isTipStyle = false,
//   bool isCloseBtnVisable = false,
//
//   /// windowWidth or type  二选一， 优先 windowWidth
//   double windowWidth,
//   WindowType type = WindowType.small,
// }) async {
//   return showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) {
//         return WebConfirmDialog(
//           title: title,
//           contentText: contentText,
//           confirmText: confirmText,
//           contentWidget: contentWidget,
//           confirmStyle: confirmStyle,
//           cancelText: cancelText,
//           onCancel: onCancel,
//           onConfirm: onConfirm,
//           showCancelButton: showCancelButton,
//           isTipStyle: isTipStyle,
//           isCloseBtnVisable: isCloseBtnVisable,
//           windowWidth: windowWidth,
//           type: type,
//         );
//       });
// }
//
// class WebConfirmDialog extends StatefulWidget {
//   final String title;
//   final Widget contentWidget;
//   final String contentText;
//   final String confirmText;
//   final TextStyle confirmStyle;
//   final String cancelText;
//   final Function onCancel;
//   final Function onConfirm;
//   final bool showCancelButton;
//   final ValueNotifier<bool> disableConfirm;
//
//   /// 窗口宽度
//   final double windowWidth;
//   final WindowType type;
//
//   /// 是否是提示样式，是的话 标题前会加感叹号， 确认按钮也会变成红色
//   final bool isTipStyle;
//
//   /// 是否需要右上角的 "X" 按钮
//   final bool isCloseBtnVisable;
//
//   WebConfirmDialog(
//       {this.title = '',
//       this.contentWidget,
//       this.contentText,
//       this.confirmText = '确定'.tr,
//       this.confirmStyle,
//       this.cancelText = '取消'.tr,
//       this.onCancel,
//       this.onConfirm,
//       this.showCancelButton = true,
//       this.isTipStyle = false,
//       this.isCloseBtnVisable = false,
//       this.windowWidth,
//       this.type = WindowType.small,
//       this.disableConfirm});
//
//   @override
//   _WebConfirmDialogState createState() => _WebConfirmDialogState();
// }
//
// class _WebConfirmDialogState extends State<WebConfirmDialog> {
//   ValueNotifier<bool> _disableConfirm;
//   @override
//   void initState() {
//     _disableConfirm = widget.disableConfirm ?? ValueNotifier(false);
//     super.initState();
//   }
//
//   Widget _header() {
//     final _theme = Theme.of(context);
//     return SizedBox(
//         height: 56,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 sizeWidth24,
//                 if (widget.isTipStyle) ...[
//                   Icon(
//                     IconFont.buffChatError,
//                     size: 20,
//                     color: _theme.errorColor,
//                   ),
//                   sizeWidth8,
//                 ],
//                 Text(
//                   widget.title,
//                   style: _theme.textTheme.bodyText2
//                       .copyWith(fontSize: 16, fontWeight: FontWeight.w500),
//                 )
//               ],
//             ),
//             Visibility(
//               visible: widget.isCloseBtnVisable,
//               child: Padding(
//                 padding: const EdgeInsets.only(right: 24),
//                 child: SizedBox(
//                   width: 24,
//                   height: 24,
//                   child: FlatButton(
//                       padding: const EdgeInsets.all(0),
//                       onPressed: () => Navigator.of(context).pop(),
//                       child: Icon(
//                         IconFont.buffTabClose,
//                         size: 16,
//                         color: _theme.textTheme.bodyText1.color,
//                       )),
//                 ),
//               ),
//             )
//           ],
//         ));
//   }
//
//   Widget _footer() {
//     final _theme = Theme.of(context);
//     return SizedBox(
//       height: 64,
//       child: Row(
//         textDirection: TextDirection.rtl,
//         children: [
//           sizeWidth24,
//           SizedBox(
//             width: 88,
//             height: 32,
//             child: ValueListenableBuilder<bool>(
//                 valueListenable: _disableConfirm,
//                 builder: (context, disableConfirm, child) {
//                   return FlatButton(
//                       onPressed: disableConfirm
//                           ? null
//                           : widget.onConfirm ??
//                               () => Navigator.of(context).pop(true),
//                       padding: const EdgeInsets.all(0),
//                       child: Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(4),
//                           color: disableConfirm
//                               ? const Color(0xFF6179f2).withOpacity(0.4)
//                               : widget.isTipStyle
//                                   ? _theme.errorColor
//                                   : _theme.primaryColor,
//                         ),
//                         alignment: Alignment.center,
//                         child: Text(
//                           widget.confirmText,
//                           style: widget.confirmStyle ??
//                               _theme.textTheme.bodyText2
//                                   .copyWith(color: Colors.white),
//                         ),
//                       ));
//                 }),
//           ),
//           sizeWidth16,
//           SizedBox(
//             width: 88,
//             height: 32,
//             child: FlatButton(
//                 onPressed:
//                     widget.onCancel ?? () => Navigator.of(context).pop(false),
//                 padding: const EdgeInsets.all(0),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(4),
//                     border:
//                         Border.all(color: Theme.of(context).dividerTheme.color),
//                     color: _theme.backgroundColor,
//                   ),
//                   alignment: Alignment.center,
//                   child: Text(
//                     widget.cancelText,
//                     style: _theme.textTheme.bodyText2,
//                   ),
//                 )),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final _theme = Theme.of(context);
//     return Center(
//       child: Container(
//         width: widget.windowWidth ?? windowWith,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(4),
//           color: _theme.backgroundColor,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _header(),
//             if (windowWith > 440) divider,
//             if (widget.contentWidget != null)
//               widget.contentWidget
//             else if (widget.contentText != null)
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 64),
//                 height: 38,
//                 alignment: Alignment.topLeft,
//                 child: Text(
//                   widget.contentText,
//                   style: _theme.textTheme.bodyText1,
//                   textAlign: TextAlign.left,
//                 ),
//               )
//             else
//               sizeHeight24,
//             if (windowWith > 440) divider,
//             _footer(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   double get windowWith {
//     switch (widget.type) {
//       case WindowType.small:
//         return 440;
//       case WindowType.middle:
//         return 800;
//       case WindowType.large:
//         return 1040;
//     }
//     return 440;
//   }
//
//   @override
//   void dispose() {
//     _disableConfirm?.dispose();
//     super.dispose();
//   }
// }
