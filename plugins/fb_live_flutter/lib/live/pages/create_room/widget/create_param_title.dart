import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/material.dart';

class CreateParamTitle extends StatelessWidget {
  final String title;
  final String subTitle;
  final String? detUrl;

  const CreateParamTitle(this.title, this.subTitle, {this.detUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 36.px),
      child: ClickEvent(
        onTap: () async {
          if (strNoEmpty(detUrl)) {
            await fbApi.pushLinkPage(context, detUrl!);
          }
        },
        child: Column(
          children: [
            Row(
              children: [
                VerticalLine(
                  color: const Color(0xff6179F2),
                  width: 2.px,
                  height: 16.px,
                ),
                Space(width: 8.px),
                Text(
                  title,
                  style: TextStyle(
                      color: const Color(0xff6D6F73), fontSize: 12.px),
                )
              ],
            ),
            Space(height: 10.px),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subTitle,
                  style: TextStyle(
                    color: const Color(0xff000000),
                    fontSize: 14.px,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10.px),
                  child: Text(
                    strNoEmpty(detUrl) ? '查看详情' : '',
                    style: TextStyle(
                        color: const Color(0xff1442CC), fontSize: 12.px),
                  ),
                )
              ],
            ),
            Space(height: 21.px),
          ],
        ),
      ),
    );
  }
}
