import 'package:flutter/material.dart';
import '../../../utils/ui/frame_size.dart';

typedef OnlineCountCallback = void Function();

class OnlineCountView extends StatefulWidget {
  final String? count;
  final OnlineCountCallback? onlineCountCallback;

  const OnlineCountView({Key? key, this.count = "0", this.onlineCountCallback})
      : super(key: key);

  @override
  _OnlineCountViewState createState() => _OnlineCountViewState();
}

class _OnlineCountViewState extends State<OnlineCountView> {
  OnlineCountCallback? onlineCountCallback;

  @override
  void initState() {
    super.initState();
    onlineCountCallback = widget.onlineCountCallback;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onlineCountCallback!();
      },
      child: Container(
        alignment: Alignment.center,
        width: FrameSize.px(41),
        height: FrameSize.px(30),
        decoration: BoxDecoration(
          color: const Color(0x8C000000).withOpacity(0.4),
          borderRadius: BorderRadius.circular(FrameSize.px(22.5)),
        ),
        child: Text(
          widget.count == null ? "0" : widget.count.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: Colors.white,
              fontSize: FrameSize.px(11),
              fontWeight: FontWeight.w300),
        ),
      ),
    );
  }
}
