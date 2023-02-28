import 'package:flutter/material.dart';
import '../../utils/ui/frame_size.dart';

void showSwBottomSheet(
  BuildContext context,
  final List list, {
  final Function(int index)? onTap,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return SwBottomSheet(
        list,
        onTap: onTap,
      );
    },
  );
}

class SwBottomSheet extends StatelessWidget {
  final List list; //底部弹出栏数组
  final Function(int index)? onTap;

  const SwBottomSheet(this.list, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final double _height = FrameSize.px(65.15);
    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        child: Container(
          height: _height * list.length + FrameSize.padBotH(),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: List.generate(list.length, (index) {
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onTap!(index);
                    },
                    child: Container(
                      height: _height,
                      alignment: Alignment.center,
                      width: FrameSize.winWidth(),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: index == (list.length - 1)
                                  ? Colors.transparent
                                  : const Color(0xff8f959e).withOpacity(0.2),
                              width: FrameSize.px(0.5)),
                        ),
                      ),
                      child: Text(
                        list[index],
                        style: TextStyle(
                          fontSize: FrameSize.px(17),
                          color: const Color(0xff1f2125),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
