

class AuditInfoBean {
  String imageUrl;
  String textUrl;
  String videoUrl;
  String accessKey;
  PermissionBean permission;

  AuditInfoBean.fromMap(Map<String, dynamic> map) {
    imageUrl = map['image_url'];
    textUrl = map['text_url'];
    videoUrl = map['video_url'];
    accessKey = map['access_key'];
    permission = PermissionBean.fromMap(map['permission']);
  }

  Map toJson() => {
    "image_url": imageUrl,
    "text_url": textUrl,
    "video_url": videoUrl,
    "access_key": accessKey,
    "permission": permission,
  };
}

class PermissionBean {
  SingleChatFriendBean singleChatFriend;
  SingleChatStrangerBean singleChatStranger;
  PublicChannelChatBean publicChannelChat;
  PrivateChannelChatBean privateChannelChat;
  CircleChannelBean circleChannelBean;

  PermissionBean.fromMap(Map<String, dynamic> map) {
    singleChatFriend = SingleChatFriendBean.fromMap(map['single_chat_friend']);
    singleChatStranger = SingleChatStrangerBean.fromMap(map['single_chat_stranger']);
    publicChannelChat = PublicChannelChatBean.fromMap(map['public_channel_chat']);
    privateChannelChat = PrivateChannelChatBean.fromMap(map['private_channel_chat']);
    circleChannelBean = CircleChannelBean.fromMap(map['circle_channel']);
  }

  Map toJson() => {
    "single_chat_friend": singleChatFriend,
    "single_chat_stranger": singleChatStranger,
    "public_channel_chat": publicChannelChat,
    "private_channel_chat": privateChannelChat,
    "circle_channel": circleChannelBean,
  };
}

/// image : "1"
/// text : "1"
/// video : "0"

class PrivateChannelChatBean {
  String image;
  String text;
  String video;

  PrivateChannelChatBean.fromMap(Map<String, dynamic> map) {
    image = map['image'];
    text = map['text'];
    video = map['video'];
  }

  Map toJson() => {
    "image": image,
    "text": text,
    "video": video,
  };
}

/// image : "1"
/// text : "1"
/// video : "0"

class PublicChannelChatBean {
  String image;
  String text;
  String video;

  PublicChannelChatBean.fromMap(Map<String, dynamic> map) {
    image = map['image'];
    text = map['text'];
    video = map['video'];
  }

  Map toJson() => {
    "image": image,
    "text": text,
    "video": video,
  };
}

/// image : "1"
/// text : "1"
/// video : "0"

class SingleChatStrangerBean {
  String image;
  String text;
  String video;

  SingleChatStrangerBean.fromMap(Map<String, dynamic> map) {
    image = map['image'];
    text = map['text'];
    video = map['video'];
  }

  Map toJson() => {
    "image": image,
    "text": text,
    "video": video,
  };
}

/// image : "0"
/// text : "0"
/// video : "0"

class SingleChatFriendBean {
  String image;
  String text;
  String video;

  SingleChatFriendBean.fromMap(Map<String, dynamic> map) {
    image = map['image'];
    text = map['text'];
    video = map['video'];
  }

  Map toJson() => {
    "image": image,
    "text": text,
    "video": video,
  };
}

class CircleChannelBean {
  String image;
  String text;
  String video;

  CircleChannelBean.fromMap(Map<String, dynamic> map) {
    if(map == null || map.isEmpty) return;
    image = map['image'];
    text = map['text'];
    video = map['video'];
  }

  Map toJson() => {
    "image": image,
    "text": text,
    "video": video,
  };
}