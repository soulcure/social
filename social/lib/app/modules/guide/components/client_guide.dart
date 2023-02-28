import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/routes/app_pages.dart';
import 'package:im/core/widgets/button/fade_button.dart';
import 'package:im/dlog/dlog_manager.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';

class GuideBottomSheet {
  GuideBottomSheet(this.assetUrl);

  final String assetUrl;

  static void showPageViewPopup() {
    final imageList = [
      GuideBottomSheet('assets/images/guild_guide.jpg'),
      GuideBottomSheet('assets/images/role_guide.jpg'),
    ];
    Get.bottomSheet(
      ClientGuide(
        imageList,
        isPageView: true,
        buttonText: '开启社区新体验'.tr,
        onTap: () {
          Get.back();
          DLogManager.getInstance().customEvent(
            actionEventId: "guild_join",
            actionEventSubId: "click_community_confirm",
            extJson: {
              "guild_id": ChatTargetsModel.instance.selectedChatTarget?.id
            },
          );
        },
      ),
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: false,
      settings: const RouteSettings(name: Routes.BS_GUILD_FIRST_ENTRY),
    );
  }

  static void showChannelPopup() {
    Get.bottomSheet(
      ClientGuide(
          [GuideBottomSheet('assets/images/channel_manager_guide.jpg')]),
      enableDrag: false,
      isDismissible: false,
      isScrollControlled: true,
    );
  }

  static void showRolePopup() {
    Get.bottomSheet(
      ClientGuide([GuideBottomSheet('assets/images/role_manager_guide.jpg')]),
      enableDrag: false,
      isDismissible: false,
      isScrollControlled: true,
    );
  }

  static void showTextChatPopup() {
    Get.bottomSheet(
      ClientGuide(
        [
          GuideBottomSheet('assets/images/text_chat_guide_1.jpg'),
          GuideBottomSheet('assets/images/text_chat_guide_2.jpg'),
        ],
        isPageView: true,
        onTap: () {
          Get.back();
          DLogManager.getInstance().customEvent(
            actionEventId: "guild_join",
            actionEventSubId: "click_channel_page",
            actionEventSubParam: GlobalState.selectedChannel.value?.id,
            extJson: {
              "guild_id": ChatTargetsModel.instance.selectedChatTarget?.id
            },
          );
        },
      ),
      enableDrag: false,
      isDismissible: false,
      isScrollControlled: true,
      settings: const RouteSettings(name: Routes.BS_GUILD_TEXT_CHANNEL),
    );
  }
}

class ClientGuide extends StatefulWidget {
  const ClientGuide(this.imageItem,
      {this.isPageView = false, this.buttonText, this.onTap, Key key})
      : super(key: key);
  final List<GuideBottomSheet> imageItem;
  final String buttonText;
  final bool isPageView;
  final VoidCallback onTap;

  @override
  _ClientGuideState createState() => _ClientGuideState();
}

class _ClientGuideState extends State<ClientGuide> {
  final PageController _controller = PageController();
  final ValueNotifier<int> _nowIndex = ValueNotifier(0);

  @override
  void initState() {
    if (widget.isPageView)
      _controller.addListener(() {
        final p = _controller.page.round();
        if (p != _nowIndex.value) {
          _nowIndex.value = p;
        }
      });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * .65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 36),
            Expanded(
              child: PageView(
                controller: _controller,
                children: List.generate(widget.imageItem.length, _image),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: _nowIndex,
              builder: (context, value, child) {
                if (value == widget.imageItem.length - 1)
                  return _finalButton();
                else
                  return _indicator();
              },
            ),
            sizeHeight20,
          ],
        ),
      ),
    );
  }

  Widget _image(int index) {
    return ImageWidget.fromAsset(
      AssetImageBuilder(widget.imageItem[index].assetUrl),
    );
  }

  Widget _indicator() {
    return SizedBox(
      height: 44,
      child: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: _nowIndex,
          builder: (context, value, child) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              widget.imageItem.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: SizedBox(
                  height: 6,
                  width: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: index == value
                          ? Get.theme.primaryColor
                          : const Color(0xFF8D93A6).withOpacity(.3),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Padding _finalButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: FadeButton(
        onTap: widget.onTap ?? Get.back,
        decoration: BoxDecoration(
          color: Get.theme.primaryColor,
          borderRadius: const BorderRadius.all(
            Radius.circular(6),
          ),
        ),
        height: 44,
        child: Text(
          widget.buttonText ?? '我知道了'.tr,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
