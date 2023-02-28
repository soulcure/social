import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/api/audit_api.dart';
import 'package:im/api/redpack_api.dart';
import 'package:im/app/modules/bind_payment/controllers/bind_payment_controller.dart';
import 'package:im/services/sp_service.dart';
import 'package:im/widgets/red_packet_popup.dart';

import '../loggers.dart';

class ServerSideConfiguration extends GetxService {
  static ServerSideConfiguration get to => Get.find<ServerSideConfiguration>();

  bool readHistoryPermissionEnabled = true;

  /// 钱包数据
  //  - nft 钱包地址
  String nftId;
  //  - 已有 nft 总数量
  String nftCollectTotal = "0";

  /// 我的-数字藏品 入口 是否打开, 默认关
  bool walletIsOpen = false;

  ///支付乐豆入口 是否打款, 默认关
  bool payIsOpen = false;

  /// 是否显示第三方登录入口
  //苹果登录 默认关
  RxBool appleLoginOpen = false.obs;

  //微信登录 默认关
  RxBool wechatLoginOpen = false.obs;

  /// APP后台通知部分
  bool serverEnableNotiInBg = true;
  int maxNotiCountInBg = 5;
  int currentNotiCountInBg = 0;

  ///支付宝绑定id
  String aliPayUid;

  double singleMaxMoney = 20000; // 发送单个红包最大金额
  int maxNum = 2000; // 拼手气红包最多分成这么多份
  int period = 24 * 60 * 60; // 默认的红包过期时间24小时，服务器配置，单位为秒

  /// 腾讯文档参数
  String tcDocEnvId;
  String tcDocEnvName;

  /// 临时字段，禁用excel批注，默认值为false
  bool disableExcelComment = false;

  @override
  Future<void> onInit() async {
    try {
      final config = await AuditApi.auditStatus();
      walletIsOpen = config.walletBean == 1;
      payIsOpen = config.leBean == 1;

      serverEnableNotiInBg =
          config.notificationInfo?.enableNotDisturbBgNoti ?? true;
      maxNotiCountInBg = config.notificationInfo?.total ?? 5;

      appleLoginOpen.value = config.appleLogin == 1;
      wechatLoginOpen.value = config.wechatLogin == 1;

      singleMaxMoney = config?.redPack?.singleMaxMoney?.toDouble() ?? 20000;
      maxNum = config?.redPack?.maxNum ?? 2000;
      period = config?.redPack?.period ?? 24 * 60 * 60;

      debugPrint(
          'a=${appleLoginOpen.value}  w=${wechatLoginOpen.value} l=$payIsOpen');

      readHistoryPermissionEnabled = config.readHistory ?? true;
    } catch (e) {
      logger.severe("Failed to parse server side configuration. $e");
    }
    super.onInit();
  }

  Future<bool> isBindAliPay(BuildContext context) async {
    final net = await Connectivity().checkConnectivity();
    bool result = false;

    ///用户无网络不能发起点亮红包
    if (net != ConnectivityResult.none) {
      aliPayUid ??= await RedPackAPI.checkBindAliPay();
      if (aliPayUid == null) {
        /// NOTE: 2022/1/11 记录点亮红包已出现过
        bool isFirsPopRedPacket = true;
        if (SpService.to.containsKey(SP.isFirsPopRedPacket)) {
          isFirsPopRedPacket = SpService.to.getBool(SP.isFirsPopRedPacket);
        }
        if (isFirsPopRedPacket) {
          await SpService.to.setBool(SP.isFirsPopRedPacket, false);
        }

        final bool isAgree =
            await showRedPacketPopup<bool>(context, onAgree: () async {
                  Get.back(result: true);
                }) ??
                false;

        if (isAgree) {
          /// FIXME: 2022/1/15 使用Put会导致通过绑定管理页面Get.toName跳转，再退出时不调用onClose，所以采用直接创建操作
          /// 可以将bindAliPay单独分离出一个调用
          final bindPaymentController =
              Get.put<BindPaymentController>(BindPaymentController());
          await bindPaymentController.bindAliPay();
          if (Get.isRegistered<BindPaymentController>()) {
            await Get.delete<BindPaymentController>();
          }

          aliPayUid ??= await RedPackAPI.checkBindAliPay();
          if (aliPayUid != null) {
            result = true;
          }
        }
      } else {
        result = true;
      }
    }
    return result;
  }

  /// 判断是否中国手机号码
  bool isChineseMobile(String mobile) =>
      RegExp(r"^1[0-9]{10}$").hasMatch(mobile);
}
