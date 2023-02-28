import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/common/extension/future_extension.dart';
import 'package:im/core/widgets/button/fade_background_button.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/pages/guild/widget/guild_icon.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/content_checker.dart';
import 'package:im/utils/cos_file_upload.dart';
import 'package:im/utils/get_image_fom_camera_or_file.dart';
import 'package:im/utils/image_operator_collection/image_collection.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/more_icon.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:oktoast/oktoast.dart';

import '../../../global.dart';
import '../../../routes.dart';
import 'guild_edit_name_page.dart';

class GuildEditInfoPage extends StatefulWidget {
  final String guildId;

  const GuildEditInfoPage({Key key, @required this.guildId}) : super(key: key);

  @override
  _GuildEditInfoPageState createState() => _GuildEditInfoPageState();
}

class _GuildEditInfoPageState extends State<GuildEditInfoPage> {
  GuildTarget target;
  bool isBannerLoading = false;
  bool isIconLoading = false;

  @override
  void initState() {
    target = ChatTargetsModel.instance.getChatTarget(widget.guildId);

    super.initState();
  }

  @override
  void dispose() {
    Loading.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerUrl = target.banner;
    final bool needShowBanner = bannerUrl != null && bannerUrl.isNotEmpty;
    const bg = Color(0xffF0F1F2);
    return Scaffold(
      backgroundColor: bg,
      appBar: CustomAppbar(
        title: '服务器资料'.tr,
      ),
      body: Container(
        color: Theme.of(context).backgroundColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            divider(bg, 16, margin: EdgeInsets.zero),
            buildListTile(
                one: Text(
                  '服务器头像'.tr,
                  style:
                      const TextStyle(color: Color(0xff1F2125), fontSize: 17),
                ),
                two: GuildIcon(
                  target,
                  size: 48,
                ),
                three: const MoreIcon(),
                height: 80,
                // loading: loadingWidget(isIconLoading),
                onTap: () {
                  onPress(isBanner: false, onSuccess: refresh).then((value) {
                    Loading.hide();
                    refresh();
                  });
                }),
            divider(bg, 0.5),
            buildListTile(
                one: Text(
                  '服务器名称'.tr,
                  style:
                      const TextStyle(color: Color(0xff1F2125), fontSize: 17),
                ),
                insert: sizedBox,
                two: Expanded(
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: Text(
                      target.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xff8F959E), fontSize: 15),
                    ),
                  ),
                ),
                three: const MoreIcon(),
                height: 52,
                onTap: () {
                  Routes.push(
                          context,
                          GuildEditNamePage(
                            guildId: widget.guildId,
                          ),
                          guildEditNameRoute)
                      .then((value) {
                    refresh();
                  });
                }),
            Container(height: 16, color: bg),
            buildListTile(
                height: 80,
                one: Text(
                  '背景图'.tr,
                  style:
                      const TextStyle(color: Color(0xff1F2125), fontSize: 17),
                ),
                two: needShowBanner
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: ImageWidget.fromCachedNet(CachedImageBuilder(
                          imageUrl: target.banner,
                          height: 48,
                        )),
                      )
                    : sizedBox,
                three: const MoreIcon(),
                // loading: loadingWidget(isBannerLoading),
                onTap: () {
                  onPress(onSuccess: refresh).then((value) {
                    Loading.hide();
                    refresh();
                  });
                }),
            Container(height: 16, color: bg),
            buildListTile(
                one: Text(
                  '复制服务器ID'.tr,
                  style:
                      const TextStyle(color: Color(0xff1F2125), fontSize: 17),
                ),
                height: 52,
                two: const SizedBox(),
                three: const SizedBox(),
                onTap: () {
                  showToast("复制成功".tr);
                  Clipboard.setData(ClipboardData(text: widget.guildId))
                      .unawaited;
                }),
          ],
        ),
      ),
    );
  }

  Widget divider(Color bg, double height, {EdgeInsetsGeometry margin}) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.only(left: 16, right: 16),
      child: Container(
        height: height,
        color: bg,
      ),
    );
  }

  Widget loadingWidget(bool isLoading) {
    return isLoading
        ? Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 4),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
        : null;
  }

  Widget buildListTile(
      {Widget one,
      Widget two,
      Widget three,
      Widget loading,
      Widget insert = const Spacer(),
      VoidCallback onTap,
      double height}) {
    final theme = Theme.of(context);
    final color1 = theme.backgroundColor;
    return FadeBackgroundButton(
      onTap: onTap,
      tapDownBackgroundColor: color1.withOpacity(0.5),
      backgroundColor: color1,
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16),
        height: height,
        child: Row(
          children: [one, insert, if (loading != null) loading, two, three],
        ),
      ),
    );
  }

  Future onPress({bool isBanner = true, VoidCallback onSuccess}) async {
    if (isBanner && isBannerLoading) return;
    if (!isBanner && isIconLoading) return;
    setLoading(isBanner);
    final crop = isBanner ? const CropAspectRatio(ratioX: 2, ratioY: 1) : null;
    final file = await getImageFromCameraOrFile(
      context,
      crop: true,
      channel: ImageChannelType.serviceImage,
      cropRatio: crop,
    );
    if (file == null) {
      clearLoading(isBanner);
      return;
    }
    refresh();
    // final uploadFileBytes = await file.readAsBytes();
    String url;
    try {
      // url = await uploadFileIfNotExist(
      //     bytes: uploadFileBytes,
      //     filename: target.name + (isBanner ? 'banner' : 'icon'),
      //     fileType: "image");
      url = await CosFileUploadQueue.instance
          .onceForPath(file.path, CosUploadFileType.image);
    } on Exception catch (_) {
      showToast('图片上传错误'.tr);
      clearLoading(isBanner);
    }
    if (url == null) return;

    try {
      await GuildApi.updateGuildInfo(
        widget.guildId,
        Global.user.id,
        icon: isBanner ? null : url,
        banner: isBanner ? url : null,
      );
      target.updateInfo(
          icon: isBanner ? null : url, banner: isBanner ? url : null);
      onSuccess?.call();
    } catch (e) {
      showToast('图片修改错误'.tr);
    }
    clearLoading(isBanner);
  }

  void setLoading(bool isBanner) {
    if (isBanner)
      isBannerLoading = true;
    else
      isIconLoading = true;
  }

  void clearLoading(bool isBanner) {
    if (isBanner)
      isBannerLoading = false;
    else
      isIconLoading = false;
  }

  void refresh() {
    if (mounted) setState(() {});
  }
}
