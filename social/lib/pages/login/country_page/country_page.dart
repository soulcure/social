import 'dart:convert';

import 'package:azlistview/azlistview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:im/locale/message_keys.dart';
import 'package:im/utils/orientation_util.dart';
import 'package:im/widgets/button/back_button.dart';
import 'package:lpinyin/lpinyin.dart';

import '../model/country_model.dart';

class CountryPage extends StatefulWidget {
  final Function(CountryModel) callback;

  const CountryPage({this.callback});

  @override
  CountryPageState createState() => CountryPageState();
}

class CountryPageState<T extends CountryPage> extends State<T> {
  String _suspensionTag = "";
  final int suspensionHeight = 32;
  final int itemHeight = 52;
  List<CountryModel> _data = [];

  Future<void> loadInitData() async {
    final String jsonString =
        await rootBundle.loadString('assets/datas/country.json');
    final List list = json.decode(jsonString);
    final List<CountryModel> ret =
        list.map((e) => CountryModel.fromMap(e)).toList();
    ret.sort((a, b) {
      if (a.key == "#") return -1;
      if (Get.locale.languageCode != MessageKeys.zh) {
        return PinyinHelper.getFirstWordPinyin(a.countryNameEn)
            .toUpperCase()
            .substring(0, 1)
            .compareTo(PinyinHelper.getFirstWordPinyin(b.countryNameEn)
                .toUpperCase()
                .substring(0, 1));
      }
      return PinyinHelper.getFirstWordPinyin(a.countryName)
          .toUpperCase()
          .substring(0, 1)
          .compareTo(PinyinHelper.getFirstWordPinyin(b.countryName)
              .toUpperCase()
              .substring(0, 1));
    });
    setState(() => _data = ret);
  }

  @protected
  Widget buildPickItem(CountryModel model) {
    return Column(
      children: <Widget>[
        Offstage(
          offstage: !(model.isShowSuspension == true),
          child: buildSusWidget(Get.locale.languageCode != MessageKeys.zh
              ? PinyinHelper.getFirstWordPinyin(model.countryNameEn)
                  .toUpperCase()
                  .substring(0, 1)
              : PinyinHelper.getFirstWordPinyin(model.countryName)
                  .toUpperCase()
                  .substring(0, 1)),
        ),
        Stack(
          children: <Widget>[
            GestureDetector(
              onTap: () {
                if (widget.callback != null) {
                  widget.callback(model);
                } else {
                  Navigator.of(context).pop(model);
                }
              },
              child: Container(
                height: itemHeight.toDouble(),
                width: MediaQuery.of(context).size.width,
                color: Theme.of(context).backgroundColor,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  '${Get.locale.languageCode != MessageKeys.zh ? model.countryNameEn : model.countryName}  +${model.phoneCode}',
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              ),
            ),
            const Positioned(
              left: 16,
              right: 0,
              bottom: 0,
              child: Divider(),
            )
          ],
        )
      ],
    );
  }

  @protected
  Widget buildSusWidget(String susTag) {
    susTag = susTag == '' ? '最热地区'.tr : susTag;
    susTag = susTag == "#" ? "最热地区".tr : susTag;
    return Container(
      alignment: Alignment.bottomLeft,
      height: suspensionHeight.toDouble(),
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.only(left: 15, bottom: 8),
      child: Text(susTag,
          style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 13)),
    );
  }

  @override
  void initState() {
    loadInitData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle1 =
        Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 10);
    final child = AzListView(
      data: _data,
      itemBuilder: (context, model) => buildPickItem(model),
      suspensionWidget: buildSusWidget(_suspensionTag),
      itemHeight: itemHeight,
      suspensionHeight: suspensionHeight,
      onSusTagChanged: (tag) => setState(() => _suspensionTag = tag),
      indexBarBuilder: (context, tags, onTouch) {
        if (kIsWeb) return const SizedBox();
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IndexBar(
              touchDownColor:
                  Theme.of(context).backgroundColor.withOpacity(0.5),
              data: tags,
              itemHeight: 18,
              textStyle: textStyle1,
              touchDownTextStyle: textStyle1,
              onTouch: (details) {
                onTouch(details);
              },
            ),
          ),
        );
      },
    );
    return OrientationBuilder(builder: (context, _) {
      if (OrientationUtil.portrait) {
        return Scaffold(
            appBar: AppBar(
              title: Text(
                '选择国家和地区'.tr,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              leading: const CustomBackButton(),
              centerTitle: true,
              elevation: 0,
            ),
            body: child);
      } else {
        return child;
      }
    });
  }
}
