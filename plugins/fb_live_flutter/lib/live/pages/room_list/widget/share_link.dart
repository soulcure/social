import 'package:flutter/material.dart';
import 'package:fb_live_flutter/live/utils/theme/my_theme.dart';
import '../../../utils/ui/frame_size.dart';
import '../../../utils/func/utils_class.dart';
import '../../../widget_common/button/sw_web_button.dart';
import '../../../widget_common/text/sw_text_span.dart';
import '../../../widget_common/text_field/sw_web_text_field.dart';

class ShareLink extends StatefulWidget {
  @override
  _ShareLinkState createState() => _ShareLinkState();
}

class _ShareLinkState extends State<ShareLink> {
  TextEditingController controller =
      TextEditingController(text: 'https://fanbook.mobi/mal2EFG9');
  static FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => focusNode.unfocus(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '分享此链接，即可观看回放',
            style: TextStyle(
              fontSize: FrameSize.px(14),
              color: const Color(0xff8F959E),
            ),
          ),
          SizedBox(height: 24.px),
          Row(
            children: [
              Expanded(
                  child: SwWebTextField(
                controller: controller,
                focusNode: focusNode,
              )),
              SizedBox(width: 16.px),
              SwWebButton(
                text: '复制',
                bgColor: MyTheme.blueColor,
                textColor: MyTheme.whiteColor,
                onPressed: () => copyText(controller.text, '复制成功'),
                isPop: false,
              ),
            ],
          ),
          SizedBox(height: FrameSize.px(16)),
          SwTextRich(
            text1: '您的邀请链接永久有效，无限次数。',
            text2: '编辑邀请链接',
            onTap: () {
              Future.delayed(Duration.zero).then((value) {
                focusNode.requestFocus();
                setState(() {});
              });
            },
          ),
        ],
      ),
    );
  }
}
