import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getString(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

Future<void> setString(String key, String value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, value);
}

Future<bool?> getBool(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(key);
}

Future<void> setBool(String key, bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(key, value);
}

Future<void> remove(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}