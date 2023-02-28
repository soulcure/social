class GiftSuccessModel {
  int? giftId;
  String? giftName;
  int? giftQt;
  String? giftImgUrl;

  GiftSuccessModel({this.giftId, this.giftName, this.giftQt, this.giftImgUrl});

  GiftSuccessModel.fromJson(Map<String, dynamic> json) {
    giftId = json['giftId'];
    giftName = json['giftName'];
    giftQt = json['giftQt'];
    giftImgUrl = json['giftImgUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['giftId'] = giftId;
    data['giftName'] = giftName;
    data['giftQt'] = giftQt;
    data['giftImgUrl'] = giftImgUrl;
    return data;
  }
}
