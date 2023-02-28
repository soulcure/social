import 'dart:convert';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/circle/content/circle_post_image_item.dart';

import 'circle_post_data_type.dart';

@HiveType(typeId: 13)
class CirclePostInfoDataModel {
  @HiveField(0)
  String topicId;
  String topicName;
  @HiveField(1)
  String guildId;
  @HiveField(2)
  String channelId;
  @HiveField(3)
  String postId;
  String createdAt;
  @HiveField(4)
  String content;
  @HiveField(5)
  String title;
  @HiveField(6)
  String postType;
  @HiveField(7)
  String contentV2;
  String guildName;
  String updatedAt;
  @HiveField(8)
  String tcDocContent;

  //瀑布流item内容区域高度
  double itemAspectRatio;

  //contentV2 中图片或视频
  List mediaList;

  //腾讯文档
  DocItem docItem;

  //文档ID: 对应圈子详情接口返回的file_id
  String fileId;

  //contentV2 中第一个图片或视频
  Map<String, dynamic> get firstMedia {
    Map<String, dynamic> firstMedia = {};
    if (mediaList?.isNotEmpty ?? false) {
      firstMedia = mediaList.first;
    }
    return firstMedia;
  }

  String get firstMediaFileType {
    if (firstMedia.isEmpty) {
      return '';
    }
    return firstMedia['_type'] ?? '';
  }

  static Map<String, dynamic> staggeredFirstMedia(
      String contentV2, String postType) {
    Map<String, dynamic> mediaMap = {};
    if (contentV2.isEmpty) {
      return mediaMap;
    }

    try {
      final List contentList = json.decode(contentV2);
      for (final data in contentList) {
        if (data is Map) {
          final content = data['insert'];
          if (content is Map) {
            final type = content['_type'] ?? '';
            if (type == 'image' || type == 'video') {
              mediaMap = content;
              break;
            }
          }
        }
      }
    } catch (_) {}

    return mediaMap;
  }

  static List<String> getAtList(String contentV2, String content) {
    final String contentStr = contentV2.isNotEmpty ? contentV2 : content;

    final List<String> atList = [];
    if (contentStr.isEmpty) {
      return atList;
    }

    try {
      final List contentList = json.decode(contentStr);
      for (final data in contentList) {
        if (data is Map) {
          final attributes = data['attributes'];
          if (attributes is Map) {
            final String at = attributes['at'];
            final mentions = attributes['mentions'];
            if (at != null && at.length > 6) {
              final val = at.substring(4, at.length - 1);
              if (!atList.contains(val)) atList.add(val);
            } else if (mentions is List) {
              for (final id in mentions) {
                if (!atList.contains(id)) atList.add(id);
              }
            }
          }
        }
      }
    } catch (_) {}

    return atList;
  }

  static String getSendContent(
      String contentV2, String content, List<CirclePostImageItem> assets) {
    String contentStr = contentV2.isNotEmpty ? contentV2 : content;

    if (contentStr.isEmpty) {
      return contentStr;
    }

    try {
      List contentList = json.decode(contentStr);
      contentList = contentList.where((e) {
        if (e is Map) {
          if (e.keys.contains('mentions')) return false;
          if (e.keys.contains('save_album')) return false;
          final content = e['insert'];
          if (content is Map) {
            final type = content['_type'] ?? '';
            if (type == 'image' || type == 'video') {
              return false;
            }
          }
        }
        return true;
      }).toList();

      for (final item in assets) {
        contentList.add({"insert": item.toJson()});
      }

      contentList.add({"insert": "\n"});

      contentStr = json.encode(contentList);
    } catch (_) {}

    return contentStr;
  }

  static List getMediaList(String contentV2, String content, String postType) {
    final String contentStr = contentV2.isNotEmpty ? contentV2 : content;

    final List medias = [];
    if (contentStr.isEmpty) {
      return medias;
    }

    try {
      final List contentList = json.decode(contentStr);
      for (final data in contentList) {
        if (data is Map) {
          final content = data['insert'];
          if (content is Map) {
            final type = content['_type'] ?? '';
            if (type == 'image' || type == 'video') {
              medias.add(content);
            }
          }
        }
      }
    } catch (_) {}

    return medias;
  }

  static double staggeredItemAspectRatio(
      String contentV2, String content, String postType) {
    final String contentStr = contentV2.isNotEmpty ? contentV2 : content;

    if (contentStr.isEmpty) {
      return 1.33;
    }

    double aspectRatio = 1.33;
    final Map<String, dynamic> firstMediaMap =
        CirclePostInfoDataModel.staggeredFirstMedia(contentStr, postType);
    if (firstMediaMap.isNotEmpty) {
      final width = firstMediaMap['width'];
      final height = firstMediaMap['height'];
      if (width != 0 && height != 0) {
        //图片宽高比例最宽4:3，最高3:4
        aspectRatio = min(1.33, max(0.75, width / height));
      }
    }

    return aspectRatio;
  }

  static DocItem getDocItem(String tcDocContent) {
    if (tcDocContent.hasValue)
      return DocItem.fromMap(json.decode(tcDocContent));
    else
      return null;
  }

  CirclePostInfoDataModel({
    this.topicId = '',
    this.topicName = '',
    this.guildId = '',
    this.channelId = '',
    this.postId = '',
    this.title = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.content = '',
    this.postType = '',
    this.contentV2 = '',
    this.guildName = '',
    this.tcDocContent = '',
    this.fileId,
  })  : mediaList =
            CirclePostInfoDataModel.getMediaList(contentV2, content, postType),
        itemAspectRatio = CirclePostInfoDataModel.staggeredItemAspectRatio(
            contentV2, content, postType),
        docItem = CirclePostInfoDataModel.getDocItem(tcDocContent);

  factory CirclePostInfoDataModel.fromJson(Map<String, dynamic> json) =>
      CirclePostInfoDataModel(
        topicId: (json['topic_id'] ?? '').toString(),
        topicName: (json['topic_name'] ?? '').toString(),
        guildId: (json['guild_id'] ?? '').toString(),
        channelId: (json['channel_id'] ?? '').toString(),
        postId: (json['post_id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        createdAt: (json['created_at'] ?? '0').toString(),
        content: (json['content'] ?? '').toString(),
        postType: (json['post_type'] ?? '').toString(),
        contentV2: (json['content_v2'] ?? '').toString(),
        guildName: (json['guild_name'] ?? '').toString(),
        updatedAt: (json['updated_at'] ?? '').toString(),
        tcDocContent: (json['tc_doc_content'] ?? '').toString(),
        fileId: (json['file_id'] ?? '').toString(),
      );

  bool get postTypeAvailable => [
        CirclePostDataType.article,
        CirclePostDataType.image,
        CirclePostDataType.video,
        ''
      ].contains(postType);

  String postContent() {
    if (postType.isEmpty) {
      return content;
    } else if (postType == CirclePostDataType.article ||
        postType == CirclePostDataType.image ||
        postType == CirclePostDataType.video) {
      return contentV2;
    } else {
      return null;
    }
  }

  ///文章类型直接返回contentV2， 图片圈子和视频圈子则返回正文（文字）部分
  String postContent2() {
    if (postType.isEmpty) {
      return content;
    } else if (postType == CirclePostDataType.article) {
      return contentV2;
    } else if (postType == CirclePostDataType.image ||
        postType == CirclePostDataType.video) {
      final List contentList = json.decode(contentV2);

      final List contents = [];
      for (final Map map in contentList) {
        final dynamic insertV = map['insert'] ?? '';
        if (insertV is Map) {
          final Map insertMap = insertV;
          final type = insertMap['_type'] ?? '';
          if (type == 'image' || type == 'video') {
            break;
          }
        }
        contents.add(map);
      }
      if (contents.isEmpty || contents.last['insert'] != '\n') {
        contents.add({'insert': '\n'});
      }
      final contentStr = json.encode(contents);
      return contentStr;
    } else {
      return null; //这里如果返回空字符串，存在兼容性问题
    }
  }

  Map<String, dynamic> toJson() => {
        'topic_id': topicId,
        'topic_name': topicName,
        'guild_id': guildId,
        'channel_id': channelId,
        'post_id': postId,
        'created_at': createdAt,
        'content': content,
        'post_type': postType,
        'content_v2': contentV2,
        'title': title,
        'tc_doc_content': tcDocContent,
      };
}

class CirclePostInfoDataModelAdapter
    extends TypeAdapter<CirclePostInfoDataModel> {
  @override
  final int typeId = 13;

  @override
  CirclePostInfoDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CirclePostInfoDataModel(
      topicId: fields[0] as String,
      guildId: fields[1] as String,
      channelId: fields[2] as String,
      postId: fields[3] as String,
      content: fields[4] as String,
      title: fields[5] as String,
      postType: fields[6] as String,
      contentV2: fields[7] as String,
      tcDocContent: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CirclePostInfoDataModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.topicId)
      ..writeByte(1)
      ..write(obj.guildId)
      ..writeByte(2)
      ..write(obj.channelId)
      ..writeByte(3)
      ..write(obj.postId)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.title)
      ..writeByte(6)
      ..write(obj.postType)
      ..writeByte(7)
      ..write(obj.contentV2)
      ..writeByte(8)
      ..write(obj.tcDocContent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CirclePostInfoDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
