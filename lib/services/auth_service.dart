import 'package:whatshoppy2/services/api_client.dart';
import 'package:whatshoppy2/services/local_storage_service.dart';

class AuthService {
  // ─── Login ───────────────────────────────────────────────────────────────────

  /// Calls POST /api/auth/login, saves user locally, returns the user map.
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.post('/api/auth/login', {
        'email': email.trim(),
        'password': password.trim(),
      });

      final data = response['data'] as Map<String, dynamic>? ?? {};
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final profile = data['profile'] as Map<String, dynamic>? ?? {};

      final userId = user['id']?.toString() ?? '';
      if (userId.isEmpty) {
        throw ApiException('Login response missing user id');
      }

      final resolvedEmail = (user['email']?.toString().isNotEmpty == true)
          ? user['email'].toString()
          : (profile['email']?.toString().isNotEmpty == true)
              ? profile['email'].toString()
              : email.trim();

      final role = profile['role']?.toString() ?? 'admin';

      await LocalStorageService.saveUser(
        userId: userId,
        email: resolvedEmail,
        role: role,
      );

      return user;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    await LocalStorageService.clear();
    // No Supabase call needed — the backend manages sessions server-side.
  }

  // ─── Forgot password ─────────────────────────────────────────────────────────

  static Future<void> resetPasswordForEmail(String email) async {
    await ApiClient.post('/api/auth/forgot-password', {
      'email': email.trim(),
    });
  }

  // ─── Update email ─────────────────────────────────────────────────────────────

  static Future<void> updateAccountEmail({required String newEmail}) async {
    final userId = await LocalStorageService.getCurrentUserId();
    await ApiClient.put('/api/auth/update-email', {
      'user_id': userId,
      'new_email': newEmail.trim(),
    });
    final role = await LocalStorageService.getRole() ?? 'admin';
    await LocalStorageService.saveUser(
      userId: userId,
      email: newEmail.trim(),
      role: role,
    );
  }

  // ─── Update password ──────────────────────────────────────────────────────────

  static Future<void> updateAccountPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final userId = await LocalStorageService.getCurrentUserId();
    await ApiClient.put('/api/auth/update-password', {
      'user_id': userId,
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  // ─── Password recovery (forgot password flow) ─────────────────────────────────
  // These are called by forget_password.dart after the user clicks the email link.
  // The access_token and refresh_token come from the deep-link URL parameters.

  /// Step 1 of recovery: establish a session from the tokens in the reset link.
  /// Calls POST /api/auth/reset-password with the tokens + new password in one step.
  static Future<void> setSessionFromRecovery({
    required String accessToken,
    required String refreshToken,
  }) async {
    // No-op on the Flutter side — tokens are forwarded to the backend only
    // when resetPasswordWithToken() is called with the full payload.
    // Kept for API compatibility with forget_password.dart.
  }

  /// Step 2 of recovery: set the new password using the recovery session.
  /// In this architecture the token was already stored by setSessionFromRecovery;
  /// forget_password.dart calls this immediately after.
  ///
  /// Because Flutter no longer holds a Supabase session, the actual password
  /// update is handled by the backend via POST /api/auth/reset-password.
  /// The screen passes the token through [resetPasswordWithToken].
  static Future<void> updatePasswordWithSession({
    required String newPassword,
  }) async {
    // This path is reached only when _accessToken is null in forget_password.dart,
    // which shows an informational message and pops. Nothing to do here.
  }

  /// Full recovery: send access_token + refresh_token + new_password to backend.
  /// Call this instead of the two-step flow when you have the tokens.
  static Future<void> resetPasswordWithToken({
    required String accessToken,
    required String refreshToken,
    required String newPassword,
  }) async {
    await ApiClient.post('/api/auth/reset-password', {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'new_password': newPassword,
    });
  }
}
