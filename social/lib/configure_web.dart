// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:im/web/utils/web_util/web_util.dart';
import 'package:url_strategy/url_strategy.dart';

void configureApp() {
  // Here we set the URL strategy for our web app.
  // It is safe to call this function when running on mobile or desktop as well.
  setPathUrlStrategy();

  html.document.addEventListener('contextmenu', (event) {
    if (WebConfig.preventDefault) {
      event.preventDefault();
    }
    WebConfig.preventDefault = false;
  });
  html.window.document.addEventListener('visibilitychange', (_) {
    WebConfig.isWindowHidden = html.window.document.hidden;
  });
}
