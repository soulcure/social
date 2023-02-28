import 'package:dynamic_card/widgets/all.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:im/pages/home/json/text_chat_json.dart';

import '../../icon_font.dart';
import 'dynamic_widget.dart';

class DynamicPage extends StatelessWidget {
  final Map<String, dynamic> json;
  final MessageEntity message;
  final String title;

  const DynamicPage({Key key, @required this.json, this.message, this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            IconFont.buffNavBarBackItem,
            color: Theme.of(context).textTheme.bodyText2.color,
          ),
          onPressed: Get.back,
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              IconFont.buffNavBarCloseItem,
              color: Theme.of(context).textTheme.bodyText2.color,
            ),
            onPressed: Get.back,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 60, 56, 0),
              child: Text(
                title ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF363940),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.27),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(
                    height: 24,
                  ),
                  const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 12),
                      child: Text(
                        "请完成下列任务".tr,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            height: 1.2,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  border: Border.all(color: const Color(0xFF8F959E)),
                  borderRadius: BorderRadius.circular(6)),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: buildDynamicWidget(),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget buildDynamicWidget() {
    return LayoutBuilder(builder: (context, constrains) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: DynamicWidget(
            json: Map<String, dynamic>.from(json),
            config: TempWidgetConfig(
                radioConfig: RadioConfig(
                  singleSelected: Icon(
                    IconFont.buffSelectSingle,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  groupSelected: Icon(
                    IconFont.buffCommonCheck,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                buttonConfig: ButtonConfig(
                  dropdownConfig: DropdownConfig(
                    dropdownIcon: () =>
                        const Icon(IconFont.buffDownMore, color: color3),
                  ),
                ),
                commonConfig: CommonConfig(
                    widgetWith: kIsWeb ? 400 : constrains.maxWidth))),
      );
    });
  }
}
