class GoodsPushModel {
  int? index;
  String? expiredTime;
  int? countdown;
  int? shopId;
  int? itemId;
  String? title;
  String? subTitle;
  String? alias;
  String? image;
  String? origin;
  String? price;
  String? detailUrl;
  int? quantity;
  int? count;
  String? content;

  GoodsPushModel({
    this.index,
    this.expiredTime,
    this.countdown,
    this.shopId,
    this.itemId,
    this.title,
    this.subTitle,
    this.alias,
    this.image,
    this.origin,
    this.price,
    this.count = 10,
    this.detailUrl,
    this.quantity,
    this.content = "pushGoods",
  });

  GoodsPushModel.fromJson(Map<String, dynamic> json) {
    index = json['index'];
    expiredTime = json['expiredTime'];
    countdown = json['countdown'];
    shopId = json['shopId'];
    itemId = json['itemId'];
    title = json['title'];
    subTitle = json['subTitle'];
    alias = json['alias'];
    image = json['image'];
    origin = json['origin'];
    price = json['price'];
    detailUrl = json['detailUrl'];
    quantity = json['quantity'];
    count = json['count'];
    content = json['content'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['index'] = index;
    data['expiredTime'] = expiredTime;
    data['countdown'] = countdown ??
        ((DateTime.parse(expiredTime!).millisecondsSinceEpoch ~/ 1000) -
            (DateTime.now().millisecondsSinceEpoch ~/ 1000));
    data['shopId'] = shopId;
    data['itemId'] = itemId;
    data['title'] = title;
    data['subTitle'] = subTitle;
    data['alias'] = alias;
    data['image'] = image;
    data['origin'] = origin;
    data['price'] = price;
    data['detailUrl'] = detailUrl;
    data['quantity'] = quantity;
    data['count'] = count;
    data['content'] = content;
    return data;
  }
}
