import 'session_store_stub.dart'
    if (dart.library.html) 'session_store_web.dart' as session_store_impl;

class SessionStore {
  static Future<String?> getString(String key) => session_store_impl.getString(key);

  static Future<void> setString(String key, String value) => session_store_impl.setString(key, value);

  static Future<bool?> getBool(String key) => session_store_impl.getBool(key);

  static Future<void> setBool(String key, bool value) => session_store_impl.setBool(key, value);

  static Future<void> remove(String key) => session_store_impl.remove(key);
}