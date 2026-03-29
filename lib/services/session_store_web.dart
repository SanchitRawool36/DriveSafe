import 'package:web/web.dart' as web;

Future<String?> getString(String key) async {
  return web.window.sessionStorage.getItem(key);
}

Future<void> setString(String key, String value) async {
  web.window.sessionStorage.setItem(key, value);
}

Future<bool?> getBool(String key) async {
  final value = web.window.sessionStorage.getItem(key);
  if (value == null) {
    return null;
  }
  return value == 'true';
}

Future<void> setBool(String key, bool value) async {
  web.window.sessionStorage.setItem(key, value.toString());
}

Future<void> remove(String key) async {
  web.window.sessionStorage.removeItem(key);
}