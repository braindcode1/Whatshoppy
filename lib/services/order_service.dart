import 'package:whatshoppy2/services/api_client.dart';
import 'package:whatshoppy2/services/local_storage_service.dart';

class OrderService {
  static Future<String> _uid() => LocalStorageService.getCurrentUserId();

  // GET /api/orders?user_id=...
  static Future<List<Map<String, dynamic>>> getOrders() async {
    final uid = await _uid();
    final response = await ApiClient.get(
      '/api/orders',
      queryParams: {'user_id': uid},
    );
    final raw = response['data'];
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(raw as List);
  }

  // PUT /api/orders/:id/status
  static Future<Map<String, dynamic>> updateOrderStatus(
    String id,
    String status,
  ) async {
    final uid = await _uid();
    final response = await ApiClient.put(
      '/api/orders/$id/status',
      {'user_id': uid, 'status': status},
    );
    return Map<String, dynamic>.from(
      response['data'] as Map<String, dynamic>? ?? {},
    );
  }

  // GET /api/orders/:id/items?user_id=...
  static Future<List<Map<String, dynamic>>> getOrderLineItems(
    String orderId,
  ) async {
    final uid = await _uid();
    final response = await ApiClient.get(
      '/api/orders/$orderId/items',
      queryParams: {'user_id': uid},
    );
    final raw = response['data'];
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(raw as List);
  }
}
