// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sk_payment_queue_wrapper.dart';

// **************************************************************************
// JsonSerializableGenerator
// 用来做序列化
// **************************************************************************

/// 错误信息Map 转为 实体对象
SKError _$SKErrorFromJson(Map json) {
  return SKError(
    code: json['code'] as int?,
    domain: json['domain'] as String?,
    userInfo: (json['userInfo'] as Map?)?.map(
      (k, e) => MapEntry(k as String, e),
    ),
  );
}

/// 错误信息实体对象 转换为 map
Map<String, dynamic> _$SKErrorToJson(SKError instance) => <String, dynamic>{
      'code': instance.code,
      'domain': instance.domain,
      'userInfo': instance.userInfo,
    };

/// 支付Map参数 转换为实体对象
SKPaymentWrapper _$SKPaymentWrapperFromJson(Map json) {
  return SKPaymentWrapper(
    productIdentifier: json['productIdentifier'] as String?,
    applicationUsername: json['applicationUsername'] as String?,
    requestData: json['requestData'] as String?,
    quantity: json['quantity'] as int?,
    simulatesAskToBuyInSandbox: json['simulatesAskToBuyInSandbox'] as bool?,
  );
}

/// 支付实体对象 转换为 Map
Map<String, dynamic> _$SKPaymentWrapperToJson(SKPaymentWrapper instance) =>
    <String, dynamic>{
      'productIdentifier': instance.productIdentifier,
      'applicationUsername': instance.applicationUsername,
      'requestData': instance.requestData,
      'quantity': instance.quantity,
      'simulatesAskToBuyInSandbox': instance.simulatesAskToBuyInSandbox,
    };
