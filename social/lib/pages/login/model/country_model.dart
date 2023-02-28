import 'dart:convert';

import 'package:azlistview/azlistview.dart';
import 'package:get/get.dart';
import 'package:im/locale/message_keys.dart';
import 'package:lpinyin/lpinyin.dart';

class CountryModel with ISuspensionBean {
  String countryName;
  String countryNameEn;
  String phoneCode;
  String countryCode;
  String key;

  CountryModel({
    this.countryName,
    this.countryNameEn,
    this.phoneCode,
    this.countryCode,
    this.key,
  });

  CountryModel.fromMap(Map<String, dynamic> map) {
    countryName = map['countryName'];
    countryNameEn = map['countryName_En'];
    phoneCode = map['phoneCode'];
    countryCode = map['countryCode'];
    key = map['key'];
  }

  Map toJson() => {
        'countryName': countryName,
        'countryName_En': countryNameEn,
        'phoneCode': phoneCode,
        'countryCode': countryCode,
        'key': key,
      };

  @override
  String toString() {
    final value = json.encode(toJson());
    return value;
  }

  @override
  String getSuspensionTag() {
    if (key == "#") return key;
    if (Get.locale.languageCode != MessageKeys.zh) {
      return PinyinHelper.getFirstWordPinyin(countryNameEn)
          .toUpperCase()
          .substring(0, 1);
    }
    return PinyinHelper.getFirstWordPinyin(countryName)
        .toUpperCase()
        .substring(0, 1);
  }

  static CountryModel defaultModel = CountryModel(
    countryName: '中国'.tr,
    countryNameEn: 'China',
    phoneCode: '86',
    countryCode: 'CN',
    key: '*',
  );
}
