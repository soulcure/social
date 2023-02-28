import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:im/core/http_middleware/http.dart';
import 'package:im/core/widgets/loading.dart';
import 'package:im/db/db.dart';
import 'package:im/icon_font.dart';
import 'package:im/loggers.dart';
import 'package:im/themes/const.dart';

///上报异常信息到服务器
void uploadError(String action, String error) {
  Http.request(
    "/api/error/put",
    data: {
      "action": action,
      "t": error,
    },
  );
}

///启动时数据库异常-提示弹窗
class DbErrorDialog extends StatelessWidget {
  const DbErrorDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyText2.color;
    final bgColor = theme.scaffoldBackgroundColor;
    final cancelBgColor = theme.backgroundColor;
    final confirmBgColor = theme.primaryColor;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            width: 280,
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: bgColor,
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                      child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        sizeHeight20,
                        Text(
                          "抱歉，数据读取异常，尝试清理缓存修复！".tr,
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  )),
                  Container(
                    height: 40,
                    margin: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Get.back();
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(6)),
                                color: cancelBgColor,
                              ),
                              child: Center(
                                child: Text(
                                  '取消'.tr,
                                  style:
                                      TextStyle(color: textColor, fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              logger.info("数据库出现异常后，清理缓存");
                              Loading.show(context, label: "正在清理…".tr);
                              try {
                                await Db.cleanUserChatData();
                              } catch (e) {
                                debugPrint('getChat dbError: $e');
                              }
                              Loading.showDelayTip(context, "清理完成".tr,
                                  widget: const Icon(
                                    IconFont.buffToastRight,
                                    color: Colors.white,
                                    size: 36,
                                  ));
                              Get.back();
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(6)),
                                color: confirmBgColor,
                              ),
                              child: Center(
                                child: Text(
                                  '清理'.tr,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
