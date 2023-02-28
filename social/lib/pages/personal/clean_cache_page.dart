import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/icon_font.dart';
import 'package:im/themes/const.dart';
import 'package:im/themes/custom_color.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/widgets/app_bar/custom_appbar.dart';
import 'package:im/widgets/button/primary_button.dart';
import 'package:im/widgets/circular_progress.dart';
import 'package:provider/provider.dart';

import 'clean_cache_model.dart';

class CleanCachePage extends StatefulWidget {
  @override
  _CleanCachePageState createState() => _CleanCachePageState();
}

class _CleanCachePageState extends State<CleanCachePage>
    with SingleTickerProviderStateMixin {
  CleanCacheModel model;

  // 1. 需要监听清除状态变化，使用Rx方式
  // 2. 之所以没有把此状态放入model中，是因为model中改变此值是async的方法（cleanChatCache/cleanDataCache）
  //    如果此异步方法还没执行，而外部又点击了系统返回键，此刻从model出来的isCleaing仍然为false，会导致先退出页面的效果
  RxBool isCleaning = RxBool(false);

  @override
  void initState() {
    super.initState();
    isCleaning.listen((v) {
      setState(() {});
    });
    model = CleanCacheModel();

    model.calcDataCacheSpace();
    model.calcChatSpace();
  }

  @override
  void dispose() {
    isCleaning.close();
    super.dispose();
  }

  String friendlySizeStr(int byteCount) {
    final double gb = byteCount / (1024 * 1024 * 1024);
    if (gb > 1) return "${gb.toStringAsFixed(2)} GB";
    final double mb = byteCount / (1024 * 1024);
    if (mb > 1) return "${mb.toStringAsFixed(1)} MB";
    final double kb = byteCount / 1024;
    if (kb > 1) return "${kb.toStringAsFixed(1)} KB";
    return "${byteCount.toStringAsFixed(0)} B";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop:
          isCleaning.value ? () => Future.value(!isCleaning.value) : null,
      child: Scaffold(
          appBar: CustomAppbar(
            title: '清除缓存'.tr,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          body: ChangeNotifierProvider(
              create: (_) => model,
              builder: (context, _) {
                return Column(
                  children: <Widget>[
                    sizeHeight6,
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Selector<CleanCacheModel, CleanCacheState>(
                            builder: (context, data, child) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "图片及视频缓存".tr,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.21,
                                              color: Color(0xFF363940)),
                                        ),
                                        sizeHeight8,
                                        if (model.dataCacheState ==
                                            CleanCacheState.calculating)
                                          Row(
                                            children: [
                                              const CircularProgress(
                                                size: 16,
                                              ),
                                              sizeWidth8,
                                              Text(
                                                "正在计算存储空间…".tr,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    height: 1.25,
                                                    color: Color(0xFF8F959E)),
                                              ),
                                            ],
                                          )
                                        else
                                          Text(
                                            friendlySizeStr(model.dataSize),
                                            style: const TextStyle(
                                                fontSize: 22,
                                                height: 1.25,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF363940)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  PrimaryButton(
                                    borderRadius: 3,
                                    width: 58,
                                    height: 32,
                                    enabled: model.dataCacheState ==
                                            CleanCacheState.calculated &&
                                        model.dataSize > 0,
                                    disabledStyle: PrimaryButtonStyle(
                                      background: theme.scaffoldBackgroundColor,
                                      text: theme.disabledColor,
                                    ),
                                    onPressed: () async {
                                      final bool isConfirm =
                                          await showConfirmDialog(
                                        title: "清理过程可能需要一点时间，请耐心等待".tr,
                                        confirmStyle: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .copyWith(
                                                fontSize: 17,
                                                color: const Color(0xFF6179F2)),
                                      );
                                      if (isConfirm != null &&
                                          isConfirm == true) {
                                        isCleaning.value = true;
                                        Loading.show(context,
                                            label: "正在清理…".tr);
                                        await model.cleanDataCache();
                                        Loading.showDelayTip(context, "已完成".tr,
                                            widget: const Icon(
                                                IconFont.buffToastRight,
                                                color: Colors.white,
                                                size: 36));
                                        isCleaning.value = false;
                                      }
                                    },
                                    label: "清理".tr,
                                    textStyle: const TextStyle(fontSize: 13),
                                  )
                                ],
                              );
                            },
                            selector: (context, model) {
                              return model.dataCacheState;
                            },
                          ),
                          // sizeHeight8,
                          // Text("包括聊天和浏览动态时缓存的图片、视频等，不会删除聊天记录。",
                          //     style: TextStyle(
                          //         fontSize: 14,
                          //         height: 1.21,
                          //         color: Color(0xFF8F959E))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Selector<CleanCacheModel, CleanCacheState>(
                            builder: (context, data, child) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "聊天消息缓存".tr,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.21,
                                              color: Color(0xFF363940)),
                                        ),
                                        sizeHeight8,
                                        if (model.chatCacheState ==
                                            CleanCacheState.calculating)
                                          Row(
                                            children: [
                                              const CircularProgress(
                                                size: 16,
                                              ),
                                              sizeWidth8,
                                              Text(
                                                "正在计算存储空间…".tr,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    height: 1.25,
                                                    color: Color(0xFF8F959E)),
                                              ),
                                            ],
                                          )
                                        else
                                          Text(
                                            friendlySizeStr(model.chatSize),
                                            style: const TextStyle(
                                                fontSize: 22,
                                                height: 1.25,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF363940)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  PrimaryButton(
                                    borderRadius: 3,
                                    width: 58,
                                    height: 32,
                                    disabledStyle: PrimaryButtonStyle(
                                      background: theme.scaffoldBackgroundColor,
                                      text: theme.disabledColor,
                                    ),
                                    enabled: model.chatCacheState ==
                                            CleanCacheState.calculated &&
                                        model.chatSize > 0,
                                    onPressed: () async {
                                      final bool isConfirm =
                                          await showConfirmDialog(
                                        title: "清理过程可能需要一点时间，请耐心等待".tr,
                                        confirmStyle: Theme.of(context)
                                            .textTheme
                                            .bodyText2
                                            .copyWith(
                                                fontSize: 17,
                                                color: const Color(0xFF6179F2)),
                                      );
                                      if (isConfirm != null &&
                                          isConfirm == true) {
                                        isCleaning.value = true;
                                        Loading.show(context,
                                            label: "正在清理…".tr);
                                        await model.cleanChatCache();
                                        Loading.showDelayTip(context, "已完成".tr,
                                            widget: const Icon(
                                              IconFont.buffToastRight,
                                              color: Colors.white,
                                              size: 36,
                                            ));
                                        isCleaning.value = false;
                                      }
                                    },
                                    label: "清理".tr,
                                    textStyle: const TextStyle(fontSize: 13),
                                  )
                                ],
                              );
                            },
                            selector: (context, model) {
                              return model.chatCacheState;
                            },
                          ),
                          // sizeHeight8,
                          // Text("清理聊天记录后将删除所有频道和私信的历史消息记录",
                          //     style: TextStyle(
                          //         fontSize: 14,
                          //         height: 1.21,
                          //         color: Color(0xFF8F959E))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Text(
                        '清理本地缓存的图片、视频和聊天消息，云端仍会保留原始文件，可随时重新加载'.tr,
                        style: TextStyle(
                            color: CustomColor(context).disableColor,
                            fontSize: 14),
                      ),
                    ),
                  ],
                );
              })),
    );
  }
}
