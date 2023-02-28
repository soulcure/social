import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/*
* 选择频道对话框
* */
Future<int?> selectFbMockDialog(
  BuildContext context, {
  List<Widget>? actions,
  String? title,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return SelectFbMockDialog(actions, title);
    },
  );
}

class SelectFbMockDialog extends StatefulWidget {
  final List<Widget>? actions;
  final String? title;

  const SelectFbMockDialog(this.actions, this.title);

  @override
  _SelectFbMockDialogState createState() => _SelectFbMockDialogState();
}

class _SelectFbMockDialogState extends State<SelectFbMockDialog> {
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: (50 * (widget.actions!.length)).px + 69.px + 50.5.px,
        margin: const EdgeInsets.only(top: 50),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10.px)),
        ),
        child: Column(
          children: [
            Container(
              height: 50.px,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: MyTheme.mainBottomBorder()),
              child: Text(
                "模拟: ${widget.title}",
                style:
                    TextStyle(color: const Color(0xff646A73), fontSize: 14.px),
              ),
            ),
            Expanded(
              child: CupertinoScrollbar(
                child: SingleChildScrollView(
                  child: Column(
                      children: List.generate(widget.actions!.length, (index) {
                    final Widget item = widget.actions![index];
                    return ClickEvent(
                      onTap: () async {
                        return RouteUtil.pop(index);
                      },
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        child: item,
                      ),
                    );
                  })),
                ),
              ),
            ),
            const HorizontalLine(height: 8),
            SizedBox(
              height: 60.px,
              width: FrameSize.winWidth(),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  '取消',
                  style: TextStyle(
                      color: const Color(0xff1F2125), fontSize: 17.px),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
* 选择频道对话框
* */
Future selectChannelDialog(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return SelectChannelDialog();
    },
  );
}

class SelectChannelDialog extends StatefulWidget {
  @override
  _SelectChannelState createState() => _SelectChannelState();
}

class _SelectChannelState extends State<SelectChannelDialog> {
  List<FBChatChannel> data = [];

  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() {
    final String? serverId = fbApi.getCurrentChannel()!.guildId;
    data = fbApi.getGuildChannels(serverId!);
    setState(() {});
  }

  Widget itemBuild(FBChatChannel e) {
    return Container(
      height: 50.px,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: e == data[data.length - 1]
                ? Colors.transparent
                : Colors.grey.withOpacity(0.5),
            width: 0.2,
          ),
        ),
      ),
      width: FrameSize.screenW(),
      child: TextButton(
        onPressed: () => Navigator.of(context).pop(e),
        style: ButtonStyle(
          padding: MaterialStateProperty.all(EdgeInsets.zero),
        ),
        child: Text(
          e.name,
          style: TextStyle(
            color: const Color(0xff1F2125),
            fontSize: 17.px,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: (50 * data.length).px + 69.px,
        margin: const EdgeInsets.only(top: 50),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(10.px)),
        ),
        child: Column(
          children: [
            Expanded(
              child: CupertinoScrollbar(
                child: SingleChildScrollView(
                  child: Column(children: data.map<Widget>(itemBuild).toList()),
                ),
              ),
            ),
            const HorizontalLine(height: 8),
            SizedBox(
              height: 60.px,
              width: FrameSize.winWidth(),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  '取消',
                  style: TextStyle(
                      color: const Color(0xff1F2125), fontSize: 17.px),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
