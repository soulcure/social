part of 'sk_payment_transaction_wrappers.dart';

/// 交易信息Map序列化为实体对象
SKPaymentTransactionWrapper _$SKPaymentTransactionWrapperFromJson(Map json) {
  return SKPaymentTransactionWrapper(
    payment: json['payment'] == null
        ? null
        : SKPaymentWrapper.fromJson(json['payment'] as Map),
    transactionState: const SKTransactionStatusConverter()
        .fromJson(json['transactionState'] as int?),
    originalTransaction: json['originalTransaction'] == null
        ? null
        : SKPaymentTransactionWrapper.fromJson(
            json['originalTransaction'] as Map),
    transactionTimeStamp: (json['transactionTimeStamp'] as num?)?.toDouble(),
    transactionIdentifier: json['transactionIdentifier'] as String?,
    transactionReceipt: json['transactionReceipt'] as String?,
    error:
        json['error'] == null ? null : SKError.fromJson(json['error'] as Map),
  );
}

/// 交易信息实体对象序列化为Map
Map<String, dynamic> _$SKPaymentTransactionWrapperToJson(
        SKPaymentTransactionWrapper instance) =>
    <String, dynamic>{
      'transactionState': const SKTransactionStatusConverter()
          .toJson(instance.transactionState),
      'payment': instance.payment,
      'originalTransaction': instance.originalTransaction,
      'transactionTimeStamp': instance.transactionTimeStamp,
      'transactionIdentifier': instance.transactionIdentifier,
      'transactionReceipt': instance.transactionReceipt,
      'error': instance.error,
    };
