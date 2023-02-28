import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'package:get/get.dart';
import 'package:im/api/guild_api.dart';
import 'package:im/api/user_api.dart';
import 'package:im/api/util_api.dart';
import 'package:im/app.dart';
import 'package:im/app/routes/app_pages.dart' as app_pages;
import 'package:im/common/permission/permission_utils.dart';
import 'package:im/core/config.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/db/async_db/test_database_utils.dart';
import 'package:im/db/db.dart';
import 'package:im/global.dart';
import 'package:im/pages/guild_setting/guild/quit_guild.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:im/pages/logging/let_log.dart';
import 'package:im/routes.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/themes/const.dart';
import 'package:im/utils/show_confirm_dialog.dart';
import 'package:im/utils/web_view_utils.dart';
import 'package:im/widgets/avatar.dart';
import 'package:im/widgets/toast.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:multi_image_picker/multi_image_picker.dart';
import 'package:oktoast/oktoast.dart';
import 'package:pedantic/pedantic.dart';
import 'package:quest_system/internal/quest_system.dart';
import 'package:quest_system/quest_system.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sqlite_viewer/sqlite_viewer.dart';

TextEditingController _proxyInputController = TextEditingController();

class DebugPage extends StatefulWidget {
  static bool _isShown = false;

  static void show() {
    if (_isShown) return;
    if (!Config.isDebug && Config.env == Env.pro) return;

    _isShown = true;
    Global.navigatorKey.currentState
        .push(MaterialPageRoute(
          builder: (_) => DebugPage(),
          fullscreenDialog: true,
        ))
        .then((_) => _isShown = false);
  }

  @override
  _DebugPageState createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  ValueNotifier<bool> _useHttps;
  ValueNotifier<bool> _useProxy;

  TextEditingController _fileSizeController;
  TextEditingController _fileCountController;

  @override
  void initState() {
    _useHttps = ValueNotifier(Config.useHttps);
    _useProxy = ValueNotifier(Http.useProxy);
    _proxyInputController.text =
        SpService.to.getString(SP.proxySharedKey) ?? "";

    _fileSizeController = TextEditingController(text: "30000");
    _fileCountController = TextEditingController(text: "5000");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("调试面板".tr),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  "当前环境：${Config.env.toString()}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _showNetworkActionSheet(context);
                  },
                  child: Text("切换".tr),
                )
              ],
            ),
            Wrap(
              children: [
                TextButton(
                  onPressed: () {
                    Get.toNamed(app_pages.Routes.UI_GALLERY);
                  },
                  child: const Text("UI 设计规范"),
                ),
                TextButton(
                  onPressed: () =>
                      Get.toNamed(app_pages.Routes.DYNAMIC_VIEW_PREVIEW),
                  child: const Text("动态卡片预览"),
                ),
                const TextButton(
                  onPressed: App.togglePerformance,
                  child: Text("Performance"),
                ),
              ],
            ),
            Wrap(
              spacing: 16,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    Routes.pushRtcLogPage(context);
                  },
                  child: Text("音视频日志".tr),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => LoggerPage()));
                  },
                  child: Text("系统日志".tr),
                ),
                TextButton(
                  onPressed: () {
                    Get.to(Scaffold(
                      appBar: AppBar(
                        title: const Text("任务数据"),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              await UtilApi.delConfig('guidance');
                              await Db.guideBox.clear();
                              Toast.iconToast(
                                  icon: ToastIcon.success, label: "清理成功，请重启");
                            },
                            child: const Text("Clear"),
                          ),
                          TextButton(
                            onPressed: () {
                              final data = QuestSystem.acceptVisitor(
                                  JsonExportVisitor());
                              Clipboard.setData(
                                  ClipboardData(text: jsonEncode(data)));
                              Toast.iconToast(
                                  icon: ToastIcon.success,
                                  label: "Copy Success");
                            },
                            child: const Text("Copy"),
                          )
                        ],
                      ),
                      body: SafeArea(
                        child: Material(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: JsonView.map(
                                QuestSystem.acceptVisitor(JsonExportVisitor())),
                          ),
                        ),
                      ),
                    ));
                  },
                  child: Text("任务数据".tr),
                ),
                TextButton(
                  onPressed: () {
                    Get.to(Scaffold(
                      body: ListView(
                          children: ChatTargetsModel.instance.chatTargets
                              .where((e) => PermissionUtils.isGuildOwner(
                                  userId: Global.user.id, guildId: e.id))
                              .map((e) {
                        return Dismissible(
                          onDismissed: (dir) {
                            unawaited(
                                GuildApi.dissolveGuild(Global.user.id, e.id)
                                    .then((_) => quitGuild(e,
                                        backHomeAndSelectDefaultChatTarget:
                                            false)));
                          },
                          confirmDismiss: (_) async {
                            return true ==
                                await showConfirmDialog(title: "确定删除服务器？");
                          },
                          key: Key(e.id),
                          child: ListTile(
                            leading: Avatar(url: (e as GuildTarget).icon),
                            title: Text(e.name),
                          ),
                        );
                      }).toList()),
                    ));
                  },
                  child: const Text("解散服务器"),
                ),
                TextButton(
                    onPressed: () async {
                      await UserApi.completeQTForm(Global.user.id);
                      showToast("上报问卷完成");
                    },
                    child: const Text("上报问卷")),
                TextButton(
                    onPressed: () async {
                      await MediaPicker.showMediaPicker(maxImages: 8);
                    },
                    child: const Text("圈子发照片")),
              ],
            ),
            sizeHeight10,
            const Divider(height: 16),
            Text(
              "推送 & 通知".tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 16,
              children: <Widget>[
                TextButton(
                  onPressed: () => JPush().setBadge(0),
                  child: Text("清空角标".tr),
                ),
                TextButton(
                  onPressed: () => JPush().clearAllNotifications(),
                  child: Text("清空通知".tr),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              "储存".tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 16,
              children: <Widget>[
                TextButton(
                  onPressed: Db.delete,
                  child: Text("清空本地数据库".tr),
                ),
                TextButton(
                  onPressed: () => SharedPreferences.getInstance()
                      .then((value) => value.clear()),
                  child: Text("清空 SharedPreferences".tr),
                ),
                TextButton(
                  onPressed: () async {
                    showToast("测试开始，请耐心等待");
                    final TestDatabaseUtils testUtils = TestDatabaseUtils();
                    await testUtils.startTest();
                    showToast("测试完成");
                  },
                  child: Text("DB单元测试".tr),
                ),
                TextButton(
                  onPressed: () async {
                    //showToast("测试开始，请耐心等待");
                    await Db.deleteAndReOpenBox();
                    showToast("测试完成");
                  },
                  child: const Text("清理Hive DB"),
                ),
                TextButton(
                  onPressed: () async {
                    //showToast("测试开始，请耐心等待");
                    if (Db.segmentMemberListBox.isOpen) {
                      await Db.segmentMemberListBox.clear();
                    }
                    showToast("测试完成");
                  },
                  child: const Text("清除segmentMemberListBox"),
                ),
                TextButton(
                  onPressed: () async {
                    //showToast("测试开始，请耐心等待");
                    if (Db.userInfoBox.isOpen) {
                      await Db.userInfoBox.clear();
                    }
                    showToast("测试完成");
                  },
                  child: const Text("清除userInfoBox"),
                ),

                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Flexible(
                        flex: 5,
                        child: TextField(
                          controller: _fileSizeController,
                          decoration: InputDecoration(
                            hintText: "文件大小".tr,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 5,
                        child: TextField(
                          controller: _fileCountController,
                          decoration: InputDecoration(
                            hintText: "文件个数".tr,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      // Flexible(
                      //   flex: 8,
                      //   child: TextButton(
                      //     onPressed: () async {
                      //       Loading.show(context);
                      //       final String path =
                      //           await CustomCacheManager.instance.store.fileSystem;
                      //       final size = int.parse(_fileSizeController.text);
                      //       final count = int.parse(_fileCountController.text);
                      //       final bytes = List<int>(size);
                      //       for (int i = 0; i < size; i++) {
                      //         bytes[i] = 200;
                      //       }
                      //       for (int i = 0; i < count; i++) {
                      //         final filePath = join(path,
                      //             '$i${DateTime.now().millisecondsSinceEpoch.toString()}');
                      //         final file = File(filePath);
                      //         file.writeAsBytesSync(bytes);
                      //       }
                      //       Loading.showDelayTip(context, "插入完成",
                      //           widget: const Icon(
                      //             IconFont.buffToastRight,
                      //             color: Colors.white,
                      //             size: 36,
                      //           ));
                      //     },
                      //     child: Text("插入缓存数据"),
                      //   ),
                      // )
                    ],
                  ),
                ),

                // Visibility(
                //   visible: kDebugMode,
                //   child: RaisedButton(
                //     child: Text("查看数据库"),
                //     onPressed: () => Navigator.push(context,
                //         MaterialPageRoute(builder: (_) => DatabaseList())),
                //   ),
                // ),
              ],
            ),
            const Divider(height: 16),
            Text(
              "网络设置".tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: <Widget>[
                Text("使用 HTTPS".tr),
                ValueListenableBuilder<bool>(
                    valueListenable: _useHttps,
                    builder: (context, useHttps, _) {
                      return Switch(
                        value: useHttps,
                        onChanged: (value) async {
                          _useHttps.value = value;
                          await SpService.to.setBool(SP.useHttps, value);
                          showToast("${value ? "启用".tr : "关闭".tr}HTTPS，重启生效");
                        },
                      );
                    }),
                const Spacer(),
                Text("启用代理".tr),
                ValueListenableBuilder<bool>(
                    valueListenable: _useProxy,
                    builder: (context, useProxy, _) {
                      return Switch(
                        value: useProxy,
                        onChanged: (value) async {
                          _useProxy.value = value;
                          await SpService.to.setBool(SP.useProxy, value);
                          showToast("${value ? "启用".tr : "关闭".tr}代理，重启生效");
                        },
                      );
                    }),
              ],
            ),
            ValueListenableBuilder<bool>(
                valueListenable: _useProxy,
                builder: (context, useProxy, _) {
                  return Offstage(
                    offstage: !useProxy,
                    child: Row(
                      children: <Widget>[
                        Text("HTTP 代理".tr),
                        sizeWidth8,
                        Expanded(
                          child: TextField(
                            controller: _proxyInputController,
                            decoration: InputDecoration(
                              helperText: "注意：此选项不能抓取 ws 流量".tr,
                              hintText: "0.0.0.0:8888",
                              border: const UnderlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: TextButton(
                            onPressed: () {
                              final text = _proxyInputController.text.trim();

                              if (!RegExp(r"^(\d{1,3}\.){3}\d{1,3}:\d{2,5}$")
                                  .hasMatch(text)) {
                                showToast("IP 地址格式错误".tr);
                              } else {
                                SpService.to.setString(SP.proxySharedKey, text);
                                showToast("重启生效 代理：$text");
                              }
                            },
                            child: Text("确认".tr),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            Text(
              "网络设置".tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton(
                onPressed: () {
                  if (GlobalState.selectedChannel.value == null) return;
                  Db.numUnrealOfChannelBox
                      .put(GlobalState.selectedChannel.value.id, 1500);
                  showToast("重启生效".tr);
                },
                child: Text("当前频道未读数设置为 1500".tr)),
            // TextButton(onPressed: s, child: child)
          ],
        ),
      ),
    );
  }

  Future _showNetworkActionSheet(BuildContext context) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
            title: Text("切换网络环境".tr),
            message: Text("当前网络环境：${Config.env}\n*切换环境后请重启App*"),
            actions: <Widget>[
              CupertinoActionSheetAction(
                onPressed: () => _setEnv(context, Env.pro),
                child: Text("正式".tr),
              ),
              CupertinoActionSheetAction(
                onPressed: () => _setEnv(context, Env.pre),
                child: Text("预发布".tr),
              ),
              CupertinoActionSheetAction(
                onPressed: () => _setEnv(context, Env.sandbox),
                child: Text("沙盒".tr),
              ),
              CupertinoActionSheetAction(
                onPressed: () => _setEnv(context, Env.newtest),
                child: const Text("新测试"),
              ),
              CupertinoActionSheetAction(
                onPressed: () => _setEnv(context, Env.dev2),
                child: Text("开发2".tr),
              ),
              CupertinoActionSheetAction(
                onPressed: () => _setEnv(context, Env.dev),
                child: Text("开发1".tr),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: Text("取消".tr),
            ));
      },
    );
  }

  void _setEnv(context, [Env env]) {
    SpService.to.setInt(SP.networkEnvSharedKey, env.index);
    // 清除登录信息
    SpService.to.remove(SP.userInfoSharedKey);
    WebViewUtils.instance().deleteAll();
    Navigator.pop(context);
    showToast("网络环境已设置为 $env，重启后生效");
  }
}
