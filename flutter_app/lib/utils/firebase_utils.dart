/// Utility functions for Firebase operations
class FirebaseUtils {
  /// Validates if a string is a valid Firebase key
  /// Firebase keys cannot contain: . # $ [ ] /
  /// and cannot be empty
  static bool isValidFirebaseKey(String key) {
    if (key.isEmpty) return false;
    return !key.contains(RegExp(r'[.#$\[\]/]'));
  }

  /// Filters a map to only include entries with valid Firebase keys
  /// Returns a new map with only valid keys and logs warnings for invalid ones
  static Map<String, T> filterValidKeys<T>(Map<String, T> map, String context) {
    final validMap = <String, T>{};
    final invalidKeys = <String>[];
    
    for (final entry in map.entries) {
      if (isValidFirebaseKey(entry.key)) {
        validMap[entry.key] = entry.value;
      } else {
        invalidKeys.add(entry.key);
      }
    }
    
    if (invalidKeys.isNotEmpty) {
      print('Warning: Found invalid Firebase keys in $context: ${invalidKeys.join(", ")}');
    }
    
    return validMap;
  }

  /// Validates a Firebase key and throws an exception if invalid
  /// Use this when you want to fail fast on invalid keys
  static void validateFirebaseKey(String key, String context) {
    if (!isValidFirebaseKey(key)) {
      throw ArgumentError(
        'Invalid Firebase key in $context: "$key"\n'
        'Firebase keys cannot contain . # \$ [ ] / or be empty.'
      );
    }
  }
} 