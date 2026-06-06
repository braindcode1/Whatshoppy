import 'package:whatshoppy2/services/api_client.dart';
import 'package:whatshoppy2/services/local_storage_service.dart';

class SettingsService {
  static Future<String> _uid() => LocalStorageService.getCurrentUserId();

  // GET /api/settings/business?user_id=...
  static Future<Map<String, dynamic>> getBusinessSettings() async {
    final uid = await _uid();
    final response = await ApiClient.get(
      '/api/settings/business',
      queryParams: {'user_id': uid},
    );
    return Map<String, dynamic>.from(
      response['data'] as Map<String, dynamic>? ?? {},
    );
  }

  // PUT /api/settings/business
  static Future<Map<String, dynamic>> upsertBusinessSettings({
    required String businessName,
    required String whatsappNumber,
  }) async {
    final uid = await _uid();
    final response = await ApiClient.put('/api/settings/business', {
      'user_id': uid,
      'business_name': businessName.trim(),
      'whatsapp_number': whatsappNumber.trim(),
    });
    return Map<String, dynamic>.from(
      response['data'] as Map<String, dynamic>? ?? {},
    );
  }
}
