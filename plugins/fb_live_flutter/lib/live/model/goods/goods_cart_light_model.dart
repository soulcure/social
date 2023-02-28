class GoodsCartLightModel {
  int? iId;
  String? roomId;
  String? isShow;
  String? userId;
  String? cartCount;

  GoodsCartLightModel(
      {this.iId, this.roomId, this.isShow, this.userId, this.cartCount});

  GoodsCartLightModel.fromJson(Map<String, dynamic> json) {
    iId = json['_id'];
    roomId = json['roomId'];
    isShow = json['isShow'];
    userId = json['userId'];
    cartCount = json['cartCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = iId;
    data['roomId'] = roomId;
    data['isShow'] = isShow;
    data['userId'] = userId;
    data['cartCount'] = cartCount;
    return data;
  }
}
