part of 'enum_converters.dart';

/// 交易状态枚举Map
const _$SKPaymentTransactionStateWrapperEnumMap = {
  SKPaymentTransactionStateWrapper.purchasing: 0,
  SKPaymentTransactionStateWrapper.purchased: 1,
  SKPaymentTransactionStateWrapper.failed: 2,
  SKPaymentTransactionStateWrapper.restored: 3,
  SKPaymentTransactionStateWrapper.deferred: 4,
};

/// int枚举转换成定义的枚举值
T? _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries.singleWhere((e) => e.value == source).key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T? _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T? unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

// Map<String, dynamic> _$_SerializedEnumsToJson(_SerializedEnums instance) =>
//     <String, dynamic>{
//       'response': _$SKPaymentTransactionStateWrapperEnumMap[instance.response],
//     };
//
// _SerializedEnums _$_SerializedEnumsFromJson(Map json) {
//   return _SerializedEnums()
//     ..response = _$enumDecode(
//         _$SKPaymentTransactionStateWrapperEnumMap, json['response']);
// }
