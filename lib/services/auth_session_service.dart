import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionService {
  static final AuthSessionService _instance = AuthSessionService._();
  factory AuthSessionService() => _instance;
  AuthSessionService._();

  static const String _kCurrentUserId = 'current_user_id';

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kCurrentUserId);
  }

  Future<void> setCurrentUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCurrentUserId, userId);
  }

  Future<void> clearCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrentUserId);
  }
}