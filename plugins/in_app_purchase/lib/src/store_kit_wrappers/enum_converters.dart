import 'package:in_app_purchase/src/in_app_purchase/purchase_details.dart';
import 'package:in_app_purchase/src/store_kit_wrappers/sk_payment_transaction_wrappers.dart';
import 'package:json_annotation/json_annotation.dart';

part 'enum_converters.g.dart';

class SKTransactionStatusConverter
    implements JsonConverter<SKPaymentTransactionStateWrapper?, int?> {
  const SKTransactionStatusConverter();

  /// json中的int值转换成枚举值
  @override
  SKPaymentTransactionStateWrapper? fromJson(int? json) =>
      _$enumDecode<SKPaymentTransactionStateWrapper>(
          _$SKPaymentTransactionStateWrapperEnumMap
              .cast<SKPaymentTransactionStateWrapper, dynamic>(),
          json);

  PurchaseStatus toPurchaseStatus(SKPaymentTransactionStateWrapper? object) {
    switch (object) {
      case SKPaymentTransactionStateWrapper.purchasing:
      case SKPaymentTransactionStateWrapper.deferred:
        return PurchaseStatus.pending;
      case SKPaymentTransactionStateWrapper.purchased:
      case SKPaymentTransactionStateWrapper.restored:
        return PurchaseStatus.purchased;
      case SKPaymentTransactionStateWrapper.failed:
      case null:
        return PurchaseStatus.error;
    }

    throw ArgumentError('$object isn\'t mapped to PurchaseStatus');
  }

  /// 枚举转换成int
  @override
  int? toJson(SKPaymentTransactionStateWrapper? object) =>
      _$SKPaymentTransactionStateWrapperEnumMap[object!];
}

@JsonSerializable()
class _SerializedEnums {
  SKPaymentTransactionStateWrapper? response;
}
