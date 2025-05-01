import 'package:humm_error_handler/src/error_storage/humm_error_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HummErrorStorageImpl extends HummErrorStorage {
  late final SharedPreferences _sharedPreferences;

  HummErrorStorageImpl._(this._sharedPreferences, {required super.storageKey});

  static Future<HummErrorStorageImpl> create({required String storageKey}) async {
    final prefs = await SharedPreferences.getInstance();
    return HummErrorStorageImpl._(
      prefs,
      storageKey: storageKey,
    );
  }

  @override
  Future<String?> getErrorLog() async {
    return _sharedPreferences.getString(storageKey);
  }

  @override
  Future<void> saveErrorLog(String file) async {
    await _sharedPreferences.setString(storageKey, file);
  }
}
