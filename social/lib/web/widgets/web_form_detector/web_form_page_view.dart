import 'package:flutter/material.dart';
import 'package:im/web/widgets/shake_animation_widget/shake_animation_widget.dart';
import 'package:im/web/widgets/shake_animation_widget/src/shake_animation_widget.dart';
import 'package:im/web/widgets/web_form_detector/web_form_confirm_box.dart';
import 'package:im/web/widgets/web_form_detector/web_form_detector_model.dart';
import 'package:im/web/widgets/web_form_detector/web_form_tab_item.dart';
import 'package:im/web/widgets/web_form_detector/web_form_tab_view.dart';
import 'package:provider/provider.dart';

class WebFormPage extends StatefulWidget {
  final List<WebFormTabItem> tabItems;
  final List<WebFormTabView> tabViews;
  // tab列表下面的组件
  final Widget trailing;
  const WebFormPage({
    @required this.tabItems,
    @required this.tabViews,
    this.trailing = const SizedBox(),
  });
  @override
  _WebFormPageState createState() => _WebFormPageState();
}

class _WebFormPageState extends State<WebFormPage>
    with SingleTickerProviderStateMixin {
  WebFormDetectorModel _model;
  Animation<Offset> offset;
  @override
  void initState() {
    _model = WebFormDetectorModel();
    super.initState();
  }

  @override
  void dispose() {
    _model?.dispose();
    super.dispose();
  }

  WebFormTabView getTabView(int index) {
    return widget.tabViews.firstWhere((element) {
      final ValueKey<int> key = element.key;
      return key.value == index;
    }, orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: _model,
        child: ShakeAnimationWidget(
          shakeAnimationController: _model.shakeAnimationController,
          shakeAnimationType: ShakeAnimationType.LeftRightShake,
          isForward: false,
          shakeRange: 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 240,
                  padding: const EdgeInsets.only(top: 100),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...widget.tabItems
                          .map((e) => !e.isTab
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: e,
                                )
                              : e)
                          .toList(),
                      widget.trailing,
                    ],
                  )),
              Expanded(
                child: Stack(
                  children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(color: Colors.white),
                      child: ValueListenableBuilder<int>(
                          valueListenable: _model.tabIndex,
                          builder: (context, tabIndex, _) {
                            final tabView = getTabView(tabIndex);
                            if (tabView == null) return const SizedBox();
                            return AnimatedSwitcher(
                                reverseDuration:
                                    const Duration(milliseconds: 200),
                                duration: const Duration(milliseconds: 400),
                                transitionBuilder: (child, animation) {
                                  final Animation<Offset> _offsetAnimation =
                                      Tween<Offset>(
                                    begin: const Offset(-0.02, 0),
                                    end: const Offset(0, 0),
                                  ).animate(animation);
                                  return SlideTransition(
                                    position: _offsetAnimation,
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: tabView);
                          }),
                    ),
                    Align(
                        alignment: Alignment.bottomLeft,
                        child: WebFormConfirmBox()),
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
