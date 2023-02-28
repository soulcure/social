


import 'package:im/global.dart';

import 'circle_detail_list_bean.dart';

class CircleCommentBean {
  String guildId;
  String channelId;
  String topicId;
  String content;
  String postId;
  String quoteL1;
  String transaction;
  String userId;
  String clientId;
  int level;
  String commentId;
  int createdAt;
  String replyUserId;
  UserBean replyUser;

  CircleCommentBean.fromMap(Map<String, dynamic> map) {
    guildId = map['guild_id'];
    channelId = map['channel_id'];
    topicId = map['topic_id'];
    content = map['content'];
    postId = map['post_id'];
    quoteL1 = map['quote_l1'];
    transaction = map['transaction'];
    userId = map['user_id'];
    clientId = map['client_id'];
    level = map['level'];
    commentId = map['comment_id'];
    createdAt = map['created_at'];
  }

  Map toJson() => {
    "guild_id": guildId,
    "channel_id": channelId,
    "topic_id": topicId,
    "content": content,
    "post_id": postId,
    "quote_l1": quoteL1,
    "transaction": transaction,
    "user_id": userId,
    "client_id": clientId,
    "level": level,
    "comment_id": commentId,
    "created_at": createdAt,
  };


  static ReplyDetailBean toReplyDetailBean(CircleCommentBean bean){
    final userInfo = Global.user;
    final user = UserBean(
        avatar: userInfo.avatar,
        userId: userInfo.id,
        username: userInfo.username,
        nickname: userInfo.nickname
    );
    return ReplyDetailBean(toCommentBean(bean), user);
  }

  static ReplyDetailBean toCommentReplyDetailBean(CircleCommentBean bean){
    final userInfo = Global.user;
    final user = UserBean(
        avatar: userInfo.avatar,
        userId: userInfo.id,
        username: userInfo.username,
        nickname: userInfo.nickname
    );
    final result = ReplyDetailBean(toCommentBean(bean), user);
    return result;
  }

  static CommentBean toCommentBean(CircleCommentBean bean){
    final userInfo = Global.user;
    final commentBean = CommentBean(
        postId: bean.postId,
        bucket: 0,
        commentId: bean.commentId,
        channelId: bean.channelId,
        content: bean.content,
        createdAt: bean.createdAt,
        guildId: bean.guildId,
        quoteL1: bean.quoteL1,
        level: bean.level,
        replyUserId: bean.replyUserId,
        replyUser: bean.replyUser,
        quoteStatus: true,
        reaction: '',
        likeTotal: 0,
        commentTotal: 0,
        topicId: bean.topicId,
        userId: userInfo.id
    );
    return commentBean;
  }

}