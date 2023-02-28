import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:im/web/utils/web_util/web_util.dart';

class ContextMenuDetector extends StatelessWidget {
  final PointerDownEventListener onContextMenu;
  final Widget child;
  const ContextMenuDetector(
      {@required this.child, @required this.onContextMenu});
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (e) {
        if (e.kind == PointerDeviceKind.mouse && e.buttons == 2) {
          WebConfig.disableContextMenu();
          onContextMenu?.call(e);
        }
      },
      child: child,
    );
  }
}
