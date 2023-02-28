// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:math';
import 'dart:typed_data';

import 'package:im/dlog/dlog_manager.dart';
import 'package:im/hybrid/jpush_util.dart';
import 'package:im/web/js/cookie_utils.dart';
import 'package:im/web/utils/web_util/web_util.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

class WebUtil implements WebUtilBase {
  @override
  void downloadFile(String url) {
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..target = '_blank'
      ..download = 'xxx';
    html.document.body.children.add(anchor);
    anchor.click();
    html.document.body.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  @override
  String getQuery() {
    final href = getHref();
    final String queryString = Uri.parse(href).query;
    return queryString.isEmpty ? '' : '?$queryString';
  }

  @override
  String getHref() {
    return js.context['location']['href'];
  }

  @override
  void pushLocalNotification(
      String title, String body, Map<String, String> extra) {
    final notification = html.Notification(title,
        body: body.substring(0, min(body.length, 200)),
        icon:
            'https://fanbook-1251001060.cos.ap-guangzhou.myqcloud.com/fanbook/icon/app-icon.png');
    notification.onClick.listen((event) {
      js.context.callMethod('focus');
      _handlerNotification(extra);
      notification.close();
    });
    Future.delayed(const Duration(seconds: 3), notification.close);
  }

  @override
  void initNotification() {
    html.Notification.requestPermission();
  }

  @override
  void setBadge(int badge) {
    if (badge == 0)
      html.document.title = 'Fanbook';
    else {
      final strBadge = badge > 99 ? '+99' : '$badge';
      html.document.title = '[$strBadge] Fanbook';
    }
  }

  @override
  void callJsMethod(String methodName, List<dynamic> params) {
    js.context.callMethod(methodName, params);
  }

  /// 处理通知跳转
  void _handlerNotification(Map extra) {
    final String type = "${extra["type"]}";
    if (type != null) {
      switch (int.parse(type)) {
        case JPushType.relationAdd:
        case JPushType.relationCancel:
          JPushUtil.gotoRelation();
          break;
        case JPushType.relationFriend:
          final String userId = extra["user_id"];
          if (userId != null) {
            JPushUtil.gotoDmChannel(userId);
          }
          break;
        case JPushType.channel:
          if (extra["channel_id"] != null) {
            JPushUtil.gotoChannel(
              "${extra["channel_id"]}",
              "${extra["message_id"]}",
              "${extra["channel_type"] ?? ""}",
              "${extra["user_id"]}",
            );
          }
          break;
        case JPushType.circleComment:
        // ignore: no_duplicate_case_values
        case JPushType.circleLike:
          final channelId = extra['channel_id'];
          final guildId = extra['guild_id'];

          /// TODO 已失效，缺少参数
          JPushUtil.gotoCircle(guildId, channelId, autoPushCircleMessage: true);
          break;
        default:
          break;
      }
    }
  }

  @override
  // ignore: type_annotate_public_apis
  Future<Asset> getAssetInfo(file) async {
    if (file.type.startsWith('image/')) {
      return getImageInfo(file);
    } else if (file.type.startsWith('video/')) {
      return getVideoInfo(file);
    } else {
      return null;
    }
  }

  @override
  // ignore: type_annotate_public_apis
  Future<Asset> getVideoInfo(file) async {
    assert(file is html.File);
    final Completer<Asset> completer = Completer<Asset>();
    final videoUrl = await createBlobUrlFromFile(file);
    final element = html.VideoElement();
    element.src = videoUrl;
    element.muted = true;
    element.autoplay = true;
    element.onLoadedData.capture((event) async {
      final canvas = html.CanvasElement()
        ..width = element.videoWidth
        ..height = element.videoHeight;
      html.document.body.append(element);
      canvas.context2D.drawImageToRect(
          element, Rectangle(0, 0, element.videoWidth, element.videoHeight));
      final blob = await canvas.toBlob();
      final thumbUrl = html.Url.createObjectUrlFromBlob(blob);
      element.remove();
      completer.complete(Asset(
          null,
          videoUrl,
          file.name,
          element.videoWidth.toDouble(),
          element.videoHeight.toDouble(),
          file.type,
          duration: element.duration,
          thumbName: 'thumb.jpg',
          thumbFilePath: thumbUrl));
    });
    return completer.future;
  }

  @override
  // ignore: type_annotate_public_apis
  Future<Asset> getImageInfo(file) async {
    assert(file is html.File);

    final Completer<Asset> completer = Completer<Asset>();
    final src = await createBlobUrlFromFile(file);
    final element = html.ImageElement();
    element.src = src;
    element.onLoad.capture((event) async {
      completer.complete(Asset(
        null,
        src,
        file.name,
        element.width.toDouble(),
        element.height.toDouble(),
        file.type,
      ));
    });
    return completer.future;
  }

  @override
  // ignore: type_annotate_public_apis
  Future<String> createBlobUrlFromFile(file) {
    assert(file is html.File);
    final Completer<String> completer = Completer();
    final reader = html.FileReader();
    reader.onLoad.first.then((event) {
      completer.complete(html.Url.createObjectUrlFromBlob(file));
    });
    reader.readAsDataUrl(file);
    return completer.future;
  }

  @override
  // ignore: type_annotate_public_apis
  Future<Uint8List> createUnit8ListFromFile(file) {
    assert(file is html.File);
    final Completer<Uint8List> completer = Completer();
    final reader = html.FileReader();
    reader.onLoadEnd.listen((e) {
      completer.complete(reader.result);
    });
    reader.readAsArrayBuffer(file);
    return completer.future;
  }

  @override
  Future<Uint8List> compressImageFromElement(String blobPath,
      {double quality = 0.6}) {
    final element = html.ImageElement(src: blobPath);

    final Completer<Uint8List> completer = Completer<Uint8List>();
    element.onLoad.listen((event) {
      final canvas = html.CanvasElement()
        ..width = element.width
        ..height = element.height;
      canvas.context2D.drawImageToRect(
          element, Rectangle(0, 0, element.width, element.height));
      final base64 = canvas.toDataUrl('image/jpeg', quality);
      final size = base64Decode(base64.substring(23));
      completer.complete(size);
    });
    return completer.future.timeout(const Duration(seconds: 1));
  }

  @override
  void refreshHtml() {
    html.window.location.reload();
  }

  @override
  void setCookie(
    String key,
    String value, {
    String domain,
    String path,
    bool secure,
    int expires,
  }) {
    CookieUtils.set(
      key,
      value,
      SetCookieOptions(
        domain: domain,
        path: path,
        secure: secure,
        expires: expires,
      ),
    );
  }

  @override
  String getCookie(String key) {
    return CookieUtils.get(key);
  }

  @override
  void wakeUpApp(String postId, String topicId) {
    js.context.callMethod("launchApp", [
      postId,
      topicId,
    ]);

    DLogManager.getInstance()
        .customEvent(actionEventId: 'click_download_fanbook');
  }

  @override
  String gzip(Uint8List bytes) {
    return js.context.callMethod("gzip", [bytes]);
  }
}
