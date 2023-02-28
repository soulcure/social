import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/guild_topic_sort_model.dart';
import 'package:im/common/extension/future_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/pages/guild_setting/circle/circle_setting/model/circle_management_model.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/get_image_fom_camera_or_file.dart';
import 'package:im/utils/show_action_sheet.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/link_tile.dart';
import 'package:im/widgets/round_image.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:oktoast/oktoast.dart';

import '../../../../utils/cos_file_upload.dart';

class CircleSettingPage extends StatefulWidget {
  final CircleInfoModel _circleInfoState;

  const CircleSettingPage(this._circleInfoState, {Key key}) : super(key: key);

  @override
  _CircleSettingPageState createState() => _CircleSettingPageState();
}

class _CircleSettingPageState extends State<CircleSettingPage> {
  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF0F1F2);
    return Scaffold(
      appBar: CustomAppbar(
        title: '圈子设置'.tr,
        elevation: 0.5,
        backgroundColor: bgColor,
      ),
      backgroundColor: bgColor,
      body: Column(
        children: [
          // sizeHeight16,
          LinkTile(
            context,
            _itemTitle("头像".tr),
            trailing: StreamBuilder<String>(
              stream: widget._circleInfoState.circleIconStream,
              builder: (context, snapshot) {
                return Avatar(
                  url: snapshot.data,
                  radius: 16,
                  cacheManager: CircleCachedManager.instance,
                );
              },
            ),
            onTap: () => _editAvatar(context),
          ),
          Container(
              color: Colors.white,
              child: const Divider(height: 0.5, indent: 16)),
          LinkTile(
            context,
            _itemTitle("名称".tr),
            trailing: StreamBuilder<String>(
              stream: widget._circleInfoState.circleNameStream,
              // initialData: _circleInfoState.circleName,
              builder: (context, snapshot) {
                return Expanded(
                  flex: 2,
                  child: Text(
                    snapshot.data ?? "",
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(color: Color(0xFF8F959E)),
                  ),
                );
              },
            ),
            onTap: () => _editCircleName(context),
          ),
          Container(
              color: Colors.white,
              child: const Divider(height: 0.5, indent: 16)),
          LinkTile(
            context,
            _itemTitle("简介".tr),
            trailing: StreamBuilder<String>(
              stream: widget._circleInfoState.circleDescStream,
              builder: (context, snapshot) {
                // 圈子描述
                final desc = snapshot.data.hasValue ? snapshot.data : "暂无简介".tr;
                return Expanded(
                    flex: 2,
                    child: Text(
                      desc,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(color: Color(0xFF8F959E)),
                    ));
              },
            ),
            onTap: () => _editCircleDesc(context),
          ),
          Container(
              color: Colors.white,
              child: const Divider(height: 0.5, indent: 16)),
          LinkTile(
            context,
            _itemTitle("背景图".tr),
            height: 68,
            trailing: StreamBuilder<String>(
              stream: widget._circleInfoState.circleBannerStream,
              builder: (context, snapshot) {
                return SizedRoundImage(
                  url: snapshot.data,
                  height: 48,
                  width: 64,
                  radius: 4,
                  cacheManager: CircleCachedManager.instance,
                );
              },
            ),
            onTap: () => _editBanner(context),
          ),
          sizeHeight16,
          LinkTile(
            context,
            _itemTitle("默认排序".tr),
            trailing: StreamBuilder<String>(
              stream: widget._circleInfoState.circleSortTypeStream,
              builder: (context, snapshot) {
                // 排序描述
                final sortKey = snapshot.data.hasValue ? snapshot.data : "";
                final sortName = CircleSortTypeExtension.key2Name(sortKey);
                return Expanded(
                    flex: 2,
                    child: Text(
                      sortName,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(color: Color(0xFF8F959E)),
                    ));
              },
            ),
            onTap: () async {
              final selSortTypeIdx = await showCustomActionSheet(
                CircleSortType.values.map((e) {
                  return Text(
                    e.typeName,
                    style: Theme.of(context).textTheme.bodyText2,
                  );
                }).toList(),
              );

              if (selSortTypeIdx != null &&
                  selSortTypeIdx >= 0 &&
                  selSortTypeIdx < CircleSortType.values.length) {
                // 更新
                final type = CircleSortType.values[selSortTypeIdx].keyName;
                CircleController.to
                    .updateCircleInfoDataModel({'sort_type': type});
                await widget._circleInfoState.updateCircleOrderType(type);
              }
            },
          ),
          sizeHeight16,
          LinkTile(
            context,
            _itemTitle("复制圈子ID".tr),
            showTrailingIcon: false,
            onTap: () {
              showToast("复制成功".tr);
              Clipboard.setData(
                      ClipboardData(text: widget._circleInfoState.channelId))
                  .unawaited;
            },
          ),
        ],
      ),
    );
  }

  Future _editAvatar(BuildContext context) async {
    final avatarFile = await getImageFromCameraOrFile(context,
        title: "设置圈子头像".tr,
        channel: ImageChannelType.FB_CIRCLE_AVATAR,
        crop: true,
        checkType: CheckType.circle);
    try {
      Loading.show(context);
      // final avatarUrl = await uploadHeadFile(avatarFile);
      final avatarUrl = await CosFileUploadQueue.instance
          .onceForPath(avatarFile.path, CosUploadFileType.headImage);
      await widget._circleInfoState.updateCircleIcon(avatarUrl);
      Loading.hide();
    } catch (e) {
      print(e);
      Loading.hide();
    }
  }

  ///设置圈子背景图
  Future _editBanner(BuildContext context) async {
    final bannerFile = await getImageFromCameraOrFile(context,
        title: "设置圈子背景图".tr,
        channel: ImageChannelType.FB_CIRCLE_BACKGROUND_PIC,
        crop: true,
        checkType: CheckType.circle,
        cropRatio: const CropAspectRatio(ratioX: 75, ratioY: 44));
    try {
      Loading.show(context);
      // final bannerUrl = await uploadHeadFile(bannerFile);
      final bannerUrl = await CosFileUploadQueue.instance
          .onceForPath(bannerFile.path, CosUploadFileType.headImage);
      await widget._circleInfoState.updateCircleBanner(bannerUrl);
      Loading.hide();
      print("circle banner --- updateCircleBanner: $bannerUrl");
    } catch (e) {
      print(e);
      Loading.hide();
    }
  }

  void _editCircleName(BuildContext context) {
    Routes.pushCircleNameEditorPage(context, widget._circleInfoState);
  }

  void _editCircleDesc(BuildContext context) {
    Routes.pushCircleDescEditorPage(context, widget._circleInfoState);
  }

  Widget _itemTitle(String text) {
    return Text(
      text,
      style:
          const TextStyle(fontSize: 16, color: Color(0xFF1F2125), height: 1.25),
    );
  }

  @override
  void dispose() {
    Loading.hide();
    super.dispose();
  }
}
