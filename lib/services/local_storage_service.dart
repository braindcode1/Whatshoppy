import 'package:shared_preferences/shared_preferences.dart';

/// Persists the authenticated user's data locally after a successful login.
///
/// This service has NO dependency on Supabase — it is pure SharedPreferences.
/// The user_id stored here is the one returned by the backend after login
/// (which is the Supabase auth.users.id).
class LocalStorageService {
  static const _kUserId = 'userId';
  static const _kEmail  = 'email';
  static const _kRole   = 'role';

  // ─── Write ───────────────────────────────────────────────────────────────────

  static Future<void> saveUser({
    required String userId,
    required String email,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, userId);
    await prefs.setString(_kEmail, email);
    await prefs.setString(_kRole, role);
  }
///pour logout
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kEmail);
    await prefs.remove(_kRole);
  }

  // ─── Read ────────────────────────────────────────────────────────────────────

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserId);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEmail);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRole);
  }

  /// Returns true only if a non-empty userId is stored locally.
  /// Used by [AuthGate] to decide the initial route.
  static Future<bool> isLoggedIn() async {
    final id = await getUserId();
    return id != null && id.isNotEmpty;
  }

  /// Returns the stored userId or throws a clear error if not logged in.
  /// Services call this to get the user_id for backend requests.
  static Future<String> getCurrentUserId() async {
    final id = await getUserId();
    if (id == null || id.isEmpty) {
      throw Exception('Not logged in. Please sign in again.');
    }
    return id;
  }
}
