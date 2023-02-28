extension ListExtension<T> on List<T> {
  bool get hasValue => this != null && isNotEmpty;

  bool get noValue => this == null || isEmpty;

  Map<K, T> toMapWithKey<K>(K Function(T) key) {
    final result = <K, T>{};
    forEach((element) {
      result[key(element)] = element;
    });
    return result;
  }

  bool isEqualTo(List<T> other) {
    if (this == null) {
      return other == null;
    } else if (isEmpty) {
      return other?.isEmpty ?? false;
    } else {
      if (other.noValue) return false;
      if (length == other.length) {
        for (var i = 0; i < length; i++) {
          if (this[i] != other[i]) {
            return false;
          }
        }
        return true;
      } else {
        return false;
      }
    }
  }
}
