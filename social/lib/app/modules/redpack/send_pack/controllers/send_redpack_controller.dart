import 'package:fb_ali_pay/fb_ali_pay.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:im/api/redpack_api.dart';
import 'package:im/app/modules/redpack/send_pack/data/send_redpack_resp.dart';
import 'package:im/app/modules/redpack/send_pack/views/send_redpack_page.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/services/server_side_configuration.dart';
import 'package:im/utils/content_checker.dart';
import 'package:oktoast/oktoast.dart';

enum RedPackEntrance {
  single_redPack, //单人普通红包
  group_redPack, //群普通红包
}

enum RedPackType {
  random_redPack, //群拼手气红包
  normal_redPack, //群普通红包
}

class SendRedPackController extends GetxController {
  String hintText = "恭喜发财，万事如意".tr;
  String redPackGreetings; //红包祝福语

  RedPackType redPackType = RedPackType.random_redPack;

  ///单个金额 或 总金额
  double redAmount = 0;

  ///红包总个数
  int total = 0;

  double singleMaxMoney; // 发送单个红包最大金额
  int maxNum; // 拼手气红包最多分成这么多份

  String errorMsg;
  bool hasSpecialError; //独处理输入0.00的例子，UI要求可以输入
  bool checkError; //独处理输入0.00的例子，UI要求可以输入

  RedPackParams redPackParams;

  final TextEditingController moneyController = TextEditingController();

  final TextEditingController countController = TextEditingController();

  final FocusNode moneyFocusNode = FocusNode();
  final FocusNode countFocusNode = FocusNode();
  final FocusNode greetingsFocusNode = FocusNode();

  void clear() {
    redAmount = 0;
    total = 0;
    errorMsg = null;
    moneyController.clear();
    countController.clear();
  }

  void hideKeyBoard() {
    FocusManager.instance.primaryFocus.unfocus();
  }

  ///红包入口，私信 or 频道,部落群聊
  RedPackEntrance get redPackEntrance => redPackParams.isSingleRedPack
      ? RedPackEntrance.single_redPack
      : RedPackEntrance.group_redPack;

  @override
  void onInit() {
    super.onInit();
    redPackParams = Get.arguments;
    singleMaxMoney = ServerSideConfiguration.to.singleMaxMoney ?? 20000;
    maxNum = ServerSideConfiguration.to.maxNum ?? 2000;
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
    clear();
  }

  String getErrorInfo() {
    return errorMsg;
  }

  bool isRandomGroupRedPack() {
    return redPackEntrance == RedPackEntrance.group_redPack &&
        redPackType == RedPackType.random_redPack;
  }

  String getRedPackGreetings() {
    if (redPackGreetings.hasValue) return redPackGreetings;
    return hintText;
  }

  ///设置单个红包金额，或总金额
  void setRedPackAmount(double amount) {
    checkError = false;
    if (amount == null) {
      redAmount = 0;
    } else {
      redAmount = amount;
    }

    checkSendStatus();
    update();
  }

  ///设置红包总个数
  void setRedPackTotal(int sum) {
    checkError = false;
    if (sum == null) {
      total = 0;
    } else {
      total = sum;
    }

    checkSendStatus();
    update();
  }

  double _getTotalAmount() {
    double price;
    if (redPackEntrance == RedPackEntrance.group_redPack &&
        redPackType == RedPackType.normal_redPack) {
      ///群普通红包
      price = redAmount * total;
    } else {
      price = redAmount;
    }
    return price;
  }

  String getTotalAmount() {
    final double price = _getTotalAmount();
    return price.toStringAsFixed(2);
  }

  bool isGroupRedPackEntrance() {
    return redPackEntrance == RedPackEntrance.group_redPack;
  }

  String getCurrentRedPackEntrance() {
    if (redPackEntrance == RedPackEntrance.group_redPack &&
        redPackType == RedPackType.random_redPack) return "总金额".tr;
    return "单个金额".tr;
  }

  String getCurrentRedPackTypeStr() {
    if (redPackType == RedPackType.random_redPack) return "拼手气红包".tr;
    return "普通红包".tr;
  }

  String getOtherRedPackTypeStr() {
    if (redPackType == RedPackType.random_redPack) return "普通红包".tr;
    return "拼手气红包".tr;
  }

  void changePackType() {
    ///私信红包不能切换红包类型
    if (redPackEntrance == RedPackEntrance.single_redPack) return;

    if (redPackType == RedPackType.random_redPack) {
      redPackType = RedPackType.normal_redPack;
    } else {
      redPackType = RedPackType.random_redPack;
    }
    clear();
    checkSendStatus();
    update();
  }

  ///检测金额的输入是否错误
  bool checkMoneyInput() {
    if (redPackEntrance == RedPackEntrance.single_redPack) {
      if (redAmount > 200) {
        return false;
      }
      if (checkError == true && redAmount == 0) {
        return false;
      }

      return true;
    } else {
      //拼手气
      if (redPackType == RedPackType.random_redPack) {
        if (redAmount > singleMaxMoney) {
          return false;
        }
        //单个红包的金额大于200,单个红包的金额小于0.01
        if (isAmountInLegalRange()) {
          return false;
        }

        if (hasSpecialError == true) {
          return false;
        }

        if (checkError == true && redAmount == 0) {
          return false;
        }

        return true;
      } else {
        //普通红包
        if (redAmount > 200) {
          return false;
        }
        //总金额超过20000
        if (isTotalOverMax()) {
          return false;
        }

        if (checkError == true && redAmount == 0) {
          return false;
        }
        return true;
      }
    }
  }

  ///检测红包数量的输入是否错误
  bool checkCountInput() {
    if (redPackEntrance == RedPackEntrance.single_redPack) {
      return true;
    } else {
      //拼手气，群普通红包
      if (total > maxNum) {
        return false;
      }

      if (checkError == true && checkMoneyInput() && total == 0) {
        return false;
      }

      return true;
    }
  }

  //errorMsg
  //单个红包的金额不可低于0.01元
  bool checkSendStatus() {
    if (redPackEntrance == RedPackEntrance.single_redPack) {
      if (redAmount > 200) {
        errorMsg = '单个红包金额不超过200元'.tr;
        return false;
      }
      if (redAmount == 0) {
        errorMsg = null;
        return false;
      }
      errorMsg = null;
      return true;
    } else {
      //拼手气
      if (redPackType == RedPackType.random_redPack) {
        if (redAmount > singleMaxMoney) {
          errorMsg =
              "单笔支付总额不可超过%s元".trArgs([singleMaxMoney.toStringAsFixed(0)]);
          return false;
        }

        if (total > maxNum) {
          errorMsg = "红包个数不超过%s个".trArgs([maxNum.toString()]);
          return false;
        }

        if (redAmount > 0 && total > 0 && redAmount / total > 200) {
          errorMsg = '单个红包金额不超过200元'.tr;
          return false;
        }

        if (redAmount > 0 && total > 0 && redAmount / total < 0.01) {
          errorMsg = '单个红包的金额不可低于0.01元'.tr;
          return false;
        }

        if (redAmount == 0 || total == 0) {
          if (hasSpecialError == true) {
            return false;
          }

          return false;
        }

        errorMsg = null;
        return true;
      } else {
        //普通红包
        if (redAmount > 200) {
          errorMsg = '单个红包金额不超过200元'.tr;
          return false;
        }

        if (total > maxNum) {
          errorMsg = "红包个数不超过%s个".trArgs([maxNum.toString()]);
          return false;
        }

        if (redAmount > 0 && total > 0 && redAmount * total > singleMaxMoney) {
          errorMsg = "单笔支付总额不可超过%s元".trArgs([singleMaxMoney.toString()]);
          return false;
        }

        if (redAmount == 0 || total == 0) {
          if (hasSpecialError == true) {
            return false;
          }

          return false;
        }

        errorMsg = null;
        return true;
      }
    }
  }

  Future<bool> sendRedPack(BuildContext context) async {
    //1 群拼手气红吧 ,2群普通红包，3私信红包
    int type;
    if (redPackEntrance == RedPackEntrance.single_redPack) {
      type = 3;
      total = 1; //私信红包个数为1
    } else {
      if (redPackType == RedPackType.random_redPack) {
        type = 1;
      } else {
        type = 2;
      }
    }
    final guildId = redPackParams.guildId;
    final channelId = redPackParams.channelId;
    final picture = redPackParams.picture;
    final quoteL1 = redPackParams.quoteL1;
    final quoteL2 = redPackParams.quoteL2;
    final money = redAmount;
    final num = total;
    final words = getRedPackGreetings();

    Loading.show(context);

    final checkPassed = await CheckUtil.startCheck(
      TextCheckItem(words, TextChannelType.GROUP_MESSAGE),
      toastError: false,
    );

    if (checkPassed == null) {
      showToast('系统繁忙，请稍后重试'.tr);
      Loading.hide();
      return false;
    }
    if (!checkPassed) {
      showToast('发送失败，备注涉及不适宜内容'.tr);
      Loading.hide();
      return false;
    }

    final SendRedPackResp resp = await RedPackAPI.sendRedPack(
        guildId, channelId, money, num, type, words, picture, quoteL1, quoteL2);

    Loading.hide();

    if (resp != null) {
      return FbAliPay.aliPaySendRedPacket(resp.payRedBag);
    }
    return false;
  }

  void sendError() {
    checkError = true;
    if (redAmount == 0) {
      errorMsg = '未填写「总金额」'.tr;
      update();
      return;
    }
    if (redPackEntrance != RedPackEntrance.single_redPack && total == 0) {
      errorMsg = '未填写「红包个数」'.tr;
      update();
      return;
    }
  }

  ///获取红包个数最大输入值
  int countMaxInput() {
    ///群拼手气红包 普通红包 最大个数2000四位数，最大数为99999
    return getCountMaxInput(maxNum);
  }

  ///获取红包金额最大输入值
  double moneyMaxInput() {
    // double max;
    // if (redPackEntrance == RedPackEntrance.group_redPack &&
    //     redPackType == RedPackType.random_redPack) {
    //   ///群拼手气红包 20000*10
    //   max = getMaxInput(singleMaxMoney);
    // } else {
    //   ///普通红包 200*10
    //   max = getMaxInput(200);
    // }
    // return max;

    ///所有红包红包限度规则由20000的五位数，改为限制六位数
    return getMoneyMaxInput(singleMaxMoney);
  }

  ///单独处理输入0.00的例子，之前是直接不让输入，线上是要能输入并报错
  void checkSpecialError(String text) {
    if (text == '0.00') {
      hasSpecialError = true;
      errorMsg = '单个红包的金额不可低于0.01元'.tr;
    } else {
      hasSpecialError = false;
      errorMsg = null;
    }
  }

  ///超过红包最大金额200
  bool isAmountInLegalRange() {
    if (redAmount > 0 &&
        total > 0 &&
        checkCountInput() &&
        (redAmount / total > 200 || redAmount / total < 0.01)) {
      return true;
    }
    return false;
  }

  ///总金额超过20000
  bool isTotalOverMax() {
    if (redAmount > 0 && total > 0 && redAmount * total > singleMaxMoney) {
      return true;
    }
    return false;
  }

  ///如果限制最大六位数，则是999999.99的最大输入
  double getMoneyMaxInput(double value) {
    double res = 10;
    int index = 1; //允许多输入一位
    while (value / 10 > 1) {
      index++;
      value = value / 10;
    }

    while (index > 0) {
      index--;
      res = res * 10;
    }

    return res - 0.01;
  }

  ///如果限制最大六位数，则是999999的最大输入
  int getCountMaxInput(int value) {
    int res = 10;
    int index = 1; //允许多输入一位
    while (value ~/ 10 > 1) {
      index++;
      value = value ~/ 10;
    }

    while (index > 0) {
      index--;
      res = res * 10;
    }

    return res - 1;
  }
}
