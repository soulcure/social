///文档操作
enum OptionMenuType {
  delete, //删除记录和文档
  deleteRecord, //仅删除记录
  rename, //重命名
  collectAdd, //收藏
  collectRemove, //取消收藏
  newCopy, //生成副本
}

///文档http 协议请求结果状态定义
enum LoadingStatus {
  loading, //请求中
  complete, //请求完成
  noData, //暂无数据
  error, //请求发生错误
}

///文档tab状态栏定义 view:最近查看,my:我的文档,collect:我的收藏
enum EntryType {
  view, //最近查看
  my, //我的文档
  collect, //我的收藏
}

extension EntryTypeExtension on EntryType {
  static EntryType fromString(String value) {
    int index;
    switch (value) {
      case 'view':
        index = 0;
        break;
      case 'my':
        index = 1;
        break;
      case 'collect':
        index = 2;
        break;
      default:
        index = 0;
        break;
    }
    return EntryType.values[index];
  }

  static String name(EntryType value) {
    String name;
    switch (value) {
      case EntryType.view:
        name = 'view';
        break;
      case EntryType.my:
        name = 'my';
        break;
      case EntryType.collect:
        name = 'collect';
        break;
      default:
        name = 'view';
        break;
    }
    return name;
  }

  static List<String> allEntryTypeName() {
    return [name(EntryType.view), name(EntryType.my), name(EntryType.collect)];
  }
}

///文档类型定义
enum DocType {
  doc, //在线文档，默认值
  sheet, //在线表格
  form, //在线收集表
  slide, //在线幻灯片
  mind, //在线思维导图
  flowchart, //在线流程图
}

extension DocTypeExtension on DocType {
  static DocType fromString(String value) {
    int index;
    switch (value) {
      case 'doc':
        index = 0;
        break;
      case 'sheet':
        index = 1;
        break;
      case 'form':
        index = 2;
        break;
      case 'slide':
        index = 3;
        break;
      case 'mind':
        index = 4;
        break;
      case 'flowchart':
        index = 5;
        break;
      default:
        index = 0;
        break;
    }
    return DocType.values[index];
  }

  static String name(DocType value) {
    String name;
    switch (value) {
      case DocType.doc:
        name = 'doc';
        break;
      case DocType.sheet:
        name = 'sheet';
        break;
      case DocType.form:
        name = 'form';
        break;
      case DocType.slide:
        name = 'slide';
        break;
      case DocType.mind:
        name = 'mind';
        break;
      case DocType.flowchart:
        name = 'flowchart';
        break;
      default:
        name = 'doc';
        break;
    }
    return name;
  }

  static String nameDesc(DocType value) {
    String name;
    switch (value) {
      case DocType.doc:
        name = '在线文档';
        break;
      case DocType.sheet:
        name = '在线表格';
        break;
      case DocType.form:
        name = '在线收集表';
        break;
      case DocType.slide:
        name = '在线幻灯片';
        break;
      case DocType.mind:
        name = '在线思维导图';
        break;
      case DocType.flowchart:
        name = '在线流程图';
        break;
      default:
        name = 'doc';
        break;
    }
    return name;
  }
}

///文档机器人推送 提及你 或 邀请你
enum SendType {
  //XXX@了你，或提及了你
  at,
  //XXX邀请了你
  invite,
}

extension SendTypeExtension on SendType {
  static SendType fromInt(int value) {
    int index = value - 1;
    if (index < 0) {
      index = 0;
    } else if (index > SendType.values.length - 1) {
      index = SendType.values.length - 1;
    }

    return SendType.values[index];
  }

  static int toInt(SendType type) {
    return type.index + 1;
  }
}

///文档的权限，阅读或编辑
enum OptionType {
  //可阅读
  view,
  //可编辑
  edit,
}

extension OptionTypeExtension on OptionType {
  static OptionType fromInt(int value) {
    return OptionType.values[value];
  }
}

///删除文档定义,//0删除最近查看记录 1是删除文件
enum DelType {
  delRecord, //0删除最近查看记录
  delFile, // 1删除文件
}
