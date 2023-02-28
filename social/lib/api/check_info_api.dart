import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/api/entity/update_bean.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/services/connectivity_service.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/utils/rsa_util.dart';
import 'package:im/widgets/dialog/update_dialog.dart';
import 'package:oktoast/oktoast.dart';
import 'package:simple_rc4/simple_rc4.dart';

import 'check_api.dart';
import 'entity/audit_info_bean.dart';

const String _fanBookKey = "fan_book";

class CheckInfoApi {
  static const String updateUrl = '/api/common/setting';
  static const String checkInfoUrl = '/api/common/audit';

  ///请求更新
  static Future<UpgradeBean> postCheckUpdate(BuildContext context,
      {bool toast = true,
      bool showUpdateDialog = false,
      bool isManual = false,
      CancelToken token}) async {
    if (isRequesting) return null;
    isRequesting = true;
    try {
      final lastTime = SpService.to.getString(SP.updatePeriod);
      final now = DateTime.now();
      bool canShowDialog = true;

      UpdateBean bean;
      try {
        final data = await Http.request(updateUrl, cancelToken: token);
        bean = UpdateBean.fromMap(data);
        if (data is Map && data['tx_doc'] != null) {
          ServerSideConfiguration.to.tcDocEnvId = data['tx_doc']['env_id'];
          ServerSideConfiguration.to.tcDocEnvName = data['tx_doc']['env_name'];
          ServerSideConfiguration.to.disableExcelComment =
              data['tx_doc']['can_comment'] == false;
        }
      } catch (e) {
        listenForNetwork(context);
      }
      if (bean == null) return null;

      ///1代表升级，0代表不升级
      final result = bean?.data?.upgrade;
      remoteCheckImageAddress = bean?.data?.imageAudit;
      remoteCheckTextAddress = bean?.data?.textAudit;
      downloadUrl = result?.download;
      if (result == null) return result;
      final forceUpdate = result.isEnforce == '1';
      final needUpdate = result.isUpgrade == '1';

      if (lastTime == null) {
        await SpService.to.setString(SP.updatePeriod, now.toIso8601String());
      } else {
        final last = DateTime.parse(lastTime);
        final diffInDays = now.difference(last).inDays;
        if (diffInDays >= 1 && needUpdate) {
          await SpService.to.setString(SP.updatePeriod, now.toIso8601String());
        } else
          canShowDialog = false;
      }
      hasInitial = true;
      removeListenForNetwork();
      if (needUpdate) needToUpdate.value = needUpdate;
      final canShow = (canShowDialog || isManual) && showUpdateDialog;
      if (toast && !needUpdate) {
        showToast('已更新至最新版本'.tr);
      } else if (forceUpdate || (needUpdate && canShow)) {
        return null;
        // await showDialog(
        //     context: context,
        //     builder: (ctx) {
        //       return UpdateDialog(
        //         version: result.version,
        //         updateInfo: result.content,
        //         updateUrl: result.download,
        //         isForce: forceUpdate,
        //       );
        //     });
      }
      return result;
    } catch (e) {
      _checkError(e, updateUrl, toast);
    } finally {
      isRequesting = false;
    }
    return null;
  }

  ///审核数据获取
  static Future<AuditInfoBean> postCheckInfo(BuildContext context,
      {bool toast = false, CancelToken token}) async {
    if (apiAccessKey != null) return null;
    try {
      final data = await Http.request(checkInfoUrl, cancelToken: token);
      final bean = AuditInfoBean.fromMap(data);
      auditInfoBean = bean;
      final key = Uri.decodeFull(bean.accessKey);
      final accessKey = decodeString(key);
      if (accessKey.isNotEmpty) {
        await _saveStringWithEncrypt(SP.accessKey, accessKey);
      }
      apiAccessKey = accessKey;
      return bean;
    } catch (e) {
      _checkError(e, updateUrl, toast);
    }
    final localAccessKey = await _getStringWithEncrypt(SP.accessKey);
    apiAccessKey ??= localAccessKey;
    apiAccessKey ??= decodeString(
        'dWTZd8QD/Mxx5iaQYgxSe6zAVeGen5oSx4LSG31lY16A5Ebn3urNSFbGHWJeJxvEuSFU4VVcIQbDUm6baM23qaiPXutiYxanpqoksDerjak8plVTd9kmX1lQTbvBqCD4KfdCaD3YXyIZkFlCX8cr5Da4UqG2AvTt4OVgbs3Wjo0=');
    return null;
  }

  static void _checkError(e, String url, bool toast) {
    if (e is DioError) {
      if (toast) showToast('网络异常，请稍后重试！'.tr);
    }
  }
}

///用于处理断网进入app，再重连后的更新请求
void listenForNetwork(BuildContext context) {
  if (_hasListenForNet) return;
  _hasListenForNet = true;
  _netSubscription =
      Get.find<ConnectivityService>().onConnectivityChanged.listen((result) {
    if (hasInitial) return;
    if (result != ConnectivityResult.none)
      CheckInfoApi.postCheckUpdate(context,
          toast: false, showUpdateDialog: true);
  });
}

void removeListenForNetwork() {
  _netSubscription?.cancel();
}

Future _saveStringWithEncrypt(SP key, String value) async {
  final rc4 = RC4(_fanBookKey);
  final encryptValue = rc4.encodeString(value);
  await SpService.to.setString(key, encryptValue);
}

Future<String> _getStringWithEncrypt(SP key) async {
  final rc4 = RC4(_fanBookKey);
  final value = SpService.to.getString(key);
  if (value == null) return null;
  final decryptValue = rc4.decodeString(value);
  return decryptValue;
}

ValueNotifier<bool> needToUpdate = ValueNotifier(false);
bool isRequesting = false;
bool hasInitial = false;
bool _hasListenForNet = false;
StreamSubscription _netSubscription;
String downloadUrl;
AuditInfoBean auditInfoBean;
