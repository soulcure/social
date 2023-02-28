import 'package:flutter/cupertino.dart';
import 'package:im/api/circle_api.dart';
import 'package:im/api/data_model/user_info.dart';
import 'package:im/app/modules/document_online/entity/doc_item.dart';
import 'package:im/common/extension/operation_extension.dart';
import 'package:im/common/extension/string_extension.dart';
import 'package:im/pages/guild_setting/circle/circle_share/circle_share_item.dart';
import 'package:im/pages/home/view/text_chat/rich_editor/utils.dart';

import 'circle_post_info_data_model.dart';
import 'circle_post_sub_info_data_model.dart';
import 'circle_post_user_data_model.dart';

/// * 圈子详情 model
class CirclePostDataModel {
  Map<String, dynamic> dataInfo;
  Map<String, dynamic> userInfo;
  Map<String, dynamic> postInfo;
  Map<String, dynamic> subInfo;
  Map<String, dynamic> docInfo;
  CirclePostUserDataModel _userDataModel;
  CirclePostInfoDataModel postInfoDataModel;
  CirclePostSubInfoDataModel _postSubInfoDataModel;

  /// * 腾讯文档数据：对应圈子详情接口返回的doc_info
  DocItem docItem;

  String topicId;
  String circleId;
  String postId;

  /// * 艾特的用户ID
  List<String> atUserIdList;

  CirclePostDataModel(
      {this.dataInfo = const {},
      this.userInfo = const {},
      this.postInfo = const {},
      this.subInfo = const {},
      this.docInfo,
      this.topicId = '',
      this.circleId = '',
      this.postId = ''}) {
    _userDataModel = CirclePostUserDataModel.fromJson(userInfo);
    postInfoDataModel = CirclePostInfoDataModel.fromJson(postInfo);
    _postSubInfoDataModel = CirclePostSubInfoDataModel.fromJson(subInfo);
    postId = postInfoDataModel.postId;
    atUserIdList = atListFromJson(postInfo['mentions_info']);
    setDocItem();
  }

  CirclePostDataModel.fromNet(this.topicId, this.circleId, this.postId);

  Future initFromNet({bool showErrorToast = false}) async {
    final result = await CircleApi.circlePostDetail(postId,
        showErrorToast: showErrorToast);
    dataInfo = result;
    userInfo = result['user'];
    postInfo = result['post'];
    subInfo = result['sub_info'];
    docInfo = result['doc_info'] as Map<String, dynamic>;
    _userDataModel = CirclePostUserDataModel.fromJson(userInfo);
    postInfoDataModel = CirclePostInfoDataModel.fromJson(postInfo);
    _postSubInfoDataModel = CirclePostSubInfoDataModel.fromJson(subInfo);
    postId = postInfoDataModel.postId;

    ///圈子详情接口返回了最新的服务器昵称，需要本地保存
    if (postInfo['mentions_info'] != null)
      atUserIdList = atListFromJson(postInfo['mentions_info']);

    setDocItem();
  }

  void setDocItem() {
    if (docInfo != null && docInfo.isNotEmpty)
      docItem = DocItem.fromMap(docInfo);
    if (postInfoDataModel.fileId.hasValue) {
      //fileId有值
      if (docItem != null) {
        //docInfo为值，显示文档
        docItem.fileId = postInfoDataModel.fileId;
      } else {
        //docInfo为空，文档被删除
        docItem = DocItem(canCopy: false, canReaderComment: false);
      }
    } else {
      docItem = null;
    }
  }

  List<String> atListFromJson(Map json) {
    try {
      if (json != null && json.isNotEmpty) {
        final List<String> userIdList = [];
        json.forEach((key, value) {
          if (!userIdList.contains(key)) userIdList.add(key);
          if (value != null) {
            UserInfo.updateIfChanged(
              userId: value["user_id"],
              nickname: value["nickname"],
              gNick: value['gnick'],
              avatar: value['avatar'],
              avatarNft: value['avatar_nft'],
              isBot: value['bot'],
              guildId: postInfoDataModel.guildId,
            );
          }
        });
        return userIdList;
      }
    } catch (_) {}
    return null;
  }

  factory CirclePostDataModel.fromJson(Map<String, dynamic> json) =>
      CirclePostDataModel(
        dataInfo: json,
        userInfo: (json['user'] ?? {}) as Map,
        postInfo: (json['post'] ?? {}) as Map,
        subInfo: (json['sub_info'] ?? {}) as Map,
        docInfo: json['doc_info'] as Map<String, dynamic>,
      );

  CirclePostUserDataModel get userDataModel {
    return _userDataModel;
  }

  CirclePostSubInfoDataModel get postSubInfoDataModel {
    return _postSubInfoDataModel;
  }

  void modifyLikedState(String iLiked, String likeId, {String postId}) {
    _postSubInfoDataModel.modifyLikeState(iLiked, likeId);
    subInfo['like_total'] = _postSubInfoDataModel.likeTotal;
    subInfo['likeId'] = _postSubInfoDataModel.likeId;
    subInfo['liked'] = _postSubInfoDataModel.iLiked;
    _updatePostInfo(postId: postId);
  }

  ///更新内存中存储的关于圈子的数据
  void _updatePostInfo({String postId}) {
    final pId = postId ?? this.postId;
    final postInfo = postInfoMap[pId];
    final commentTotal = _postSubInfoDataModel.commentTotal;
    final likeTotal = _postSubInfoDataModel.likeTotal;
    final liked = _postSubInfoDataModel.iLiked == '1';
    final title = postInfoDataModel.title;
    final content =
        postInfoDataModel.postContent() ?? RichEditorUtils.defaultDoc.encode();
    if (postInfo == null)
      postInfoMap[pId] = PostInfo(
          ValueNotifier(commentTotal),
          ValueNotifier(likeTotal),
          ValueNotifier(title),
          ValueNotifier(content),
          ValueNotifier(liked),
          ValueNotifier(false),
          pId);
    else
      postInfo.setData(
          commentTotal: commentTotal, liked: liked, likeTotal: likeTotal);
  }

  void updateByAnother(CirclePostDataModel model) {
    dataInfo = model.dataInfo;
    userInfo = model.userInfo;
    postInfo = model.postInfo;
    subInfo = model.subInfo;
    postInfoDataModel = model.postInfoDataModel;
    _postSubInfoDataModel = model._postSubInfoDataModel;
    _userDataModel = model._userDataModel;
  }

  void modifyILiked(String iLiked) {
    _postSubInfoDataModel.modifyILiked(iLiked);
    subInfo['liked'] = iLiked;
  }

  Map<String, dynamic> toJson() => {
        'user': userInfo,
        'post': postInfo,
        'sub_info': subInfo,
      };

  Map<String, dynamic> toJsonByModel() => {
        'user': _userDataModel.toJson(),
        'post': postInfoDataModel.toJson(),
        'sub_info': _postSubInfoDataModel.toJson(),
      };
}
