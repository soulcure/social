import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/app/modules/experimental_features_page/controllers/experimental_features_page_controller.dart';
import 'package:im/common/extension/future_extension.dart';
import 'package:im/loggers.dart';
import 'package:im/pages/home/gif_search_result.dart';
import 'package:im/pages/home/model/input_model.dart';
import 'package:im/pages/home/model/universal_rich_input_controller.dart';
import 'package:provider/provider.dart';

import 'json/text_chat_json.dart';
import 'model/text_channel_controller.dart';

class GifSearchController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static const kSearchMaxLimit = 4;
  static const kPageSize = 18;
  static const kAppearDuration = Duration(seconds: 5);
  final UniversalRichInputController textEditingController;
  final RxString _text = "".obs;
  final FocusNode focusNode;
  final String channelId;

  ScrollController scrollController;
  final RxDouble _scrollPosition = 0.0.obs;
  Worker _scrollIntervaller;
  HttpClientRequest _httpRequest;

  Worker _searchDebouncer;
  Timer _disappearTimer;

  // ignore: unused_field
  int _offset = 0;

  AnimationController animation;
  RxList<GifSearchResult> list = RxList<GifSearchResult>();

  GifSearchController(
      {this.textEditingController, this.focusNode, this.channelId});

  @override
  void onInit() {
    scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.hasClients)
        _scrollPosition.value = scrollController.position.pixels;
    });
    _scrollIntervaller =
        interval(_scrollPosition, _restartTimer, time: 500.milliseconds);

    animation = AnimationController(vsync: this, duration: 200.milliseconds);
    textEditingController.addListener(_onTextChange);
    _searchDebouncer = debounce(_text, _search, time: 100.milliseconds);
    super.onInit();
  }

  @override
  void onClose() {
    scrollController.dispose();
    animation.dispose();
    textEditingController.removeListener(_onTextChange);
    _searchDebouncer.dispose();
    _scrollIntervaller.dispose();
    super.onClose();
  }

  void _onTextChange() {
    if (!focusNode.hasFocus) return;

    final text = textEditingController.text;

    if (text.length <= kSearchMaxLimit) {
      if (text == "@" || text == "#") return;
      _text.value = text;
    }
  }

  Future<void> _search(String text) async {
    final enabled = ExperimentalFeaturesPageController.isEnabled(
        ExperimentalFeatures.GifSearch);
    if (!enabled) return;

    _httpRequest?.abort();
    _disappearTimer?.cancel();

    text = text.trim();

    if (text.isEmpty) {
      disappear();
      return;
    }

    _offset = 0;
    list.value = await fetchFromNet(text: text, offset: 0, limit: kPageSize);
    _offset += list.length;

    if (list.isEmpty) {
      animation.reverse().unawaited;
    } else {
      animation.forward().unawaited;
      _restartTimer();
    }
  }

  void _restartTimer([_]) {
    _disappearTimer?.cancel();
    _disappearTimer = Timer(kAppearDuration, disappear);
  }

  void disappear() {
    // 为了处理 animation 被 dispose 的情况
    try {
      animation.reverse().then((_) {
        list.clear();
      }).unawaited;
      // ignore: empty_catches
    } catch (e) {}
  }

  void send(BuildContext context, GifSearchResult gif) {
    final model = Provider.of<InputModel>(context, listen: false);
    TextChannelController.to(channelId: channelId).sendContent(
      ImageEntity(
        url: gif.url,
        width: gif.w,
        height: gif.h,
      ),
      reply: model.reply,
    );
    model.inputController.clear();
    disappear();
  }

  Future<bool> load() async {
    // 暂时搞不懂接口的参数意义，先不分页
    // final more = await fetchFromNet(
    //   text: textEditingController.text.trim(),
    //   offset: _offset,
    //   limit: kPageSize,
    // );
    // list.addAll(more);
    //
    // _offset += more.length;
    return false;
  }

  Future<List<GifSearchResult>> fetchFromNet({
    String text,
    int offset,
    int limit,
  }) async {
    try {
      final client = HttpClient();
      client.userAgent =
          "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Mobile Safari/537.36";
      _httpRequest = await client.getUrl(Uri.parse(
          "http://weshineapp.com/api/v1/index/search/$text?offset=$offset&limit=$limit&block=list"));
      final response = await _httpRequest.close();
      final body = await response.transform(const Utf8Decoder()).join();
      return (jsonDecode(body)['data'] as List)
          .map((e) => GifSearchResult.fromJson(e))
          .toList();
    } catch (e) {
      logger.fine("failed to search gif due to $e");
      return [];
    }
  }
}
