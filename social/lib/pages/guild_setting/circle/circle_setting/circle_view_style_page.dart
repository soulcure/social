import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/circle_setting/model/circle_management_model.dart';
import 'package:im/svg_icons.dart';
import 'package:im/widgets/app_bar/appbar_button.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:websafe_svg/websafe_svg.dart';

class CircleViewStylePage extends StatefulWidget {
  final TopicsModel topicsModel;
  final int topicIndex;

  const CircleViewStylePage(this.topicsModel, this.topicIndex, {Key key})
      : super(key: key);

  @override
  _CircleViewStylePageState createState() => _CircleViewStylePageState();
}

class _CircleViewStylePageState extends State<CircleViewStylePage> {
  int showType = 0;

  @override
  void initState() {
    super.initState();
    final topic = widget.topicsModel.topics[widget.topicIndex];
    showType = topic.showType;
  }

  Future<void> doneAction() async {
    final topic = widget.topicsModel.topics[widget.topicIndex];
    try {
      await widget.topicsModel
          .setupViewStyleTopic(widget.topicIndex, topic.topicId, showType);
      topic.showType = showType;
    } catch (_) {}

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        leadingBuilder: (icon) {
          return IconButton(
              icon: Icon(
                IconFont.buffNavBarCloseItem,
                size: icon.size,
                color: icon.color,
              ),
              onPressed: () {
                Get.back();
              });
        },
        title: '圈子频道样式设置'.tr,
        actions: [
          AppbarTextButton(text: '完成'.tr, onTap: doneAction),
        ],
      ),
      body: SizedBox(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '分类浏览样式'.tr,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(fontSize: 13),
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    cardOptionWidget(SvgIcons.circleViewStyleDefault,
                        showType == 0, '默认样式'.tr, () {
                      setState(() {
                        showType = 0;
                      });
                    }),
                    cardOptionWidget(SvgIcons.circleViewStyleDouble,
                        showType == 1, '双卡片样式'.tr, () {
                      setState(() {
                        showType = 1;
                      });
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget cardOptionWidget(
    String asset,
    bool isSelect,
    String title,
    GestureTapCallback callback,
  ) {
    final icon =
        isSelect ? IconFont.buffSelectSingle : IconFont.buffUnselectSingle;
    final color = isSelect ? Get.theme.primaryColor : const Color(0xff8F959E);

    return GestureDetector(
      onTap: callback,
      child: SizedBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 156,
              height: 254,
              child: WebsafeSvg.asset(asset),
            ),
            SizedBox(
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Text(
                    title,
                    style:
                        const TextStyle(color: Color(0xff212733), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
