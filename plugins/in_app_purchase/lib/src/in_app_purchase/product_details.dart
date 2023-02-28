import 'package:in_app_purchase/store_kit_wrappers.dart';

import 'in_app_purchase_connection.dart';

/// 购买商品信息
class ProductDetails {
  /// 商品唯一标识ID
  final String? productIdentifier;

  /// 商品标题
  final String? localizedTitle;

  /// 商品具体描述
  final String? localizedDescription;

  /// 价格
  final String? price;

  ProductDetails(
      {required this.productIdentifier,
      this.localizedTitle,
      this.localizedDescription,
      this.price});

  ProductDetails.fromSKProduct(SKProductWrapper product)
      : this.productIdentifier = product.productIdentifier,
        this.localizedTitle = product.localizedTitle,
        this.localizedDescription = product.localizedDescription,
        this.price = product.priceLocale!.currencySymbol! + product.price!;
}

class ProductDetailsResponse {
  /// 所有请求到的 [SKProductWrapper] 实例数组
  final List<ProductDetails>? products;

  /// 无效唯一商品ID
  final List<String>? invalidProductIdentifiers;

  /// 错误信息
  final IAPError? error;

  ProductDetailsResponse(
      {this.products, this.invalidProductIdentifiers, this.error});
}
