import 'package:whatshoppy2/services/api_client.dart';
import 'package:whatshoppy2/services/local_storage_service.dart';

class ClientService {
  static Future<String> _uid() => LocalStorageService.getCurrentUserId();

  static Future<List<Map<String, dynamic>>> getClients() async {
    final uid = await _uid();
    final response = await ApiClient.get(
      '/api/clients',
      queryParams: {'user_id': uid},
    );
    final raw = response['data'];
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(raw as List);
  }
}
