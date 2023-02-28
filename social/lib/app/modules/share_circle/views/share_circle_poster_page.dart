//
//  share_circle_poster_page
//  social
//
//  Created by weiweili on 2021/11/4 .
//  Copyright © social. All rights reserved.
//
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:fluwx/fluwx.dart';
import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/circle/controllers/circle_controller.dart';
import 'package:im/app/modules/circle/models/circle_post_data_model.dart';
import 'package:im/app/modules/scan_qr_code/controllers/scan_qr_code_controller.dart';
import 'package:im/app/modules/share_circle/controllers/share_circle_controller.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/design_logical_pixels.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/guild_setting/guild/container_image.dart';
import 'package:im/pages/home/view/check_permission.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';
import 'package:im/svg_icons.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/custom_cache_manager.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';
import 'package:im/widgets/realtime_user_info.dart';
import 'package:im/widgets/share_link_popup/share_type.dart';
import 'package:im/widgets/toast.dart';
import 'package:im/widgets/top_status_bar.dart';
import 'package:im/widgets/user_info/realtime_nick_name.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:oktoast/oktoast.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:tuple/tuple.dart';
import 'package:websafe_svg/websafe_svg.dart';

class _BoundaryModel {
  final Uint8List data;
  final int imageW;
  final int imageH;

  _BoundaryModel(
      {@required this.data, @required this.imageW, @required this.imageH});
}

class ShareCirclePosterPage extends StatefulWidget {
  /// 分享链接
  final String shareLink;
  final ShareBean shareBean;

  const ShareCirclePosterPage({
    Key key,
    @required this.shareLink,
    @required this.shareBean,
  }) : super(key: key);

  @override
  _ShareCirclePosterPageState createState() => _ShareCirclePosterPageState();
}

class _ShareCirclePosterPageState extends State<ShareCirclePosterPage>
    with SingleTickerProviderStateMixin {
  final uniqueKey = UniqueKey();
  final GlobalKey _posterKey = GlobalKey();
  final GlobalKey _popUpKey = GlobalKey();
  double _contentH = 0;
  double _topPadding = 45;
  double _bottomPadding = 0;

  bool _isQrLoadedErr = false;

  ///高度的最大像素
  final maxHeightPixel = 7000;

  ///动态内容最大高度
  double maxContentHeight;

  CirclePostDataModel get data => widget.shareBean.data;

  String get guildId => data?.postInfoDataModel?.guildId ?? '';

  @override
  void initState() {
    super.initState();
    maxContentHeight = maxHeightPixel / Get.window.devicePixelRatio;
    // debugPrint('getChat maxWidgetHeight: $maxWidgetHeight');
  }

  @override
  void didChangeDependencies() {
    /// 视频分享不需要
    if (widget.shareBean.sharePosterModel.postVideo == null) {
      WidgetsBinding.instance.addPostFrameCallback(_getContainerHeight);
    }
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(ShareCirclePosterPage oldWidget) {
    /// 视频分享不需要
    if (widget.shareBean.sharePosterModel.postVideo == null) {
      WidgetsBinding.instance.addPostFrameCallback(_getContainerHeight);
    }
    super.didUpdateWidget(oldWidget);
  }

  ///获取一些widget的宽高，设置Padding，设置裁剪高度等
  void _getContainerHeight(_) {
    final contentH = _posterKey.currentContext.size.height;
    if (contentH == _contentH) {
      return;
    }
    _contentH = contentH;
    final popUpH = _popUpKey.currentContext.size.height;

    /// 有效的展示高度，超过有效高度，居中展示，否则距离顶部40px开始显示
    final visibleH = Get.height - popUpH - 60;

    /// 居中显示
    if (contentH <= visibleH) {
      _topPadding = (Get.height - popUpH - contentH) / 2;
    } else {
      _topPadding = 45;
    }
    _bottomPadding = popUpH + 15;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0x42000000),
      body: GetBuilder<TopStatusController>(
        /// 监听网络变化
        builder: (controller) {
          return Stack(
            children: [
              _invitePosterCard(context),
              _sharePopUp(context),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    logger.info("ShareCirclePosterPage -- dispose");
    super.dispose();
  }

  /// 分享海报
  Widget _invitePosterCard(BuildContext context) {
    final data = widget.shareBean.data;
    final title = data.postInfoDataModel.title;
    //视频封面地址
    final thumbUrl = widget.shareBean.sharePosterModel?.postVideo?.thumbUrl;
    final tuple2 =
        getContentAndMedia(data.postInfoDataModel.postContent(), thumbUrl);
    //  是否有标题
    final hasTitle = title.hasValue;
    //  是否有图
    final hasImage = tuple2.item2 != null;
    List<String> mentions = [];
    if (tuple2.item1.noValue && !hasTitle) {
      mentions = data.atUserIdList;
    }
    final titleTextStyle = appThemeData.textTheme.bodyText1.copyWith(
      fontSize: 15,
      height: 1.5,
      fontWeight: FontWeight.bold,
    );
    final contentTextStyle =
        appThemeData.textTheme.bodyText2.copyWith(fontSize: 14, height: 1.25);

    return Positioned(
        top: 0,
        left: 16,
        right: 16,
        bottom: 0,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (widget.shareBean.sharePosterModel.postVideo == null)
                SizedBox(height: _topPadding)
              else
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: SizedBox(height: _topPadding),
                ),
              RepaintBoundary(
                key: _posterKey,
                child: AbsorbPointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (hasImage) _buildMediaItem(tuple2.item2, context),
                        if (!hasImage)
                          _getContent(tuple2.item1, contentTextStyle, 5),
                        if (hasImage && !hasTitle)
                          _getContent(tuple2.item1, titleTextStyle, 2),
                        if (hasTitle) _getTitle(title, titleTextStyle),
                        if (mentions != null && mentions.isNotEmpty)
                          _buildMentionsView(mentions, titleTextStyle),
                        _buildUserInfo(data),
                        Divider(
                          height: .5,
                          thickness: .5,
                          color: appThemeData.dividerColor,
                        ),
                        _buildPosterBottom(),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: _bottomPadding),
            ],
          ),
        ));
  }

  /// * 解析动态的内容
  Tuple2<String, Operation> getContentAndMedia(
      String contentValue, String thumbUrl) {
    final list = getOperationList(contentValue);
    Operation media = list.firstWhere(
      (o) => o.isMedia,
      orElse: () => null,
    );
    if (thumbUrl.hasValue) {
      final thumb = list.firstWhere(
        (o) =>
            o.isVideo &&
            thumbUrl == RichEditorUtils.getEmbedAttribute(o, 'thumbUrl'),
        orElse: () => null,
      );
      if (thumb != null) media = thumb;
    }

    final richTextSb = getRichText(list);
    final tempText = richTextSb.toString().compressLineString();
    return Tuple2(tempText, media);
  }

  /// * 第一张图片或视频封面
  Widget _buildMediaItem(Operation o, BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      String url;
      if (o.isImage)
        url = RichEditorUtils.getEmbedAttribute(o, 'source');
      else
        url = RichEditorUtils.getEmbedAttribute(o, 'thumbUrl');
      if (url.noValue) return sizedBox;

      final widgetWidth = constraint.maxWidth;
      double widgetHeight;
      double width, height;
      final w = RichEditorUtils.getEmbedAttribute(o, 'width');
      if (w is int) {
        width = w.toDouble();
      } else {
        width = w as double;
      }
      final h = RichEditorUtils.getEmbedAttribute(o, 'height');
      if (h is int) {
        height = h.toDouble();
      } else {
        height = h as double;
      }

      // 按照宽高比范围，计算高度
      widgetHeight = getImageHeightByRatio(width, height, widgetWidth);
      final child = Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border:
                  Border.all(color: appThemeData.dividerColor.withOpacity(0.2)),
            ),
            child: ContainerImage(
              url,
              width: widgetWidth,
              height: widgetHeight,
              thumbWidth: CircleController.circleThumbWidth,
              fit: BoxFit.cover,
              cacheManager: CircleCachedManager.instance,
              placeHolder: (_, url) =>
                  const Center(child: CupertinoActivityIndicator()),
            ),
          ),
          if (o.isVideo)
            Container(
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                width: 40,
                height: 40,
                child: Center(
                  child: WebsafeSvg.asset(
                    SvgIcons.circleVideoPlay,
                    width: 20,
                    height: 20,
                    color: Colors.white,
                  ),
                )),
        ],
      );
      return ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(4),
        ),
        child: child,
      );
    });
  }

  /// * 标题，最多两行
  Widget _getTitle(String title, TextStyle textStyle) => title.noValue
      ? sizedBox
      : Container(
          padding: const EdgeInsets.fromLTRB(0, 12, 8, 0),
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        );

  /// * 动态内容
  Widget _getContent(String content, TextStyle textStyle, int maxLines) {
    // 是否在上面显示
    final isTop = maxLines == 5;
    TextStyle _textStyle = textStyle;
    if (isTop) {
      _textStyle = appThemeData.textTheme.bodyText1.copyWith(
        fontSize: 17,
        height: 1.25,
      );
    }

    final textWidget = ParsedText(
      style: _textStyle,
      text: content,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      parse: [
        ParsedTextExtension.matchCusEmoText(context, textStyle.fontSize),
        ParsedTextExtension.matchAtText(
          context,
          textStyle: textStyle,
          guildId: guildId,
          useDefaultColor: false,
          tapToShowUserInfo: false,
        ),
        ParsedTextExtension.matchChannelLink(
          context,
          textStyle: textStyle,
          tapToJumpChannel: false,
          hasBgColor: false,
          refererChannelSource: RefererChannelSource.CircleLink,
        ),
      ],
    );

    return content.noValue
        ? sizedBox
        : !isTop
            ? Container(
                padding: const EdgeInsets.fromLTRB(0, 12, 8, 0),
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: textWidget,
              )
            : LayoutBuilder(
                builder: (context, constraint) {
                  final width = constraint.maxWidth;
                  final height = width * 0.75;
                  return Container(
                    color: const Color(0xFFFBFBFD),
                    padding: const EdgeInsets.fromLTRB(16, 12, 15, 0),
                    width: width,
                    height: height,
                    alignment: Alignment.center,
                    child: textWidget,
                  );
                },
              );
  }

  /// 被提醒的人
  Widget _buildMentionsView(List<String> userIds, TextStyle style) => Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: UserInfo.getUserIdListWidget(
          userIds,
          guildId: guildId,
          builder: (context, users, child) {
            String mentionName = "";
            users.forEach((key, user) {
              mentionName += "@${user.showName(guildId: guildId)} ";
            });
            return Text(
              mentionName,
              style: style,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      );

  /// 海报底部区域UI
  Widget _buildPosterBottom() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: _bottomLeft()),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _qrCode(),
        ),
      ],
    );
  }

  Widget _bottomLeft() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            WebsafeSvg.asset(SvgIcons.circleFanbookLogo, width: 20, height: 20),
            const SizedBox(width: 8),
            WebsafeSvg.asset(SvgIcons.circleFanbookWord, height: 14),
          ],
        ),
        sizeHeight10,
        Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Text(
            "扫一扫，查看更多内容".tr,
            style: const TextStyle(
              fontSize: 12,
              height: 1,
              color: Color(0xFF646A73),
            ),
          ),
        ),
      ],
    );
  }

  /// 分享二维码
  Widget _qrCode() {
    if (widget.shareLink == null || widget.shareLink?.isEmpty == true) {
      return _buildActivityIndicator();
    }

    /// NOTE(jp@jin.dev): 2022/5/20 缩小icon的图标大小，防止中心区域丢失严重，导致二维码识别失败
    return ScanQrCodeController.genQRCode(
        data: widget.shareLink,
        embeddedImg: const AssetImage("assets/images/icon.png"),
        embeddedImageSize: 12,
        padding: EdgeInsets.zero,
        embeddedImageEmitsError: true,
        size: 56,
        errorStateBuilder: (ctx, err) {
          return _buildActivityIndicator();
        });
  }

  Widget _buildActivityIndicator() {
    _isQrLoadedErr = true;
    return const SizedBox(
      height: 100,
      width: 100,
      child: Center(
        child: CupertinoActivityIndicator(),
      ),
    );
  }

  /// 发起邀请的用户头像和昵称
  Widget _buildUserInfo(CirclePostDataModel data) {
    final user = data?.userDataModel;
    if (user == null) {
      return const SizedBox();
    }
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            // 头像 ，不使用RealtimeAvatar的原因是，texture显示的图片，使用截图不能显示。
            RealtimeAvatar(
              userId: user?.userId ?? '',
              size: 23,
              guildId: guildId,
              showBorder: true,
            ),
            sizeWidth8,
            Expanded(
              child: RealtimeNickname(
                userId: user?.userId ?? '',
                style: appThemeData.textTheme.bodyText2
                    .copyWith(fontSize: 14, height: 1.25),
                showNameRule: ShowNameRule.remarkAndGuild,
                guildId: data.postInfoDataModel.guildId,
              ),
            ),
            sizeWidth16,
          ],
        ),
      ),
    );
  }

  /// 分享弹窗
  Widget _sharePopUp(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_getContainerHeight);

    final bottom = MediaQueryData.fromWindow(ui.window).padding.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: Column(
          key: _popUpKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 122,
              color: const Color(0xFFF5F5F8),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                scrollDirection: Axis.horizontal,
                children: [
                  /// 保存到本地
                  _buildShareItem(
                    SaveImageConfig(),
                    SaveNativePosterAction(
                        _posterBoundaryModel, _isAllowedPoster),
                  ),

                  /// 分享给微信好友
                  _buildShareItem(
                    WechatShareToFriendConfig(),
                    WechatShareCirclePosterAction(
                        _posterBoundaryModel, _isAllowedPoster),
                  ),

                  /// 分享到微信朋友圈
                  _buildShareItem(
                    WechatShareToMomentConfig(),
                    WechatShareCirclePosterAction(
                      _posterBoundaryModel,
                      _isAllowedPoster,
                      scene: WeChatScene.TIMELINE,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                alignment: Alignment.center,
                width: ui.window.physicalSize.width,
                padding: const EdgeInsets.symmetric(vertical: 17.5),
                color: Colors.white,
                child: Text(
                  "取消".tr,
                  style:
                      const TextStyle(color: Color(0xFF1F2125), fontSize: 17),
                ),
              ),
            ),
            if (bottom > 0) Container(height: bottom, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildShareItem(ShareConfig config, ShareAction action) {
    return ShareItem(
      config: config,
      action: action,
      size: 56,
      radius: 10,
      iconBgColor: Colors.white,
      textStyle: const TextStyle(color: Color(0xFF646A73), fontSize: 10),
      padding: EdgeInsets.symmetric(horizontal: 6.px),
    );
  }

  Future<_BoundaryModel> _posterBoundaryModel() async {
    final image = await _generatePosterImage();
    final unit8List = await _generateUint8List(image);
    return _BoundaryModel(
        data: unit8List, imageW: image.width, imageH: image.height);
  }

  bool _isAllowedPoster() {
    final event = TopStatusController.to().topStatusBarEvent;

    /// 断开网络情况
    if (event == TopStatusBarEvent.netWorkOff) {
      showToast('网络异常，请检查后重试'.tr);
      return false;
    }

    /// 二维码是否加载失败
    if (_isQrLoadedErr) {
      showToast('二维码加载失败，请检查后重试'.tr);
      return false;
    }
    return true;
  }

  Future<Uint8List> _generateUint8List(ui.Image image) async {
    final _byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return _byteData.buffer.asUint8List();
  }

  Future<ui.Image> _generatePosterImage() async {
    final RenderRepaintBoundary boundary =
        _posterKey.currentContext.findRenderObject();
    final ratio = ui.window.devicePixelRatio; // 获取当前设备的像素比
    final image = await boundary.toImage(pixelRatio: ratio);
    return image;
  }
}

typedef GenerateCirclePoster = Future<_BoundaryModel> Function();
typedef CirclePosterAllowed = bool Function();

/// 分享圈子内容海报到微信
class WechatShareCirclePosterAction extends ShareAction {
  /// 生成邀请海报的接口
  final GenerateCirclePoster generatePoster;
  final WeChatScene scene;
  final CirclePosterAllowed posterAllowed;

  WechatShareCirclePosterAction(
    this.generatePoster,
    this.posterAllowed, {
    this.scene = WeChatScene.SESSION,
  });

  @override
  Future<bool> shareAction() async {
    if (!posterAllowed()) {
      isPopAfterShare = false;
      Navigator.pop(Get.context);
      return false;
    }
    final model = await generatePoster();
    final Uint8List rawData = model.data;
    final image = WeChatImage.binary(rawData);
    final shareModel = WeChatShareImageModel(image, scene: scene);
    if (await isWeChatInstalled) {
      await shareToWeChat(shareModel);
    } else {
      showToast('未安装微信'.tr);
    }
    return true;
  }
}

/// 保存分享海报
class SaveNativePosterAction extends ShareAction {
  /// 生成邀请海报的接口
  final GenerateCirclePoster generatePoster;
  final CirclePosterAllowed posterAllowed;

  SaveNativePosterAction(this.generatePoster, this.posterAllowed);

  @override
  Future<bool> shareAction() async {
    if (!posterAllowed()) {
      isPopAfterShare = false;
      Navigator.pop(Get.context);
      return false;
    }

    /// 获得图片Uint8 list数据
    final model = await generatePoster();

    /// ios android获取保存图片权限不一致，需要分别处理
    final permission = await checkSystemPermissions(
      context: Get.context,
      permissions: [
        if (UniversalPlatform.isIOS) Permission.photos,
        if (UniversalPlatform.isAndroid) Permission.storage
      ],
    );
    if (permission != true) {
      isPopAfterShare = false;
      showToast('无权限获取相册，保存失败'.tr);
      return false;
    }

    /// 保存图片到相册
    final res = await ImageGallerySaver.saveImage(model.data);
    if (res == null || res == '') {
      showToast("保存失败".tr);
      return false;
    }
    Toast.iconToast(icon: ToastIcon.success, label: "已保存到系统相册".tr);
    return true;
  }
}
