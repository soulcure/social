import 'dart:ui';

import 'package:im/dlog/model/dlog_base_model.dart';
import 'package:im/global.dart';

class DLogDeviceStartModel extends DLogBaseModel {
  String brand;
  String model;
  String osVersion;
  String operator;
  String network;
  String memoryMb;
  String screenW;
  String screenH;
  String sysLang;
  Map extJson;

  DLogDeviceStartModel() {
    logType = 'dlog_app_devicestart_fb';
    operator = '00';
    network = '4';
    brand = Global.deviceInfo?.brand ?? '';
    model = Global.deviceInfo?.model ?? '';
    osVersion = Global.deviceInfo?.systemVersion ?? '';
    screenW = window.physicalSize?.width?.toString() ?? '';
    screenH = window.physicalSize?.height?.toString() ?? '';
    extJson = {};
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    final superMap = super.toJson();
    data.addAll(superMap);
    data['terml_brand'] = brand ?? '';
    data['terml_model'] = model ?? '';
    data['terml_os_version'] = osVersion ?? '';
    data['terml_operator'] = operator ?? '';
    data['terml_network'] = network ?? '';
    data['terml_memory_mb'] = memoryMb ?? '';
    data['screen_width'] = screenW ?? '';
    data['screen_hight'] = screenH ?? '';
    data['sys_lang'] = sysLang ?? '';
    data['ext_json'] = extJson ?? {};
    return data;
  }
}
