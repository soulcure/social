T? handleNum<T extends num>(Object value) {
  if (value is String) {
    return (num.parse(value) as T);
  } else if (value is num) {
    dynamic ret;
    if (value is! T) {
      if (T is int) {
        ret = value.toInt();
      } else {
        ret = value.toDouble();
      }
    } else {
      ret = value;
    }
    return ret;
  }
  return null;
}

extension StringExtension on String? {
  bool get hasValue => this != null && this!.isNotEmpty;
  bool get noValue => this == null || this!.isEmpty;
}
