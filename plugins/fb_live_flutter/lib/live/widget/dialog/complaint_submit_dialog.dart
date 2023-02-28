import 'package:fb_live_flutter/live/model/room_list_model.dart';
import 'package:fb_live_flutter/live/net/api.dart';
import 'package:fb_live_flutter/live/utils/func/router.dart';
import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:fb_live_flutter/live/utils/theme/my_toast.dart';
import 'package:fb_live_flutter/live/utils/ui/dialog_util.dart';
import 'package:fb_live_flutter/live/utils/ui/frame_size.dart';
import 'package:fb_live_flutter/live/utils/ui/ui.dart';
import 'package:fb_live_flutter/live/widget/view/dialog_top_bar.dart';
import 'package:fb_live_flutter/live/widget_common/flutter/click_event.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ComplaintSubmitDialog extends StatefulWidget {
  final double height;
  final RoomListModel? item;

  const ComplaintSubmitDialog(this.height, this.item);

  @override
  _ComplaintSubmitDialogState createState() => _ComplaintSubmitDialogState();
}

class _ComplaintSubmitDialogState extends State<ComplaintSubmitDialog> {
  TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350)).then((value) {
      focusNode.requestFocus();
    });
  }

  Future handle() async {
    if (controller.text.length > 100) {
      myFailToast('长度过大');
      return;
    }
    if (!strNoEmpty(controller.text)) {
      myFailToast('请输入申诉原因');
      return;
    }
    Get.back();
    await playbackAppeal(controller.text, false);
  }

  Future playbackAppeal(String reason, bool isAgain) async {
    if (!strNoEmpty(reason) && !isAgain) {
      myFailToast('请输入申诉原因');
      return;
    }
    if (widget.item == null) {
      myFailToast('数据异常');
      return;
    }
    Map? _result;
    if (!isAgain) {
      _result = await Api.playbackAppeal(widget.item!.roomId, reason);
    } else {
      _result = await Api.playbackIsAppeal(widget.item!.roomId);
    }
    if (_result!['code'] == 200) {
      await DialogUtil.complaintReceive(context, isAgain);
    } else {
      myToast(_result['msg']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: FrameSize.winWidth(),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.px),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            DialogTopBar(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: RouteUtil.pop,
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: 12.px, top: 12.px, bottom: 12.px),
                    child: Image.asset(
                      'assets/live/main/goods_close.png',
                      width: 16.97.px,
                      height: 16.97.px,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 12.px, top: 12.px),
                  child: Text(
                    '提交申诉说明',
                    style: TextStyle(
                      color: const Color(0xff1F2125),
                      fontSize: 17.px,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ClickEvent(
                  onTap: handle,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12.px, top: 12.px),
                    child: Text(
                      '完成',
                      style: TextStyle(
                        color: const Color(0xFF198CFE),
                        fontSize: 16.px,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                width: FrameSize.winWidth(),
                decoration: BoxDecoration(
                  color: const Color(0xffF5F5F8),
                  borderRadius: BorderRadius.all(Radius.circular(6.px)),
                ),
                padding: EdgeInsets.only(
                    left: 16.px, bottom: 16.px, right: 16.px, top: 6.px),
                child: StatefulBuilder(
                  builder: (_, ss) {
                    return Column(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            expands: true,
                            maxLines: null,
                            // autofocus: true,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "请输入申诉内容",
                              hintStyle: TextStyle(
                                color: const Color(0xff8F959E),
                                fontSize: 16.px,
                              ),
                            ),
                            onChanged: (_) {
                              ss(() {});
                            },
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            '${controller.text.length}/100',
                            style: TextStyle(
                                color: controller.text.length > 100
                                    ? Colors.red
                                    : const Color(0xff8F959E),
                                fontSize: 14.px),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Space(height: 20.px),
          ],
        ),
      ),
    );
  }
}
