import 'dart:ui' show hashValues;
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sk_product_wrapper.g.dart';

/// Dart 封装 StoreKit
/// [SKProductsResponse](https://developer.apple.com/documentation/storekit/skproductsresponse?language=objc).
/// 通过商品唯一标识获取到的道具列表信息
class SKProductResponseWrapper {
  /// 所有请求到的 [SKProductWrapper] 实例数组
  final List<SKProductWrapper> products;

  /// 无效唯一商品ID
  final List<String> invalidProductIdentifiers;

  SKProductResponseWrapper(
      {required this.products, required this.invalidProductIdentifiers});

  factory SKProductResponseWrapper.fromJson(Map map) {
    assert(map != null, 'Map 不能为空');
    return _$SkProductResponseWrapperFromJson(map);
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final SKProductResponseWrapper typedOther = other as SKProductResponseWrapper;
    return DeepCollectionEquality().equals(typedOther.products, products) &&
        DeepCollectionEquality().equals(
            typedOther.invalidProductIdentifiers, invalidProductIdentifiers);
  }

  @override
  int get hashCode => hashValues(this.products, this.invalidProductIdentifiers);

  @override
  String toString() => _$SkProductResponseWrapperToJson(this).toString();
}

/// Dart 封装 StoreKit
/// 订阅时间单位枚举
/// 查看 [SKProductPeriodUnit](https://developer.apple.com/documentation/storekit/skproductperiodunit?language=objc).
enum SKSubscriptionPeriodUnit {
  /// 间隔时间单位: 天
  @JsonValue(0)
  day,

  /// 间隔时间单位: 周
  @JsonValue(1)
  week,

  /// 间隔时间单位: 月
  @JsonValue(2)
  month,

  /// 间隔时间单位: 年
  @JsonValue(3)
  year,
}

/// Dart 封装 StoreKit
/// [SKProductSubscriptionPeriod](https://developer.apple.com/documentation/storekit/skproductsubscriptionperiod?language=objc).
/// 一个时间周期是由 [numberOfUnits] 和 [unit] 组成的
/// 例如 3个月  numberOfUnits 为 3 , unit 为 月
class SKProductSubscriptionPeriodWrapper {
  /// 指定时间单位的数量,必须大于0
  final int? numberOfUnits;

  /// 时间单位
  final SKSubscriptionPeriodUnit? unit;

  SKProductSubscriptionPeriodWrapper(
      {required this.numberOfUnits, required this.unit});

  factory SKProductSubscriptionPeriodWrapper.fromJson(Map map) {
    assert(map != null, 'SKProductSubscriptionPeriodWrapper Map 不能为空');
    return _$SKProductSubscriptionPeriodWrapperFromJson(map);
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final SKProductSubscriptionPeriodWrapper typedOther = other as SKProductSubscriptionPeriodWrapper;
    return typedOther.numberOfUnits == numberOfUnits && typedOther.unit == unit;
  }

  @override
  int get hashCode => hashValues(this.numberOfUnits, this.unit);

  @override
  String toString() =>
      _$SKProductSubscriptionPeriodWrapperToJson(this).toString();
}

/// Dart 封装 StoreKit
/// [SKProductDiscountPaymentMode](https://developer.apple.com/documentation/storekit/skproductdiscountpaymentmode?language=objc).
/// 折扣方式类型
enum SKProductDiscountPaymentMode {
  /// 新订户将在特定时间段内为每个结算周期支付折扣价。
  /// 例如，您可以提供三个月每月1.99美元的折扣价，从第四个月开始每月标准订阅价为3.99美元。
  @JsonValue(0)
  payAsYouGo,

  /// 新订户将在特定时间内支付一次性入门价格。特定周期结束后按正常价格进行续订
  /// 例如，如果您想提供每月订阅，但您认为用户需要大约六个月的时间来适应体验并且更有可能保留订阅，您可以提供6个月的入门价格9.99美元，
  /// 然后是从第七个月开始每月3.99美元的标准价格。
  @JsonValue(1)
  payUpFront,

  /// 新订阅者可以在特定时间内免费访问您应用的内容。订阅立即开始，并且在免费试用期结束后,订阅是以正常价格进行续订。
  @JsonValue(2)
  freeTrail,
}

class SKProductDiscountWrapper {
  /// The discounted price, in the currency that is defined in [priceLocale].
  final String? price;

  /// Includes locale information about the price, e.g. `$` as the currency symbol for US locale.
  final SKPriceLocaleWrapper? priceLocale;

  /// The object represent the discount period length.
  ///
  /// The value must be >= 0.
  final int? numberOfPeriods;

  /// The object indicates how the discount price is charged.
  final SKProductDiscountPaymentMode? paymentMode;

  /// The object represents the duration of single subscription period for the discount.
  ///
  /// The [subscriptionPeriod] of the discount is independent of the product's [subscriptionPeriod],
  /// and their units and duration do not have to be matched.
  final SKProductSubscriptionPeriodWrapper? subscriptionPeriod;

  SKProductDiscountWrapper(
      {required this.price,
      required this.priceLocale,
      required this.numberOfPeriods,
      required this.paymentMode,
      required this.subscriptionPeriod});

  factory SKProductDiscountWrapper.fromJson(Map map) {
    assert(map != null, 'SKProductDiscountWrapper Map不能为空');
    return _$SKProductDiscountWrapperFromJson(map);
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final SKProductDiscountWrapper typedOther = other as SKProductDiscountWrapper;
    return typedOther.price == price &&
        typedOther.priceLocale == priceLocale &&
        typedOther.numberOfPeriods == numberOfPeriods &&
        typedOther.paymentMode == paymentMode &&
        typedOther.subscriptionPeriod == subscriptionPeriod;
  }

  @override
  int get hashCode => hashValues(this.price, this.priceLocale,
      this.numberOfPeriods, this.paymentMode, this.subscriptionPeriod);

  @override
  String toString() => _$SKProductDiscountWrapperToJson(this).toString();
}

/// Dart 封装 StoreKit
/// 阅读文档[SKProduct](https://developer.apple.com/documentation/storekit/skproduct?language=objc).
/// 购买的商品信息
@JsonSerializable(nullable: true)
class SKProductWrapper {
  /// 商品唯一标识ID
  final String? productIdentifier;

  /// 商品标题
  final String? localizedTitle;

  /// 商品具体描述
  final String? localizedDescription;

  /// 本地化价格信息(包含了货币符号 和 货币代码)
  final SKPriceLocaleWrapper? priceLocale;

  /// 订阅组唯一标识ID
  final String? subscriptionGroupIdentifier;

  /// 价格
  final String? price;

  /// 订阅商品信息(如果是非订阅时为 null)
  final SKProductSubscriptionPeriodWrapper? subscriptionPeriod;

  /// 优惠 / 折扣价格信息
  /// 只有运营在App Store Connect对订阅道具设置了优惠 / 折扣时才有值
  /// 否则为空; 查阅 [https://developer.apple.com/documentation/storekit/in-app_purchase/offering_introductory_pricing_in_your_app?language=objc]
  final SKProductDiscountWrapper? introductoryPrice;

  SKProductWrapper(
      {required this.productIdentifier,
      required this.localizedTitle,
      required this.localizedDescription,
      required this.priceLocale,
      required this.subscriptionGroupIdentifier,
      required this.price,
      required this.subscriptionPeriod,
      required this.introductoryPrice});

  factory SKProductWrapper.fromJson(Map map) {
    assert(map != null, 'SKProductWrapper Map 不能为空');
    return _$SKProductWrapperFromJson(map);
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final SKProductWrapper typedOther = other as SKProductWrapper;
    return typedOther.productIdentifier == productIdentifier &&
        typedOther.localizedTitle == localizedTitle &&
        typedOther.localizedDescription == localizedDescription &&
        typedOther.priceLocale == priceLocale &&
        typedOther.subscriptionGroupIdentifier == subscriptionGroupIdentifier &&
        typedOther.price == price &&
        typedOther.subscriptionPeriod == subscriptionPeriod &&
        typedOther.introductoryPrice == introductoryPrice;
  }

  @override
  int get hashCode => hashValues(
      this.productIdentifier,
      this.localizedTitle,
      this.localizedDescription,
      this.priceLocale,
      this.subscriptionGroupIdentifier,
      this.price,
      this.subscriptionPeriod,
      this.introductoryPrice);

  @override
  String toString() => _$SKProductWrapperToJson(this).toString();
}

/// 货币价格本地化信息
/// Dart封装的对象
/// [NSLocale](https://developer.apple.com/documentation/foundation/nslocale?language=objc).
@JsonSerializable()
class SKPriceLocaleWrapper {
  /// Creates a new price locale for `currencySymbol` and `currencyCode`.
  SKPriceLocaleWrapper(
      {required this.currencySymbol, required this.currencyCode});

  /// Constructing an instance from a map from the Objective-C layer.
  ///
  /// This method should only be used with `map` values returned by [SKProductWrapper.fromJson] and [SKProductDiscountWrapper.fromJson].
  /// The `map` parameter must not be null.
  factory SKPriceLocaleWrapper.fromJson(Map map) {
    assert(map != null, 'Map must not be null.');
    return _$SKPriceLocaleWrapperFromJson(map);
  }

  /// 货币符号, 例如 $ 代表 美元
  final String? currencySymbol;

  ///T货币代码 例如 USD for 美元
  final String? currencyCode;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final SKPriceLocaleWrapper typedOther = other as SKPriceLocaleWrapper;
    return typedOther.currencySymbol == currencySymbol &&
        typedOther.currencyCode == currencyCode;
  }

  @override
  int get hashCode => hashValues(this.currencySymbol, this.currencyCode);

  @override
  String toString() => _$SKPriceLocaleWrapperToJson(this).toString();
}
