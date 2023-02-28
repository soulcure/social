import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:im/web/widgets/web_form_detector/web_form_detector_model.dart';
import 'package:provider/provider.dart';

class WebFormDetector extends StatefulWidget {
  final Widget child;
  final GestureTapCallback onTap;
  const WebFormDetector({@required this.child, @required this.onTap});
  @override
  _WebFormDetectorState createState() => _WebFormDetectorState();
}

class _WebFormDetectorState extends State<WebFormDetector> {
  Animation<double> offsetAnim;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final model =
              Provider.of<WebFormDetectorModel>(context, listen: false);
          if (model.changed.value) {
            model.animate();
            return;
          }
          widget.onTap?.call();
        },
        child: widget.child,
      ),
    );
  }
}
