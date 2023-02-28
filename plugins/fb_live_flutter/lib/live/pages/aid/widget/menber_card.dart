import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget_common/image/sw_image.dart';
import 'package:flutter/material.dart';

typedef MemberCheckCall = Function(FBUserInfo? value);

class MemberCard extends StatelessWidget {
  final bool isSelect;
  final MemberCheckCall? call;
  final FBUserInfo? item;

  const MemberCard({required this.isSelect, this.call, this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (call != null) {
          call!(item);
        }
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.px),
            child: Row(
              children: [
                Space(width: 18.px),

                ///  多选按钮模糊找俊杰要多选的组件
                checkboxIcon(isSelect),
                Space(width: 11.px),
                CircleAvatar(
                  radius: 40.px / 2,
                  backgroundImage: swImageProvider(null),
                ),
                Space(width: 12.px),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item?.name ?? '',
                      style: TextStyle(
                          color: const Color(0xff363940), fontSize: 16.px),
                    ),
                    Space(height: 4.px),
                    Text(
                      '#${item?.userId ?? '0'}',
                      style: TextStyle(
                          color: const Color(0xff8F959E), fontSize: 13.px),
                    )
                  ],
                )
              ],
            ),
          ),
          HorizontalLine(
            margin:
                EdgeInsets.only(left: 11.px + 18.3.px + 18.px + (40.px / 2)),
            color: const Color(0xff8F959E).withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}
