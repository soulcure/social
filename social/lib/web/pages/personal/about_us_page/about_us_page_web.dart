// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/api.dart';
import 'package:im/themes/const.dart';
import 'package:im/web/widgets/tab_bar/web_tab_bar.dart';
import 'package:im/widgets/dialog/ui_fake.dart' if (dart.library.html) 'dart:ui'
    as ui;

class AboutUsPage extends StatefulWidget {
  @override
  _AboutUsPageState createState() => _AboutUsPageState();

  static void disable() {
    final plv = html.document.getElementsByTagName('flt-platform-view');
    if (plv.isEmpty) return;
    final html.HtmlElement flt = plv.first;
    final terms = flt?.shadowRoot?.getElementById('terms');
    final privacy = flt?.shadowRoot?.getElementById('privacy');
    terms?.style?.pointerEvents = 'none';
    privacy?.style?.pointerEvents = 'none';
  }

  static void enable() {
    final plv = html.document.getElementsByTagName('flt-platform-view');
    if (plv.isEmpty) return;
    final html.HtmlElement flt = plv.first;
    final terms = flt?.shadowRoot?.getElementById('terms');
    final privacy = flt?.shadowRoot?.getElementById('privacy');
    terms?.style?.pointerEvents = 'auto';
    privacy?.style?.pointerEvents = 'auto';
  }
}

class _AboutUsPageState extends State<AboutUsPage>
    with TickerProviderStateMixin {
  WebTabBarModel _model;
  TabController _tabController;
  html.IFrameElement _termsElement;
  html.IFrameElement _privacyElement;

  @override
  void initState() {
    _termsElement = html.IFrameElement()
      ..id = 'terms'
      ..src =
          'https://${ApiUrl.termsUrl}?udx=93${DateTime.now().millisecondsSinceEpoch}3c4'
      ..height = '600'
      ..allowFullscreen = true
      ..style.border = 'none';
    ui.platformViewRegistry
        .registerViewFactory('termsUrl', (viewId) => _termsElement);
    _privacyElement = html.IFrameElement()
      ..id = 'privacy'
      ..src =
          'https://${ApiUrl.privacyUrl}?udx=93${DateTime.now().millisecondsSinceEpoch}3c4'
      ..height = '600'
      ..allowFullscreen = true
      ..style.border = 'none';
    ui.platformViewRegistry
        .registerViewFactory('privacyUrl', (viewId) => _privacyElement);
    _tabController = TabController(length: 2, vsync: this);
    _model = WebTabBarModel();
    _model.updateTabController(_tabController);
    _model.updateTabTitles(['用户协议'.tr, '隐私保护'.tr]);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: _model,
        builder: (c) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(-20, 0),
                child: const WebTabBar(),
              ),
              sizeHeight12,
              SizedBox(
                width: 680,
                height: 600,
                child: TabBarView(
                  controller: _model.tabController,
                  children: const [
                    HtmlElementView(viewType: 'termsUrl'),
                    HtmlElementView(viewType: 'privacyUrl'),
                  ],
                ),
              )
            ],
          );
        });
  }
}
