import 'package:flutter/material.dart';

class LivePlayMaskWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final bool showMask;

  const LivePlayMaskWidget({
    this.onTap,
    this.showMask = false,
  });

  @override
  _LivePlayMaskWidgetState createState() => _LivePlayMaskWidgetState();
}

class _LivePlayMaskWidgetState extends State<LivePlayMaskWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.showMask == false) {
      return Container();
    }
    return GestureDetector(
      onTap: widget.onTap,
      child: const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Icon(
            Icons.play_circle_outline_sharp,
            size: 56,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
