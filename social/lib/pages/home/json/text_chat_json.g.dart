// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_chat_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageEntity _$ImageEntityFromJson(Map<String, dynamic> json) {
  return ImageEntity(
    url: json['url'] as String,
    width: json['width'] as int,
    height: json['height'] as int,
    fileType: json['fileType'] as String,
    localFilePath: json['localFilePath'] as String,
    localIdentify: json['localIdentify'] as String,
    thumb: json['thumb'] as bool,
  );
}

Map<String, dynamic> _$ImageEntityToJson(ImageEntity instance) =>
    <String, dynamic>{
      'type': _$MessageTypeEnumMap[instance.type],
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
      'fileType': instance.fileType,
      'localFilePath': instance.localFilePath,
      'localIdentify': instance.localIdentify,
      'thumb': instance.thumb,
    };

const _$MessageTypeEnumMap = {
  MessageType.unSupport: 'unSupport',
  MessageType.start: 'start',
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.video: 'video',
  MessageType.voice: 'voice',
  MessageType.newJoin: 'newJoin',
  MessageType.call: 'call',
  MessageType.del: 'del',
  MessageType.richText: 'richText',
  MessageType.empty: 'empty',
  MessageType.upMsg: 'upMsg',
  MessageType.recall: 'recall',
  MessageType.topicShare: 'topicShare',
  MessageType.stickerEntity: 'stickerEntity',
  MessageType.circleShareEntity: 'circleShareEntity',
  MessageType.goodsShareEntity: 'goodsShareEntity',
  MessageType.externalShareEntity: 'externalShareEntity',
  MessageType.pinned: 'pinned',
  MessageType.reaction: 'reaction',
  MessageType.task: 'task',
  MessageType.vote: 'vote',
  MessageType.file: 'file',
  MessageType.circle: 'circle',
  MessageType.friend: 'friend',
  MessageType.document: 'doc',
};

VideoEntity _$VideoEntityFromJson(Map<String, dynamic> json) {
  return VideoEntity(
    url: json['url'] as String,
    videoName: json['videoName'] as String,
    width: json['width'] as int,
    height: json['height'] as int,
    thumbUrl: json['thumbUrl'] as String,
    thumbWidth: json['thumbWidth'] as int,
    thumbHeight: json['thumbHeight'] as int,
    duration: json['duration'] as int,
    thumbName: json['thumbName'] as String,
    fileType: json['fileType'] as String,
    localPath: json['localPath'] as String,
    localThumbPath: json['localThumbPath'] as String,
    localIdentify: json['localIdentify'] as String,
  );
}

Map<String, dynamic> _$VideoEntityToJson(VideoEntity instance) =>
    <String, dynamic>{
      'type': _$MessageTypeEnumMap[instance.type],
      'url': instance.url,
      'videoName': instance.videoName,
      'width': instance.width,
      'height': instance.height,
      'localPath': instance.localPath,
      'thumbUrl': instance.thumbUrl,
      'thumbWidth': instance.thumbWidth,
      'thumbHeight': instance.thumbHeight,
      'duration': instance.duration,
      'thumbName': instance.thumbName,
      'fileType': instance.fileType,
      'localThumbPath': instance.localThumbPath,
      'localIdentify': instance.localIdentify,
    };

WelcomeEntity _$WelcomeEntityFromJson(Map<String, dynamic> json) {
  return WelcomeEntity(
    index: json['index'] as int,
  );
}

Map<String, dynamic> _$WelcomeEntityToJson(WelcomeEntity instance) =>
    <String, dynamic>{
      'type': _$MessageTypeEnumMap[instance.type],
      'index': instance.index,
    };

CallEntity _$CallEntityFromJson(Map<String, dynamic> json) {
  return CallEntity(
    duration: json['duration'] as int,
    status: json['status'] as int,
    objectId: json['objectId'] as int,
    video: json['video'] as int,
  );
}

Map<String, dynamic> _$CallEntityToJson(CallEntity instance) =>
    <String, dynamic>{
      'type': _$MessageTypeEnumMap[instance.type],
      'status': instance.status,
      'duration': instance.duration,
      'video': instance.video,
      'objectId': instance.objectId,
    };

VoiceEntity _$VoiceEntityFromJson(Map<String, dynamic> json) {
  return VoiceEntity(
    url: json['url'] as String,
    path: json['path'] as String,
    second: json['second'] as int,
    isRead: json['isRead'] as bool,
  );
}

Map<String, dynamic> _$VoiceEntityToJson(VoiceEntity instance) =>
    <String, dynamic>{
      'type': _$MessageTypeEnumMap[instance.type],
      'url': instance.url,
      'path': instance.path,
      'second': instance.second,
      'isRead': instance.isRead,
    };
