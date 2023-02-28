class RoomGiftsModel {
  int? pageNum;
  int? pageSize;
  int? total;
  int? pageCount;
  List<Result>? result;

  RoomGiftsModel(
      {this.pageNum, this.pageSize, this.total, this.pageCount, this.result});

  RoomGiftsModel.fromJson(Map<String, dynamic> json) {
    pageNum = json['pageNum'];
    pageSize = json['pageSize'];
    total = json['total'];
    pageCount = json['pageCount'];
    if (json['result'] != null) {
      result = <Result>[];
      json['result'].forEach((v) {
        result!.add(Result.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pageNum'] = pageNum;
    data['pageSize'] = pageSize;
    data['total'] = total;
    data['pageCount'] = pageCount;
    if (result != null) {
      data['result'] = result!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Result {
  int? id;
  String? name;
  String? imgUrl;
  int? price;

  Result({this.id, this.name, this.imgUrl, this.price});

  Result.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    imgUrl = json['imgUrl'];
    price = json['price'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['imgUrl'] = imgUrl;
    data['price'] = price;
    return data;
  }
}
