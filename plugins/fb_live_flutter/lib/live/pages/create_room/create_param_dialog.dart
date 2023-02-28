import 'package:fb_live_flutter/fb_live_flutter.dart';
import 'package:fb_live_flutter/live/model/live/obs_rsp_model.dart';
import 'package:fb_live_flutter/live/utils/ui/show_right_dialog.dart';
import 'package:fb_live_flutter/live/widget/view/dialog_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/ui/frame_size.dart';
import '../../utils/ui/ui.dart';
import 'create_param_page.dart';

Future createParamDialog(BuildContext context, final ObsRspModel? obsModel) {
  return showBottomSheetCommonDialog(
    context,
    child: CreateParamDialog(obsModel),
  );
}

class CreateParamDialog extends StatefulWidget {
  final ObsRspModel? obsModel;

  const CreateParamDialog(this.obsModel);

  @override
  _CreateParamDialogState createState() => _CreateParamDialogState();
}

class _CreateParamDialogState extends State<CreateParamDialog> {
  List<List<String>> data = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    data = [
      ['URL', widget.obsModel?.url ?? '为空'],
      ['流名称 (Key)', widget.obsModel?.secret ?? '为空'],
    ];
    fbApi.fbLogger.info(data.toString());
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.only(top: 5.px),
            margin: EdgeInsets.only(top: FrameSize.padTopH()),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10.px)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  DialogTopBar(),
                  Space(height: 14.px),
                  CreateParamBody(data),
                  HorizontalLine(
                    height: 8,
                    margin: EdgeInsets.only(top: 30.px),
                  ),
                  SizedBox(
                    width: FrameSize.winWidth(),
                    child: TextButton(
                      onPressed: Get.back,
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
          )
        ],
      ),
    );
  }
}
