import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:get/get.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/app.dart';
import 'package:im/app/modules/circle/models/models.dart';
import 'package:im/app/theme/app_theme.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/icon_font.dart';
import 'package:im/pages/guild_setting/circle/entry/circle_entry_controller.dart';
import 'package:im/pages/guild_setting/circle/entry/circle_entry_handler.dart';
import 'package:im/pages/home/components/red_dot.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/home/model/text_channel_event.dart';
import 'package:im/pages/home/model/text_channel_util.dart';
import 'package:im/pages/home/view/text_chat/items/components/parsed_text_extension.dart';
import 'package:im/routes.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/default_theme.dart';
import 'package:im/utils/universal_platform.dart';
import 'package:im/utils/utils.dart';

class CircleEntryView extends StatefulWidget {
  const CircleEntryView({Key key}) : super(key: key);

  @override
  _CircleEntryViewState createState() => _CircleEntryViewState();
}

class _CircleEntryViewState extends State<CircleEntryView> {
  // 圈子入口只有在特定触发条件的时候才去获取API刷新入口参数
  // 1、用户点击服务器
  // 2、每隔2分钟刷新入口
  // 3、从圈子页面退出
  Timer _timer;

  @override
  void initState() {
    ///移动端去掉圈子入口轮询
    if (!UniversalPlatform.isMobileDevice) {
      _timer = Timer.periodic(const Duration(seconds: 120), (timer) {
        if (App.appLifecycleState != AppLifecycleState.resumed) return;
        _refresh();
      });
    }

    final guildTarget = ChatTargetsModel.instance.selectedChatTarget;
    if (guildTarget != null) {
      final guildId = guildTarget.id;
      if (CircleEntryController.to() == null) {
        Get.put(CircleEntryController(guildId));
      } else {
        CircleEntryController.to().updateData(guildId, isUpdate: false);
      }
      _refresh();
    }
    super.initState();
  }

  /// 更新圈子入口信息
  void _refresh() {
    final chatTarget = ChatTargetsModel.instance.selectedChatTarget;
    if (chatTarget == null) return;
    _fetchCircleDataInfo(chatTarget).then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CircleEntryController>(builder: (c) {
      final chatTarget = ChatTargetsModel.instance.selectedChatTarget;
      if (chatTarget == null || chatTarget is! GuildTarget)
        return const SizedBox(height: 1);

      final guildTarget = chatTarget as GuildTarget;
      if (guildTarget.userPending) return const SizedBox(height: 1);
      return Visibility(
          visible: guildTarget.circleAvailable,
          child: _buildEntry(guildTarget, c));
    });
  }

// 现在圈子里发动态是不限制字数的，在频道页的入口展示没有文字的帖子时，改为显示发布内容的类型
// 仅图片，入口文案显示为[图片]
// 仅视频，入口文案显示为[视频]
// 图片和视频都有，入口文案显示为[视频]
  Widget _buildEntry(GuildTarget target, CircleEntryController c) {
    String entryContent = '';
    bool containPic = false;
    bool containVideo = false;
    final guildId = target.id;
    String channelId =
        target.circleData != null ? target.circleData['channel_id'] : null;
    int newPostTotal = 0;
    if (circleEntryCache[target.id] != null) {
      final bean = c.bean;
      if (bean == null) return const SizedBox();
      channelId = bean.channelId;
      if (channelId.noValue && target.circleData != null)
        channelId = target.circleData['channel_id'];
      newPostTotal = bean.newPostTotal ?? 0;

      try {
        final postType = bean.postType ?? '';
        String content = '';
        switch (postType) {
          case '':
            content = bean.content;
            break;
          case CirclePostDataType.image:
          case CirclePostDataType.video:
          case CirclePostDataType.article:
            content = bean.contentV2;
            break;
          default:
            throw Exception('当前版本暂不支持查看此消息类型');
            break;
        }
        if (bean.title.hasValue) {
          containPic = false;
          containVideo = false;
          entryContent = bean.title;
        }
        if (content != null && content.isNotEmpty) {
          final operationList = getOperationList(content);
          final richTextSb = getRichText(operationList);
          content = richTextSb.toString().compressLineString();
          entryContent = entryContent.isEmpty ? content : entryContent;
          for (final item in operationList) {
            containPic = containPic || item.isImage;
            containVideo = containVideo || item.isVideo;
          }
        }
      } catch (e) {
        containPic = false;
        containVideo = false;
        entryContent = bean.title ?? '当前版本暂不支持查看此消息类型'.tr;
      }
      if (entryContent.isEmpty) {
        if (containVideo) {
          entryContent = '[视频]'.tr;
        } else if (containPic) {
          entryContent = '[图片]'.tr;
        }
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await Routes.pushCircleMainPage(context, guildId, channelId);
        // await _refresh();
      },
      child: Column(
        children: [
          _buildEntryHeader(
              '0',
              newPostTotal > 0
                  ? '%s条新动态'.trArgs([newPostTotal.toString()])
                  : '发现更多精彩'.tr),
          AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              reverseDuration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SizeTransition(sizeFactor: animation, child: child);
              },
              child: SizedBox(
                key: ValueKey(circleEntryCache[target.id]?.hashCode ?? 0),
                child: circleEntryCache[target.id] != null &&
                        (entryContent.hasValue || containVideo || containPic)
                    ? Container(
                        alignment: Alignment.topCenter,
                        padding:
                            const EdgeInsets.only(left: 12, right: 12, top: 3),
                        height: 32,
                        child: Row(
                          children: [
                            if (containVideo)
                              Icon(
                                IconFont.buffCircleVideoThumb,
                                size: 16,
                                color: Theme.of(context).disabledColor,
                              )
                            else if (containPic)
                              Icon(
                                IconFont.buffCircleImageThumb,
                                size: 16,
                                color: Theme.of(context).disabledColor,
                              ),
                            Visibility(
                                visible: containPic || containVideo,
                                child: sizeWidth8),
                            Expanded(
                              child: ParsedText(
                                style: appThemeData.textTheme.caption,
                                text: entryContent,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                parse: [
                                  ParsedTextExtension.matchCusEmoText(
                                    context,
                                    appThemeData.textTheme.caption.fontSize,
                                  ),
                                  ParsedTextExtension.matchAtText(
                                    context,
                                    textStyle: appThemeData.textTheme.caption,
                                    useDefaultColor: false,
                                    guildId: guildId,
                                    tapToShowUserInfo: false,
                                  ),
                                  ParsedTextExtension.matchChannelLink(
                                    context,
                                    textStyle: appThemeData.textTheme.caption,
                                    hasBgColor: false,
                                    tapToJumpChannel: false,
                                    refererChannelSource:
                                        RefererChannelSource.CircleLink,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : sizedBox,
              ))
        ],
      ),
    );
  }

  Widget _buildEntryHeader(String unreadCount, String title) {
    final circleStyle =
        Theme.of(context).textTheme.bodyText2.copyWith(color: primaryColor);
    final unreadNum = int.tryParse(unreadCount) ?? 0;
    //隐藏圈子消息红点
    final showUnreadCount =
        // ignore: avoid_bool_literals_in_conditional_expressions
        UniversalPlatform.isMobileDevice ? false : unreadNum > 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 40,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(IconFont.buffCircleOfFriends,
              size: 16, color: circleStyle.color),
          sizeWidth8,
          Text(
            '圈子'.tr,
            strutStyle: const StrutStyle(
                fontSize: 16, fontWeight: FontWeight.w500, height: 1.25),
            style: TextStyle(
              fontSize: 16,
              color: circleStyle.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (showUnreadCount) ...[
            const Expanded(child: Text('')),
            RedDot(unreadNum)
          ] else
            Expanded(
                child: Text(
              title,
              strutStyle: const StrutStyle(fontSize: 14, height: 1.25),
              style: Theme.of(context).textTheme.bodyText1.copyWith(
                    fontSize: 14,
                    color: appThemeData.dividerColor.withOpacity(1),
                  ),
              textAlign: TextAlign.right,
            )),
          const SizedBox(width: 4),
          Icon(
            IconFont.buffPayArrowNext,
            size: 12,
            color: appThemeData.dividerColor.withOpacity(.75),
          ),
        ],
      ),
    );
  }

  ///调用 guildInfo 接口，获取圈子入口信息
  Future _fetchCircleDataInfo(GuildTarget target) async {
    try {
      final guildId = target.id;
      // print(
      //     'getChat fetchCircle: $guildId, ${circleEntryCache[guildId] != null}，circleAvailable: ${target.circleAvailable}');
      if (!target.circleAvailable) return;

      ///移动端：每个服务器只调用一次
      if (UniversalPlatform.isMobileDevice && circleEntryCache[guildId] != null)
        return;

      final result = await CircleApi.circlePostInfo(guildId);

      //移动端已去掉圈子红点，无需调用'圈子通知数量'接口
      if (!UniversalPlatform.isMobileDevice &&
          result['circle_display'].toString() == 'true') {
        final circleList = result['list'];
        for (var i = 0; i < circleList?.length ?? 0; i++) {
          final circleId = circleList[i]['channel_id']?.toString() ?? '';
          final unreadData = await CircleApi.circleUnreadNewsCount(circleId);
          circleList[i]['unread_count'] = unreadData['total'];
        }
        final unreadNum = (result['list'] as List).last['unread_count'];
        // 发送服务器圈子未读数刷新事件
        TextChannelUtil.instance.stream.add(WebCircleUnreadEvent(unreadNum));
      }

      CircleEntryBean newBean;
      if (result['list'] != null) {
        final circleDataList = result['list'] as List;
        if (circleDataList.isNotEmpty) {
          final first = circleDataList[0];
          final records = first["records"] as List;
          if (records != null && records.isNotEmpty) {
            final map = Map<String, dynamic>.from(records[0]);
            newBean = CircleEntryBean.fromJson(map);
          }
          newBean ??= CircleEntryBean();
          final total = first['new_post_total'] as int ?? 0;
          newBean.newPostTotal = total >= 0 ? total : 0;
        }
        // print('getChat fetchCircle newBean: ${newBean.title}');
      }
      circleEntryCache[guildId] = newBean;

      final c = CircleEntryController.to();
      if (c != null && c.guildId == guildId)
        c.updateData(guildId, isUpdate: false);
    } catch (_) {
      // print('getChat fetchCircle error: $e');
    }
  }
}
