class Utils {
  static R? getAndConvert<T, R>(dynamic map, List<String> keys, R Function(T) convert) {
    if (keys.isEmpty) {
      return map is T ? convert(map) : null;
    }

    if (map is Map<String, dynamic> && map.containsKey(keys.first)) {
      return getAndConvert(map[keys.first], keys.sublist(1), convert);
    } else {
      return null;
    }
  }

  static T none<T>(T value) {
    return value;
  }

  static T? get<T>(dynamic map, List<String> keys) {
    return getAndConvert<T, T>(map, keys, none<T>);
  }

  static bool has(dynamic map, List<String> keys) {
    return get<dynamic>(map, keys) != null;
  }

  static T getOrDefault<T>(dynamic map, List<String> keys, T def) {
    return get(map, keys) ?? def;
  }
}
