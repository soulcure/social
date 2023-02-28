import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/circle/models/circle_share_poster_model.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/modules/mute/controllers/mute_listener_controller.dart';
import 'package:im/app/modules/share_circle/controllers/share_circle_controller.dart';
import 'package:im/app/modules/share_circle/views/share_circle.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/permission/permission_model.dart';
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/widgets/check_circle_box.dart';
import 'package:im/widgets/fb_ui_kit/button/button_builder.dart';
import 'package:oktoast/oktoast.dart';

import '../../../../icon_font.dart';

class ShareButton extends StatelessWidget {
  final CirclePostDataModel data;
  final AlignmentGeometry alignment;
  final double size;
  final Function onTap;
  final bool isLandFromCircleDetail;
  final EdgeInsetsGeometry padding;
  final BoxConstraints constraints;
  final Color color;
  final bool isFromList;

  /// 用于海报分享
  final CircleSharePosterModel sharePosterModel;

  const ShareButton({
    Key key,
    this.data,
    this.sharePosterModel,
    this.alignment = Alignment.centerRight,
    this.size = 24,
    this.isLandFromCircleDetail = false,
    this.padding = EdgeInsets.zero,
    this.constraints,
    this.color,
    this.onTap,
    this.isFromList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      padding: padding,
      constraints: constraints,
      alignment: alignment,

      icon: Icon(IconFont.buffChatForwardNew,
          color: color ?? theme.disabledColor, size: size),
      // todo 不能这样写
      onPressed: onTap ??
          () {
            ShareCircle.showCircleShareDialog(
              ShareBean(
                data: data,
                guildId: data.postInfoDataModel.guildId,
                isLandFromCircleDetail: isLandFromCircleDetail,
                sharePosterModel: sharePosterModel,
                isFromList: isFromList,
              ),
            );
          },
    );
  }
}

class ShareWidget extends StatefulWidget {
  final Function(Map<String, ChatChannel>, GuildTarget) onSend;
  final String guildId;
  final String buttonText;

  const ShareWidget({Key key, this.onSend, this.guildId, this.buttonText})
      : super(key: key);

  @override
  _ShareWidgetState createState() => _ShareWidgetState();
}

class _ShareWidgetState extends State<ShareWidget> {
  List<ChatChannel> _channels = [];
  Rx<int> selectedIndex = Rx<int>(-1);

  ///key为channelId
  final Map<String, ChatChannel> _selectedChannels = {};

  bool isNetWorkNormal = true;
  GuildTarget _guildTargetModel;

  FbButtonStatus _confirmStatus = FbButtonStatus.unable;

  bool get hasSelected => _selectedChannels.isNotEmpty;

  int get select => selectedIndex.value;

  set select(int index) => selectedIndex.value = index;

  @override
  void initState() {
    final list = ChatTargetsModel.instance.chatTargets;
    list.forEach((e) {
      if (e is GuildTarget && e.id == widget.guildId) _guildTargetModel = e;
    });
    _channels = _guildTargetModel.getViewSendChannels();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height / 1.5;

    return Container(
      constraints: BoxConstraints(maxHeight: height > 450 ? 450 : height),
      child: buildMenu(theme),
    );
  }

  Widget buildMenu(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const SizedBox(width: 50),
                Expanded(
                    child: Center(
                  child: Text('分享至频道'.tr,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                )),
                SizedBox(
                  width: 50,
                  child: FbButton.text(
                    '确定',
                    status: _confirmStatus,
                    size: FbButtonSize.big,
                    onPressed: () {
                      if (_selectedChannels.isEmpty) return;
                      if (MuteListenerController.to.isMuted) {
                        // 是否被禁言
                        showToast('你已被禁言，无法操作'.tr);
                        return;
                      }

                      widget.onSend?.call(_selectedChannels, _guildTargetModel);
                      Get.back();
                    },
                  ),
                )
              ],
            ),
          ),
        ),
        Expanded(
          child: Scrollbar(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              itemBuilder: _buildItem,
              separatorBuilder: (c, i) => const Divider(
                indent: 16,
                thickness: 0.5,
              ),
              itemCount: _channels.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(c, index) {
    final channel = _channels[index];
    final color =
        isChannelColorBlack(channel) ? const Color(0xff1F2125) : Colors.grey;
    final isPrivate = PermissionUtils.isPrivateChannel(
        PermissionModel.getPermission(channel.guildId), channel.id);
    BoxDecoration decoration;
    final Color bgColor = appThemeData.backgroundColor;
    if (index == 0) {
      decoration = BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          color: bgColor);
    } else if (index == _channels.length - 1) {
      decoration = BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          color: bgColor);
    } else {
      decoration = BoxDecoration(color: bgColor);
    }

    return GestureDetector(
      onTap: () {
        onValueChange(index);
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        height: 52,
        decoration: decoration,
        child: Row(
          children: [
            const SizedBox(width: 16),
            AbsorbPointer(
              absorbing: _selectedChannels.length >= 9,
              child: Obx(() => AnimatedContainer(
                    duration: const Duration(milliseconds: 20),
                    child: CheckCircleBox(
                      value: select == index,
                      size: 22,
                      onChanged: (v) {
                        onValueChange(v ? index : -1);
                      },
                    ),
                  )),
            ),
            const SizedBox(width: 12),
            Icon(
              isPrivate
                  ? IconFont.buffSimiwenzipindao
                  : IconFont.buffWenzipindaotubiao,
              size: 18,
              color: Get.textTheme.bodyText2.color,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _channels[index].name,
                style: TextStyle(fontSize: 16, color: color, height: 20 / 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildButton(ThemeData theme, String text, bool hasSelected,
      {VoidCallback onPressed}) {
    final selectLength = _selectedChannels.length;
    return Column(
      children: [
        Container(
          height: 0.5,
          color: const Color(0xff8F959E).withOpacity(0.3),
          margin: const EdgeInsets.only(bottom: 7.5),
        ),
        Row(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 16, bottom: 16),
              child: Text(
                '已选择：%s'.trArgs(
                    [(selectLength > 0 ? selectLength : '0').toString()]),
                style: const TextStyle(color: Color(0xff6179F2), fontSize: 14),
              ),
            ),
            const Expanded(
              child: SizedBox(),
            ),
            Container(
              margin: const EdgeInsets.only(right: 16, bottom: 16),
              width: 100,
              height: 36,
              child: TextButton(
                onPressed: onPressed,
                style: TextButton.styleFrom(
                  backgroundColor: hasSelected
                      ? theme.primaryColor
                      : theme.scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                      fontSize: 14,
                      color: hasSelected
                          ? Colors.white
                          : theme.textTheme.bodyText1.color),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onValueChange(int index) {
    select = index;
    _selectedChannels.clear();
    if (index >= 0) {
      final channel = _channels[index];
      _selectedChannels[channel.id] = channel;
    }
    _confirmStatus = _selectedChannels.isNotEmpty
        ? FbButtonStatus.normal
        : FbButtonStatus.unable;
    _refresh();

    // final v = !_channelValue[index];
    // if (_selectedChannels.length >= 9 && v) {
    //   showToast('同时最多只能选择9个频道'.tr);
    //   return;
    // }
    // final channel = _channels[index];
    // if (v) {
    //   _selectedChannels[channel.id] = channel;
    // } else
    //   _selectedChannels.remove(channel.id);
    // _channelValue[index] = v;
    // _refresh();
  }

  void onConnectivityChanged(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      isNetWorkNormal = false;
    } else
      isNetWorkNormal = true;
    _refresh();
  }

  bool isChannelColorBlack(ChatChannel channel) {
    if (_selectedChannels.length != 9) return true;
    if (_selectedChannels[channel.id] != null) return true;
    return false;
  }

  void clearData() {
    _channels.clear();
    _selectedChannels.clear();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }
}
