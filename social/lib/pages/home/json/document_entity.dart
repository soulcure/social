import 'package:get/get.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/document_online/document_enum_defined.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/home/json/text_chat_json.dart';

// {
// "type": "doc",
// "file_id": "300000000$ONDNbxfewlIt",
// "url": "https:\/\/docs.qq.com\/doc\/DT05ETmJ4ZmV3bEl0",
// "guild_id": 345178383224668160,
// "document_title": "\u65e0\u6807\u9898\u6587\u6863",
// "send_user_id": "207020327354499072",
// "send_type": 2,
// "document_type": "doc"
// }

class DocumentEntity extends MessageContentEntity {
  final String fileId;
  final String url;
  final String guildId;
  String documentTitle;
  final String sendUserId;
  final SendType sendType;
  final DocType documentType;
  String desc;

  DocumentEntity({
    this.fileId,
    this.url,
    this.guildId,
    this.documentTitle,
    this.sendUserId,
    this.sendType,
    this.documentType,
  }) : super(MessageType.document);

  Map<String, dynamic> toMap() {
    return {
      'type': typeInString,
      'file_id': fileId,
      'url': url,
      'guild_id': guildId,
      'document_title': documentTitle,
      'send_user_id': sendUserId,
      'send_type': SendTypeExtension.toInt(sendType),
      'document_type': DocTypeExtension.name(documentType),
    };
  }

  factory DocumentEntity.fromJson(Map<String, dynamic> json) {
    return DocumentEntity(
      fileId: json['file_id'],
      url: json['url'],
      guildId: json['guild_id'],
      documentTitle: json['document_title'],
      sendUserId: json['send_user_id'],
      sendType: SendTypeExtension.fromInt(json['send_type']),
      documentType: DocTypeExtension.fromString(json['document_type']),
    );
  }

  @override
  Map<String, dynamic> toJson() => toMap();

  Future<String> toNotificationString() async {
    if (desc.hasValue) {
      return desc;
    }

    final String sendName = await sendNickName();
    String info;
    if (sendType == SendType.at) {
      info = '中@你'.tr;
      return '@$sendName 在 [在线文档] $documentTitle $info';
    } else {
      info = '邀请你编辑'.tr;
      return '@$sendName $info [在线文档] $documentTitle';
    }
  }

  Future<String> sendNickName() async {
    final name =
        (await UserInfo.get(sendUserId))?.showName(guildId: guildId) ?? '';
    return name;
  }
}
