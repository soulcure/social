import 'package:flutter/material.dart';
import 'package:im/global.dart';
import 'package:im/pages/home/model/chat_index_model.dart';
import 'package:im/pages/home/model/chat_target_model.dart';
import 'package:get/get.dart';

class CommunityUtil {
  static int versionCompare(String version1, String version2) {
    if (version1 == version2) {
      return 0;
    }

    final list1 = version1.split(".");
    final list2 = version2.split(".");

    final int count1 = list1.length;
    final int count2 = list2.length;
    final int count = count1 > count2 ? count2 : count1;

    for (int i = 0; i < count; ++i) {
      final int num1 = int.tryParse(list1[i]);
      final int num2 = int.tryParse(list2[i]);
      if (num1 == null || num2 == null) {
        return -2;
      }
      if (num1 == num2) {
        continue;
      }
      return num1 > num2 ? 1 : -1;
    }

    return count1 > count2 ? 1 : -1;
  }

  static bool isAppVersionSuitable() {
    final lowestAppVersion = getVirtualParameter('minVer');
    if (lowestAppVersion.isEmpty) {
      return true;
    }

    final curAppVersion =
        '${Global.packageInfo.version}.${Global.packageInfo.buildNumber}';
    return versionCompare(curAppVersion, lowestAppVersion) >= 0;
  }

  static Future<bool> checkAppVersionSuitable(BuildContext context) async {
    if (isAppVersionSuitable()) return true;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("提示".tr),
          content: Text("当前Fanbook版本无法体验该功能，请升级Fanbook~".tr),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("确定".tr),
            ),
          ],
        );
      },
    );
    return false;
  }

  static String getVirtualParameter(String key, {String defaultValue = ''}) {
    final String content =
        (ChatTargetsModel.instance?.selectedChatTarget as GuildTarget)
                .virtualParameters ??
            '';
    if (content.isNotEmpty) {
      try {
        final parameters = content.trim().split('&');
        for (int i = 0; i < parameters.length; i++) {
          if (parameters[i].startsWith('$key=')) {
            return parameters[i].substring(key.length + 1);
          }
        }
      } catch (e) {
        print("decode community parameters error:$content");
      }
    }
    return defaultValue;
  }
}
