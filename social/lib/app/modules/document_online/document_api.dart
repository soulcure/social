import 'package:get/get.dart';
import 'package:im/app/modules/black_list/black_item.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/app/modules/document_online/entity/doc_info_item.dart';
import 'package:im/app/modules/tc_doc_add_group_page/entities/tc_doc_group.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/core/http_middleware/http.dart';

import '../../../loggers.dart';
import 'entity/create_doc_item.dart';
import 'entity/doc_list_item.dart';
import 'entity/doc_type.dart';

class DocumentApi {
  static const String DocCreate = '/api/doc/create'; //创建文档
  static const String DocCollect = '/api/doc/collect'; //收藏文档，取消收藏文档
  static const String DocDel = '/api/doc/del'; //移除最近查看/删除文档
  static const String DocShare = '/api/doc/share'; //文档分享
  static const String DocList = '/api/doc/list'; //文档列表
  static const String DocEdit = '/api/doc/edit'; //文档编辑,重命名
  static const String DocTempUrl = '/api/doc/tempUrl'; //获取临时链接  服务器跳转，暂不使用
  static const String DocDirCreate = '/api/doc/dirCreate'; //目录创建
  static const String DocDirUpdate = '/api/doc/dirUpdate'; //目录编辑
  static const String DocDirList = '/api/doc/dirList'; //目录列表
  static const String DocDirDel = '/api/doc/dirDel'; //目录删除
  static const String DocSearch = '/api/doc/search'; //文档搜索
  static const String DocCopy = '/api/doc/copy'; //生成副本，类似于创建文档
  static const String DocTypes = '/api/doc/types'; //获取文档类型  创建文档入口的个数，暂不使用
  static const String DocInfo = '/api/doc/info'; //查看文档信息
  static const String DocGroups = '/api/doc/groupList'; //查看文档信息
  static const String DocGroupBatch = '/api/doc/groupBatch'; //批量添加协作者
  static const String DocGroupUpdate = '/api/doc/groupUp'; //修改协作者权限
  static const String DocGroupDel = '/api/doc/groupDel'; //删除协作者
  static const String DocQuit = '/api/doc/quit'; //退出文档（协作者）
  static const String DocOnlineUser = '/api/doc/viewList'; //协作者列表
  static const String DocAtUser = '/api/doc/mention'; //@人
  static const String DocUser = '/api/doc/user'; //获取腾讯文档token、openId等参数
  static const String DocJoin = '/api/doc/join'; //加入文档在线用户
  static const String DocPermissionSet = '/api/doc/permissionSet'; //加入文档在线用户

  ///创建文档
  static Future<CreateDocItem> docCreate(String guildId, String type,
      {int dirId, String title}) async {
    final res = await Http.request(
      DocCreate,
      showDefaultErrorToast: true,
      data: {
        "guild_id": guildId,
        "type": type,
        if (dirId != null) 'dir_id': dirId,
        if (title.hasValue) 'title': title,
      },
    ).catchError((e) {
      logger.severe("docCreate e=$e");
      return null;
    });

    if (res is Map) {
      return CreateDocItem.fromMap(res);
    }
    return null;
  }

  ///收藏
  static Future<bool> docCollectAdd(String fileId) async {
    return _docCollect(fileId, "collect");
  }

  ///取消收藏
  static Future<bool> docCollectRemove(String fileId) async {
    return _docCollect(fileId, "cancel");
  }

  ///收藏/取消收藏
  static Future<bool> _docCollect(String fileId, String action) async {
    final res = await Http.request(
      DocCollect,
      showDefaultErrorToast: true,
      data: {
        "file_id": fileId,
        "action": action,
      },
    ).catchError((e) {
      logger.severe("docCollect e=$e");
      return null;
    });

    if (res is Map) {
      return true;
    }
    return null;
  }

  //0 1  0删除最近查看记录 1是删除文件， userId=自己才能删除
  static Future<bool> docDel(
      String guildId, String fileId, DelType withFile) async {
    final res = await Http.request(
      DocDel,
      showDefaultErrorToast: true,
      data: {
        "guild_id": guildId,
        "file_id": fileId,
        "with_file": withFile.index,
      },
    ).catchError((e) {
      logger.severe("docDel e=$e");
      return false;
    });

    if (res is Map) {
      return true;
    }
    return false;
  }

  static Future<BlackItem> docShare(String guildId) async {
    final res = await Http.request(
      DocShare,
      showDefaultErrorToast: true,
      data: {
        "guild_id": guildId,
      },
    ).catchError((e) {
      logger.severe("docShare e=$e");
      return null;
    });

    if (res is Map) {
      return BlackItem.fromMap(res);
    }
    return null;
  }

  ///文档列表
  static Future<DocListItem> docList(String guildId, String listType, int page,
      {int size = 20}) async {
    final res = await Http.request(
      DocList,
      //showDefaultErrorToast: true,
      data: {
        "guild_id": guildId,
        "list_type": listType,
        "size": size,
        "page": page,
      },
    ).catchError((e) {
      logger.severe("docList e=$e");
      return null;
    });

    if (res is Map) {
      return DocListItem.fromMap(res);
    }
    return null;
  }

  ///编辑文档，重命名
  static Future<bool> docEdit(
      String userId, String fileId, String title) async {
    final res = await Http.request(
      DocEdit,
      showDefaultErrorToast: true,
      data: {
        "user_id": userId,
        "file_id": fileId,
        "title": title,
      },
    ).catchError((e) {
      logger.severe("docEdit e=$e");
      return null;
    });

    if (res is Map) {
      return true;
    }
    return null;
  }

  static Future<bool> docTempUrl(String fileId) async {
    final res = await Http.dio.get(
      DocTempUrl,
      queryParameters: {
        'file_id': fileId,
      },
    ).catchError((e) {
      logger.severe("docTempUrl e=$e");
      return null;
    });

    if (res is Map) {
      return true;
    }
    return null;
  }

  static Future<BlackItem> docDirCreate(String guildId) async {
    final res = await Http.request(
      DocDirCreate,
      showDefaultErrorToast: true,
      data: {
        "guild_id": guildId,
      },
    ).catchError((e) {
      logger.severe("docDirCreate e=$e");
      return null;
    });

    if (res is Map) {
      return BlackItem.fromMap(res);
    }
    return null;
  }

  static Future<BlackItem> docDirUpdate(String guildId) async {
    final res = await Http.request(
      DocDirUpdate,
      showDefaultErrorToast: true,
      data: {
        "guild_id": guildId,
      },
    ).catchError((e) {
      logger.severe("docDirUpdate e=$e");
      return null;
    });

    if (res is Map) {
      return BlackItem.fromMap(res);
    }
    return null;
  }

  static Future<BlackItem> docDirList(String guildId) async {
    final res = await Http.request(
      DocDirList,
      showDefaultErrorToast: true,
      data: {
        "guild_id": guildId,
      },
    ).catchError((e) {
      logger.severe("docDirList e=$e");
      return null;
    });

    if (res is Map) {
      return BlackItem.fromMap(res);
    }
    return null;
  }

  static Future<BlackItem> docDirDel(String guildId) async {
    final res = await Http.request(
      DocDirDel,
      showDefaultErrorToast: true,
      data: {
        "guild_id": guildId,
      },
    ).catchError((e) {
      logger.severe("DocDirDel e=$e");
      return null;
    });

    if (res is Map) {
      return BlackItem.fromMap(res);
    }
    return null;
  }

  ///文档列表
  static Future<DocListItem> docSearch(
      String guildId, String listType, String keyword, int page,
      {int size = 20}) async {
    final res = await Http.request(
      DocList,
      //showDefaultErrorToast: true,
      data: {
        "guild_id": guildId,
        "list_type": listType,
        "size": size,
        "page": page,
        "title": keyword,
      },
    ).catchError((e) {
      logger.severe("docList search e=$e");
      return null;
    });

    if (res is Map) {
      return DocListItem.fromMap(res);
    }
    return null;
  }

  ///生成副本,文档标题 | 默认是 '副本-xxx'
  static Future<CreateDocItem> docCopy(String fileId, {String title}) async {
    final res = await Http.request(
      DocCopy,
      showDefaultErrorToast: true,
      data: {
        "file_id": fileId,
        if (title.hasValue) 'title': title,
      },
    ).catchError((e) {
      logger.severe("docCopy e=$e");
      return null;
    });

    if (res is Map) {
      return CreateDocItem.fromMap(res);
    }
    return null;
  }

  ///获取文档类型
  static Future<DocTypeItem> docTypes(String fileId, {String title}) async {
    final res = await Http.request(
      DocTypes,
      showDefaultErrorToast: true,
      data: {
        "file_id": fileId,
        if (title.hasValue) 'title': title,
      },
    ).catchError((e) {
      logger.severe("docTypes e=$e");
      return null;
    });

    if (res is Map) {
      return DocTypeItem.fromMap(res);
    }
    return null;
  }

  ///查看文档信息  位运算得到额外数据|1:权限判断,2:收藏时间,4:正在查看列表,  位运算
  static Future<DocInfoItem> docInfo(
    String fileId, {
    bool checkPermission = false,
    bool collectTime = false,
    bool viewList = false,
  }) async {
    int sum = 0;
    if (checkPermission) {
      sum = sum + 1 << 0;
    }
    if (collectTime) {
      sum = sum + 1 << 1;
    }
    if (viewList) {
      sum = sum + 1 << 2;
    }
    final res = await Http.request(
      DocInfo,
      isOriginDataReturn: true,
      //showDefaultErrorToast: true,
      data: {
        "file_id": fileId,
        if (sum > 0) "extra_data": sum,
      },
    ).catchError((e) {
      logger.severe("docInfo e=$e");
      return null;
    });

    if (res is Map) {
      if (res['code'] == 1000) {
        res.putIfAbsent('file_id', () => fileId);
        return DocInfoItem.fromMap(res['data']);
      } else if (res['code'] == 6002) {
        //文件不存在
        final DocInfoItem item = DocInfoItem();
        item.title = "文档已被删除".tr;
        return item;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>> docGroups(
    String fileId, {
    int page = 1,
    int pageSize = 10,
    bool showDefaultErrorToast = true,
  }) async {
    final res = await Http.request(
      DocGroups,
      showDefaultErrorToast: showDefaultErrorToast,
      data: {
        "file_id": fileId,
        "page": page,
        "size": pageSize,
      },
    );
    return Map<String, dynamic>.from(res);
  }

  static Future<void> docBatch(String fileId, List<TcDocGroup> groups) async {
    final data = groups.map((e) => e.toBatchJson()).toList();
    await Http.request(
      DocGroupBatch,
      showDefaultErrorToast: true,
      data: {
        "file_id": fileId,
        "data": data,
      },
    );
  }

  static Future<void> docGroupUpdate(
      String fileId, String groupId, TcDocGroupRole role) async {
    await Http.request(
      DocGroupUpdate,
      showDefaultErrorToast: true,
      data: {
        "file_id": fileId,
        "group_id": groupId,
        "role": role.toInt(),
      },
    );
  }

  static Future<void> docGroupDel(String groupId) async {
    await Http.request(
      DocGroupDel,
      showDefaultErrorToast: true,
      data: {
        "group_id": groupId,
      },
    );
  }

  static Future<Map<String, dynamic>> docOnlineUser(
    String fileId, {
    int page = 1,
    int pageSize = 10,
    bool showDefaultErrorToast = true,
  }) async {
    final res = await Http.request(
      DocOnlineUser,
      showDefaultErrorToast: showDefaultErrorToast,
      data: {
        "file_id": fileId,
        "page": page,
        "size": pageSize,
      },
    );
    return Map<String, dynamic>.from(res);
  }

  static Future<void> docQuit(String fileId, String guildId) async {
    await Http.request(
      DocQuit,
      data: {
        "file_id": fileId,
        "guild_id": guildId,
      },
    );
  }

  static Future<void> docAtUser(String fileId, String userId) async {
    await Http.request(
      DocAtUser,
      data: {
        "file_id": fileId,
        "mention_user": userId,
      },
    );
  }

  static Future docUser() async {
    return Http.request(
      DocUser,
    );
  }

  static Future docJoin(String fileId) async {
    return Http.request(DocJoin, data: {
      'file_id': fileId,
    });
  }

  static Future docPermissionSet(String fileId,
      {bool canCopy, bool canReadeComment}) async {
    final Map<String, dynamic> data = {
      'file_id': fileId,
    };

    data.addIf(canCopy != null, 'can_copy', canCopy == true ? 1 : 0);
    data.addIf(canReadeComment != null, 'can_reader_comment',
        canReadeComment == true ? 1 : 0);
    return Http.request(DocPermissionSet, data: data);
  }
}
