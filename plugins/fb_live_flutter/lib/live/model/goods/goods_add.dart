import 'package:fb_live_flutter/live/utils/func/utils_class.dart';
import 'package:flutter/cupertino.dart';

class GoodsListModel {
  int? shopId;
  int? itemId;
  String? title;
  String? summary;
  String? alias;
  List<String>? images;
  String? origin;
  String? price;
  String? detailUrl;
  String? image;
  int? quantity;
  int? startSaleNum;
  int? buyQuota;
  List<SkuProps>? skuProps;
  List<SkuList>? skuList;
  int? spuId;
  bool? isCanSelect;
  List<GoodsMessageModel>? messages;
  bool? checked;
  int? itemType;

  GoodsListModel({
    this.shopId,
    this.itemId,
    this.title,
    this.summary,
    this.alias,
    this.images,
    this.image,
    this.origin,
    this.price,
    this.isCanSelect = true,
    this.detailUrl,
    this.quantity,
    this.startSaleNum,
    this.buyQuota,
    this.skuProps,
    this.skuList,
    this.spuId,
    this.messages,
    this.checked,
    this.itemType,
  });

  GoodsListModel.fromJson(Map<String, dynamic> json) {
    shopId = json['shopId'];
    itemId = json['itemId'] ?? json['item_id'];
    title = json['title'];
    summary = json['subTitle'] ?? json['summary'];
    alias = json['alias'];
    images = listNoEmpty(json['images']) ? json['images'].cast<String>() : [];
    origin = json['origin'];
    image = json['image'];
    price = json['price'];
    detailUrl = json['detailUrl'];
    quantity = json['quantity'];
    startSaleNum = json['startSaleNum'];
    buyQuota = json['buyQuota'];
    if (json['skuProps'] != null) {
      skuProps = <SkuProps>[];
      json['skuProps'].forEach((v) {
        skuProps!.add(SkuProps.fromJson(v));
      });
    }
    if (json['skuList'] != null) {
      skuList = <SkuList>[];
      json['skuList'].forEach((v) {
        skuList!.add(SkuList.fromJson(v));
      });
    }
    if (json['messages'] != null) {
      messages = <GoodsMessageModel>[];
      json['messages'].forEach((v) {
        messages!.add(GoodsMessageModel.fromJson(v));
      });
    }
    spuId = json['spuId'];
    itemType = json['itemType'];
    checked = json['checked'];
    if (checked != null) {
      isCanSelect = !checked!;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['shopId'] = shopId;
    data['item_id'] = itemId;
    data['image'] = image;
    data['title'] = title;
    data['summary'] = summary;
    data['alias'] = alias;
    data['images'] = images;
    data['origin'] = origin;
    data['price'] = price;
    data['detailUrl'] = detailUrl;
    data['quantity'] = quantity;
    data['startSaleNum'] = startSaleNum;
    data['buyQuota'] = buyQuota;
    if (skuProps != null) {
      data['skuProps'] = skuProps!.map((v) => v.toJson()).toList();
    }
    if (skuList != null) {
      data['skuList'] = skuList!.map((v) => v.toJson()).toList();
    }
    if (messages != null) {
      data['messages'] = messages!.map((v) => v.toJson()).toList();
    }
    data['spuId'] = spuId;
    data['checked'] = checked;
    data['itemType'] = itemType;
    return data;
  }
}

class SkuProps {
  int? propId;
  String? propName;
  int? selectValueId;
  String? selectValueName;
  List<SkuValues>? values;

  SkuProps({this.propId, this.propName, this.values});

  SkuProps.fromJson(Map<String, dynamic> json) {
    propId = json['propId'];
    propName = json['propName'];
    if (json['values'] != null) {
      values = <SkuValues>[];
      json['values'].forEach((v) {
        values!.add(SkuValues.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['propId'] = propId;
    data['propName'] = propName;
    data['selectValueId'] = selectValueId;
    data['selectValueName'] = selectValueName;
    if (values != null) {
      data['values'] = values!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

/// 【2021 12.04】
/// 1。选中的规格数量大于等于规格总数减1【只有1/0个没选的时候】则处理最后那个的库存不足致灰；
/// 2。如果只有一个规格一开始初始化就要处理库存为空情况；
///
///
class SkuValues {
  int? valueId;
  String? valueName;
  String? image;

  /// 状态：1=未选中；2=选中；3=禁用
  int? status;

  SkuValues({this.valueId, this.valueName, this.image, this.status = 1});

  SkuValues.fromJson(Map<String, dynamic> json) {
    valueId = json['valueId'];
    valueName = json['valueName'];
    image = json['image'];

    /// 默认设置为未选择
    status = 1;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['valueId'] = valueId;
    data['valueName'] = valueName;
    data['image'] = image;
    return data;
  }
}

class SkuList {
  int? skuId;
  List<int>? propValues;
  String? price;
  int? stockNum;

  SkuList({this.skuId, this.propValues, this.price, this.stockNum});

  SkuList.fromJson(Map<String, dynamic> json) {
    skuId = json['skuId'];
    propValues =
        listNoEmpty(json['propValues']) ? json['propValues'].cast<int>() : [];
    price = json['price'];
    stockNum = json['stockNum'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['skuId'] = skuId;
    data['propValues'] = propValues;
    data['price'] = price;
    data['stockNum'] = stockNum;
    return data;
  }
}

class GoodsMessageModel {
  int? required;
  String? name;
  String? type;
  TextEditingController? controller;

  GoodsMessageModel({
    this.required,
    this.name,
    this.type,
  });

  GoodsMessageModel.fromJson(Map<String, dynamic> json) {
    required = json['required'];
    name = json['name'];
    type = json['type'];
    controller = TextEditingController();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['required'] = required;
    data['name'] = name;
    data['type'] = type;
    return data;
  }
}
