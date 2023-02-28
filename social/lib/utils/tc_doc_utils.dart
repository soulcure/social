import 'package:get/get.dart';
import 'package:im/app/routes/app_pages.dart' as get_pages;

class TcDocUtils {
  /// 腾讯文档地址正则
  static RegExp tcDocUrlReg = RegExp(
      r'https://docs.qq.com/(doc|sheet|mind|slide|page|flowchart|form)/\w+');

  /// 腾讯文档Fb链接正则fileId之前的host
  static RegExp docUrlReg = RegExp(
      r'https://(\w+.)?fanbook.mobi/(doc|sheet|mind|slide|page|flowchart|form)/');

  /// 腾讯文档Fb链接正则全地址
  static RegExp docUrlRegFull = RegExp(
      r'https://(\w+.)?fanbook.mobi/(doc|sheet|mind|slide|page|flowchart|form)/[a-zA-Z0-9&$%./-~-]*');

  static Future toAddGroupPage(String guildId, String fileId) {
    return Get.toNamed(get_pages.Routes.TC_DOC_ADD_GROUP_PAGE,
        arguments: {'guildId': guildId, 'fileId': fileId});
  }

  static Future toGroupsPage(String guildId, String fileId) async {
    return Get.toNamed(
      get_pages.Routes.TC_DOC_GROUPS_PAGE,
      arguments: {'guildId': guildId, 'fileId': fileId},
    );
  }

  // fromSelectPage
  // true 返回值为DocInfoItem，false 返回值为List<Tuple2<TcDocPageReturnType, DocInfoItem>>
  static Future toDocPage(String url, {bool fromSelectPage = false}) async {
    final res = await Get.toNamed(get_pages.Routes.TC_DOC_PAGE, arguments: {
      'fromSelectPage': fromSelectPage
    }, parameters: {
      'appId': url,
    });
    return res;
  }
}
