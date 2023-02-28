class CircleDetailBean {
  List<ReplyDetailBean> replys;
  ReplyDetailBean item;
  PostBean post;
  String size;
  String listId;
  String next;

  ///circlePostComment/around 接口返回的上下部分回复列表数量
  int afterSize = 0;
  int beforeSize = 0;
  List<ReplyDetailBean> after;

  CircleDetailBean() {
    replys = [];
  }

  CircleDetailBean.fromMap(Map<String, dynamic> map) {
    replys = [
      ...(map['records'] as List ?? []).map((o) => ReplyDetailBean.fromMap(o))
    ];
    sort(isDesc: map['isDesc'] ?? true);
    size = map['size']?.toString();
    item = ReplyDetailBean.fromMap(map['item']);
    post = PostBean.fromMap(map['post']);
    listId = map['list_id']?.toString();
    next = map['next'];
  }

  CircleDetailBean.fromAroundMap(Map<String, dynamic> map) {
    final before =
    (map['before'] as List ?? []).map((o) => ReplyDetailBean.fromMap(o));
    beforeSize = before.length;
    after = (map['after'] as List ?? [])
        .map((o) => ReplyDetailBean.fromMap(o))
        .toList(growable: false);
    afterSize = after.length;
    final current =
    (map['current'] as List ?? []).map((o) => ReplyDetailBean.fromMap(o));
    replys = [...before, ...current, ...after];
    sort();
  }

  void sort({bool isDesc = true}) {
    try {
      if (replys.isNotEmpty) {
        if (isDesc)
          replys.sort(
              (a, b) => b.comment.commentId.compareTo(a.comment.commentId));
        else
          replys.sort(
              (a, b) => a.comment.commentId.compareTo(b.comment.commentId));
      }
    } catch (_) {}
  }

  CircleDetailBean.fromDataWithMap(
      Map<String, dynamic> map, Map<String, int> commentMap) {
    int length = 0;
    replys = [
      ...(map['records'] as List ?? []).map((o) {
        final bean = ReplyDetailBean.fromMap(o);
        commentMap[bean.comment.commentId] = length;
        length++;
        return bean;
      })
    ];
    size = map['size']?.toString();
    listId = map['list_id']?.toString();
    next = map['next'];
  }

  Map toJson() => {
        "records": replys,
        "size": size,
        "list_id": listId,
        "next": next,
      };
}

class PostBean {
  SubInfoBean subInfo;

  PostBean.fromMap(Map<String, dynamic> map) {
    if (map == null) return;
    subInfo = SubInfoBean.fromMap(map['sub_info']);
  }

  Map toJson() => {
        "sub_info": subInfo,
      };
}

class SubInfoBean {
  int commentTotal;
  int likeTotal;
  int liked;
  String likeId;

  SubInfoBean.fromMap(Map<String, dynamic> map) {
    commentTotal = map['comment_total'];
    likeTotal = map['like_total'];
    liked = map['liked'];
    likeId = map['like_id'];
  }

  Map toJson() => {
        "comment_total": commentTotal,
        "like_total": likeTotal,
      };
}

/// comment : {"post_id":"159292323912482816","bucket":44,"comment_id":"159935774031085568","channel_id":"159288470513123328","content":"ddddddddd","created_at":1603354547000,"guild_id":"142885263687811072","quote_l1":null,"replay_list":[{"comment":{"post_id":"159292323912482816","bucket":44,"comment_id":"159935774031085568","channel_id":"159288470513123328","content":"ddddddddd","created_at":1603354547000,"guild_id":"142885263687811072","quote_l1":159935774031085568,"replay_list":null,"quote_status":null,"reaction":null,"topic_id":"159290131172294656","reply_user_id":"86490735033065472","user_id":"86490735033065472"},"user":{"avatar":"https://xms-dev-1251001060.cos.ap-guangzhou.myqcloud.com/x-project/user-upload-files/d05248587bbdbbac895ab558536ba355","user_id":"86490735033065472","username":"4551735","nickname":"dragon/5😀😀😀"}},{"comment":{"post_id":"159292323912482816","bucket":44,"comment_id":"159935774031085568","channel_id":"159288470513123328","content":"ddddddddd","created_at":1603354547000,"guild_id":"142885263687811072","quote_l1":159935774031085568,"replay_list":null,"quote_status":null,"reaction":null,"topic_id":"159290131172294656","reply_user_id":"86490735033065472","user_id":"86490735033065472"},"user":{"avatar":"https://xms-dev-1251001060.cos.ap-guangzhou.myqcloud.com/x-project/user-upload-files/d05248587bbdbbac895ab558536ba355","user_id":"86490735033065472","username":"4551735","nickname":"dragon/5😀😀😀"}},{"comment":{"post_id":"159292323912482816","bucket":44,"comment_id":"159935774031085568","channel_id":"159288470513123328","content":"ddddddddd","created_at":1603354547000,"guild_id":"142885263687811072","quote_l1":159935774031085568,"quote_l2":159935774031085568,"replay_list":null,"quote_status":null,"reaction":null,"topic_id":"159290131172294656","reply_user_id":"86490735033065472","user_id":"86490735033065472"},"user":{"avatar":"https://xms-dev-1251001060.cos.ap-guangzhou.myqcloud.com/x-project/user-upload-files/d05248587bbdbbac895ab558536ba355","user_id":"86490735033065472","username":"4551735","nickname":"dragon/5😀😀😀"}}],"quote_status":1,"reaction":null,"like_total":40,"comment_total":40,"topic_id":"159290131172294656","user_id":"86490735033065472"}
/// user : {"avatar":"https://xms-dev-1251001060.cos.ap-guangzhou.myqcloud.com/x-project/user-upload-files/d05248587bbdbbac895ab558536ba355","user_id":"86490735033065472","username":"4551735","nickname":"dragon/5😀😀😀"}

class ReplyDetailBean {
  CommentBean comment;
  UserBean user;

  ReplyDetailBean(this.comment, this.user);

  ReplyDetailBean.fromMap(Map<String, dynamic> map) {
    if (map == null) return;
    comment = CommentBean.fromMap(map['comment']);
    user = UserBean.fromMap(map['user']);
  }

  Map toJson() => {
        "comment": comment,
        "user": user,
      };
}

/// avatar : "https://xms-dev-1251001060.cos.ap-guangzhou.myqcloud.com/x-project/user-upload-files/d05248587bbdbbac895ab558536ba355"
/// user_id : "86490735033065472"
/// username : "4551735"
/// nickname : "dragon/5😀😀😀"

class UserBean {
  String avatar;
  String userId;
  String username;
  String nickname;

  UserBean({this.avatar, this.userId, this.username, this.nickname});

  UserBean.fromMap(Map<String, dynamic> map) {
    if (map?.isEmpty ?? true) return;
    avatar = map['avatar'];
    userId = map['user_id'];
    username = map['username'];
    nickname = map['nickname'];
  }

  Map toJson() => {
        "avatar": avatar,
        "user_id": userId,
        "username": username,
        "nickname": nickname,
      };
}

/// post_id : "159292323912482816"
/// bucket : 44
/// comment_id : "159935774031085568"
/// channel_id : "159288470513123328"
/// content : "ddddddddd"
/// created_at : 1603354547000
/// guild_id : "142885263687811072"
/// quote_l1 : null
/// replay_list : [{"comment":{"post_id":"159292323912482816","bucket":44,"comment_id":"159935774031085568","channel_id":"159288470513123328","content":"ddddddddd","created_at":1603354547000,"guild_id":"142885263687811072","quote_l1":159935774031085568,"replay_list":null,"quote_status":null,"reaction":null,"topic_id":"159290131172294656","reply_user_id":"86490735033065472","user_id":"86490735033065472"},"user":{"avatar":"https://xms-dev-1251001060.cos.ap-guangzhou.myqcloud.com/x-project/user-upload-files/d05248587bbdbbac895ab558536ba355","user_id":"86490735033065472","username":"4551735","nickname":"dragon/5😀😀😀"}},{"comment":{"post_id":"159292323912482816","bucket":44,"comment_id":"159935774031085568","channel_id":"159288470513123328","content":"ddddddddd","created_at":1603354547000,"guild_id":"142885263687811072","quote_l1":159935774031085568,"replay_list":null,"quote_status":null,"reaction":null,"topic_id":"159290131172294656","reply_user_id":"86490735033065472","user_id":"86490735033065472"},"user":{"avatar":"https://xms-dev-1251001060.cos.ap-guangzhou.myqcloud.com/x-project/user-upload-files/d05248587bbdbbac895ab558536ba355","user_id":"86490735033065472","username":"4551735","nickname":"dragon/5😀😀😀"}},{"comment":{"post_id":"159292323912482816","bucket":44,"comment_id":"159935774031085568","channel_id":"159288470513123328","content":"ddddddddd","created_at":1603354547000,"guild_id":"142885263687811072","quote_l1":159935774031085568,"quote_l2":159935774031085568,"replay_list":null,"quote_status":null,"reaction":null,"topic_id":"159290131172294656","reply_user_id":"86490735033065472","user_id":"86490735033065472"},"user":{"avatar":"https://xms-dev-1251001060.cos.ap-guangzhou.myqcloud.com/x-project/user-upload-files/d05248587bbdbbac895ab558536ba355","user_id":"86490735033065472","username":"4551735","nickname":"dragon/5😀😀😀"}}]
/// quote_status : 1
/// reaction : null
/// like_total : 40
/// comment_total : 40
/// topic_id : "159290131172294656"
/// user_id : "86490735033065472"

class CommentBean {
  String postId;
  int bucket;
  String commentId;
  String channelId;
  String content;
  int createdAt;
  int level;
  String guildId;
  String quoteL1;
  String replyUserId;
  List<ReplyDetailBean> replayList;
  UserBean replyUser;
  bool quoteStatus;
  dynamic reaction;
  int likeTotal;
  String likeId;
  String liked;
  int commentTotal;
  String topicId;
  String userId;

  CommentBean(
      {this.postId,
      this.bucket,
      this.commentId,
      this.channelId,
      this.content,
      this.createdAt,
      this.guildId,
      this.quoteL1,
      this.level,
      this.replyUserId,
      this.replayList,
      this.replyUser,
      this.quoteStatus,
      this.reaction,
      this.likeTotal,
      this.commentTotal,
      this.topicId,
      this.userId,
      this.liked,
      this.likeId});

  CommentBean.fromMap(Map<String, dynamic> map) {
    final userInfo = map['reply_user_info'];
    postId = map['post_id'];
    bucket = map['bucket'];
    commentId = map['comment_id'];
    channelId = map['channel_id'];
    content = map['content'];
    createdAt = map['created_at'];
    level = map['level'];
    guildId = map['guild_id'];
    quoteL1 = map['quote_l1'];
    replyUserId = map['reply_user_id'];
    if (userInfo != null)
      replyUser = UserBean.fromMap((userInfo is List) ? {} : userInfo);
    replayList = [
      ...(map['replay_list'] as List ?? [])
          .map((o) => ReplyDetailBean.fromMap(o))
    ];
    quoteStatus = map['quote_status'];
    reaction = map['reaction'];
    likeTotal = map['like_total'];
    commentTotal = map['comment_total'];
    topicId = map['topic_id'];
    userId = map['user_id'];
    liked = map['liked']?.toString();
    likeId = map['like_id'];
  }

  Map toJson() => {
        "post_id": postId,
        "bucket": bucket,
        "comment_id": commentId,
        "channel_id": channelId,
        "content": content,
        "created_at": createdAt,
        "guild_id": guildId,
        "quote_l1": quoteL1,
        "level": level,
        "replay_list": replayList,
        "quote_status": quoteStatus,
        "reaction": reaction,
        "like_total": likeTotal,
        "comment_total": commentTotal,
        "topic_id": topicId,
        "user_id": userId,
        "liked": liked,
        "like_id": likeId,
      };

  void increaseCommentTotal() {
    commentTotal ??= 0;
    commentTotal++;
  }

  void decreaseCommentTotal() {
    commentTotal ??= 1;
    if (commentTotal <= 0) commentTotal = 1;
    commentTotal--;
  }
}
