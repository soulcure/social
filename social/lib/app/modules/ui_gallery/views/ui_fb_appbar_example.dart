///
/// @FilePath       : \social\lib\app\modules\ui_gallery\views\ui_appbar_example.dart
///
/// @Info           : UI样例展示： 统一导航栏
///
/// @Author         : Whiskee Chan
/// @Date           : 2021-12-17 14:34:37
/// @Version        : 1.0.0
///
/// Copyright 2021 iDreamSky FanBook, All Rights Reserved.
///
/// @LastEditors    : Whiskee Chan
/// @LastEditTime   : 2021-12-22 10:35:46
///
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:im/icon_font.dart';
import 'package:im/utils/show_bottom_modal.dart';
import 'package:im/widgets/app_bar/appbar_action_model.dart';
import 'package:im/widgets/app_bar/appbar_builder.dart';
import 'package:im/widgets/toast.dart';
import 'package:oktoast/oktoast.dart';

class UIFbAppBarExample extends StatefulWidget {
  const UIFbAppBarExample();

  @override
  _UIFbAppBarExampleState createState() => _UIFbAppBarExampleState();
}

class _UIFbAppBarExampleState extends State<UIFbAppBarExample> {
  /// 可展示类型
  List<int> showTypes = [0, 1, 2, 3, 4, 5];

  /// 标题栏样式选择
  int appBarType = 0;

  /// 标题栏位置：false 为 居中展示标题，true 为左侧展示标题
  bool isLeftTitle = false;

  /// 右侧按钮是否可点击
  bool isRightCanClick = true;

  /// 显示加载圈
  bool isShowLoading = false;

  /// 箭头方向
  bool isArrowDown = true;

  /// 可用按钮
  List<AppBarActionModelInterface> actions = [];

  /// 未读消息监听
  final ValueNotifier<int> _backMsgNum = ValueNotifier<int>(0);

  /// 未读消息监听
  final ValueNotifier<int> _unreadMsgNum = ValueNotifier<int>(0);

  /// 关注、取消 圈子
  bool isCircleSelect = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _assembleAppBar(),
        body: ListView(
          children: [
            const Text("\n  组件路径: ../lib/widgets/app_bar"),
            const Text("\n  样式选择: "),
            Column(
              children: showTypes
                  .map((type) => TextButton(
                      onPressed: () {
                        setState(() {
                          if (type == 5) {
                            _showFbAppBarSheetDialog();
                          } else {
                            appBarType = type;
                          }
                        });
                      },
                      child: Text(_getTitle(type),
                          style: TextStyle(
                              color: Theme.of(context).primaryColor))))
                  .toList(),
            ),
            const Text("\n  -- 属性 : "),
            Row(
              children: [
                TextButton(
                    onPressed: !_canPropertiesUse("标题")
                        ? null
                        : () => setState(() {
                              isLeftTitle = !isLeftTitle;
                            }),
                    child: Text("${isLeftTitle ? "居中" : "左侧"}标题")),
                TextButton(
                    onPressed: !_canPropertiesUse("右侧按钮")
                        ? null
                        : () => setState(() {
                              isRightCanClick = !isRightCanClick;
                              actions.forEach((action) {
                                if (action.actionType ==
                                        AppBarActionType.text_light ||
                                    action.actionType ==
                                        AppBarActionType.text_primary) {
                                  action.isEnable = isRightCanClick;
                                }
                              });
                            }),
                    child: Text("${isRightCanClick ? "禁用" : "启用"}右侧按钮")),
              ],
            ),
            const Text("  -- 右侧按钮 : "),
            Row(
              children: [
                TextButton(
                    onPressed: !_canPropertiesUse("文字按钮")
                        ? null
                        : () => setState(() {
                              isShowLoading = !isShowLoading;
                              actions.forEach((action) {
                                action.isLoading = isShowLoading;
                              });
                            }),
                    child: Text("${isShowLoading ? "关闭" : "显示"} loading")),
              ],
            ),
            Row(
              children: [
                TextButton(
                    onPressed: !_canPropertiesUse("文字按钮")
                        ? null
                        : () => setState(() {
                              actions.clear();
                              actions.add(
                                  // 测试样式：纯文字按钮
                                  AppBarTextPureActionModel(
                                "保存",
                                isLoading: isShowLoading,
                                actionBlock: () {
                                  showToast("我保存了！");
                                },
                              ));
                            }),
                    child: const Text("纯文字按钮")),
                TextButton(
                    onPressed: !_canPropertiesUse("文字按钮")
                        ? null
                        : () => setState(() {
                              actions.clear();
                              actions.add(
                                // 测试样式：填充背景文字按钮
                                AppBarTextPrimaryActionModel("保存",
                                    isEnable: isRightCanClick,
                                    isLoading: isShowLoading, actionBlock: () {
                                  showToast("我保存了！");
                                }),
                              );
                            }),
                    child: const Text("填充背景文字按钮")),
                TextButton(
                    onPressed: !_canPropertiesUse("文字按钮")
                        ? null
                        : () => setState(() {
                              actions.clear();
                              actions.add(
                                // 测试样式：浅色背景文字按钮
                                AppBarTextLightActionModel("下一步",
                                    isEnable: isRightCanClick,
                                    isLoading: isShowLoading, actionBlock: () {
                                  showToast("你下一步想做啥？");
                                }),
                              );
                            }),
                    child: const Text("浅色背景文字按钮")),
              ],
            ),
            Row(
              children: [
                TextButton(
                    onPressed: !_canPropertiesUse("图标按钮")
                        ? null
                        : () => setState(() {
                              actions.clear();
                              actions.add(
                                AppBarIconActionModel(
                                  IconFont.buffChannelClassificationLarge,
                                  unreadMsgNumListenable: _unreadMsgNum,
                                  isLoading: isShowLoading,
                                  selector: (index) => index,
                                ),
                              );
                            }),
                    child: const Text("单个图标按钮")),
                TextButton(
                    onPressed: !_canPropertiesUse("图标按钮")
                        ? null
                        : () => setState(() {
                              actions.clear();
                              actions.add(AppBarIconActionModel(
                                IconFont.buffCircleAllTopicNew,
                                unreadMsgNumListenable: _unreadMsgNum,
                                isLoading: isShowLoading,
                                selector: (index) => index,
                              ));
                              actions.add(AppBarIconActionModel(
                                IconFont.buffFriendList,
                                isShowRedDotWithNum: true,
                                unreadMsgNumListenable: _unreadMsgNum,
                                selector: (index) => index,
                              ));
                            }),
                    child: const Text("多个图标按钮"))
              ],
            ),
            const Text("  -- 消息数量展示 : "),
            Row(
              children: [
                TextButton(
                    onPressed: !_canPropertiesUse("返回数量")
                        ? null
                        : () => _backMsgNum.value++,
                    child: const Text("增加返回数量")),
                TextButton(
                    onPressed: !_canPropertiesUse("返回数量")
                        ? null
                        : () {
                            if (_backMsgNum.value == 0) return;
                            _backMsgNum.value--;
                          },
                    child: const Text("减少返回数量"))
              ],
            ),
            Row(children: [
              TextButton(
                  onPressed: !_canPropertiesUse("未读消息")
                      ? null
                      : () => _unreadMsgNum.value++,
                  child: const Text("增加未读消息")),
              TextButton(
                  onPressed: !_canPropertiesUse("未读消息")
                      ? null
                      : () {
                          if (_unreadMsgNum.value == 0) return;
                          _unreadMsgNum.value--;
                        },
                  child: const Text("减少未读消息"))
            ]),
          ],
        ));
  }

  /// 创建标题栏
  Widget _assembleAppBar() {
    switch (appBarType) {
      case 0:
        return FbAppBar.custom(
          "这里是标题",
          isCenterTitle: !isLeftTitle,
          leadingShowMsgNum: _backMsgNum,
          actions: actions,
        );
      case 1:
        return FbAppBar.noLeading(
          "没有左侧按钮呢",
          actions: actions,
        );
      case 2:
        return FbAppBar.custom(
          "这里是标题",
          isCenterTitle: !isLeftTitle,
          leadingShowMsgNum: _backMsgNum,
          actions: actions,
        );
      // return FbAppBar.circleInfo(
      //     leadingShowMsgNum: _backMsgNum,
      //     isSubCircleSelect: isCircleSelect,
      //     isRequestSelect: isShowLoading,
      //     subCircleSelectBlock: (isSelect) {
      //       setState(() {
      //         isCircleSelect = isSelect;
      //       });
      //     },
      //     showMoreMenuBlock: () {
      //       Toast.customIconToast(
      //           icon: IconFont.buffAnimaitonRecordSound1, label: "展示更多菜单咯");
      //     });
      case 3:
        return FbAppBar.partners("哭泣站台-王小帅",
            leadingShowMsgNum: _backMsgNum,
            brandDes: "歌曲来自",
            brandLogoUrl:
                "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fandroid-artworks.25pp.com%2Ffs06%2F2016%2F01%2F26%2F2%2F110_e0a270da4de6cd239c8322879eb3bd9a_con.png&refer=http%3A%2F%2Fandroid-artworks.25pp.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1642254127&t=637327f9ad711149d4553c488ae9ca5a",
            brandName: "QQ音乐", showMoreMenuBlock: () {
          Toast.customIconToast(
              icon: IconFont.buffAnimaitonRecordSound1, label: "展示更多菜单咯");
        });
      case 4:
        return FbAppBar.withArrow("文件路径选择", isArrowDown: isArrowDown,
            arrowDirectionBlock: (isDown) {
          setState(() {
            isArrowDown = isDown;
          });
          Toast.customIconToast(
              icon: IconFont.buffChannelLink2, label: isDown ? "向下了" : "向上了");
        });
      default:
        return const FbAppBar.custom("");
    }
  }

  String _getTitle(index) {
    switch (index) {
      case 0:
        return "基础样式: FbAppBar.custom";
      case 1:
        return "无左侧按钮: FbAppBar.noLeading";
      case 2:
        return "圈子详情: FbAppBar.circleInfo";
      case 3:
        return "品牌合作: FbAppBar.partners";
      case 4:
        return "下拉按钮: FbAppBar.dropDown";
      case 5:
        return "Sheet模式: FbAppBar.forSheet";
      default:
        return "";
    }
  }

  /// 判断属性能否启用
  bool _canPropertiesUse(String type) {
    if (type.contains("标题")) {
      return appBarType == 0;
    } else if (type.contains("右侧按钮")) {
      return appBarType == 0 || appBarType == 1;
    } else if (type.contains("文字按钮")) {
      return appBarType == 0 || appBarType == 1 || appBarType == 5;
    } else if (type.contains("图标按钮")) {
      return appBarType == 0 || appBarType == 1 || appBarType == 5;
    } else if (type.contains("返回数量")) {
      return appBarType != 1 && appBarType != 4 || appBarType == 5;
    } else if (type.contains("未读消息")) {
      return appBarType == 0 || appBarType == 1 || appBarType == 5;
    }
    return true;
  }

  /// 展示弹窗：带FbAppBar的弹窗视图
  Future _showFbAppBarSheetDialog() async {
    await showBottomModal(
      context,
      headerBuilder: (c, s) => const FbAppBar.forSheet("Sheet弹窗"),
      // ignore: sized_box_for_whitespace
      builder: (c, s) => Container(
        height: 250,
        child: const Center(
          child: Text("支持多页面展示下，左侧按钮显示为Close或Back"),
        ),
      ),
    );
  }
}
