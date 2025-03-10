import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // Save auth data
  Future<void> saveAuthData({
    required String? token,
    required String? userId,
    required String? email,
  }) async {
    if (token != null) await _prefs.setString(_authTokenKey, token);
    if (userId != null) await _prefs.setString(_userIdKey, userId);
    if (email != null) await _prefs.setString(_userEmailKey, email);
  }

  // Clear auth data on logout
  Future<void> clearAuthData() async {
    await _prefs.remove(_authTokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userEmailKey);
  }

  // Get stored auth token
  String? getAuthToken() => _prefs.getString(_authTokenKey);

  // Get stored user ID
  String? getUserId() => _prefs.getString(_userIdKey);

  // Get stored email
  String? getUserEmail() => _prefs.getString(_userEmailKey);

  // Check if user is logged in
  bool isLoggedIn() => getAuthToken() != null;
}
