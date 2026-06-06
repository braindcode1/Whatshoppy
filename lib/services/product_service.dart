import 'package:whatshoppy2/services/api_client.dart';
import 'package:whatshoppy2/services/local_storage_service.dart';

class ProductService {
  static Future<String> _uid() => LocalStorageService.getCurrentUserId();

  // GET /api/products?user_id=...
  static Future<List<Map<String, dynamic>>> getProducts() async {
    final uid = await _uid();
    final response = await ApiClient.get(
      '/api/products',
      queryParams: {'user_id': uid},
    );
    final raw = response['data'];
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(raw as List);
  }

  // POST /api/products
  static Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> data,
  ) async {
    final uid = await _uid();
    final payload = Map<String, dynamic>.from(data);
    payload['user_id'] = uid;
    final response = await ApiClient.post('/api/products', payload);
    return Map<String, dynamic>.from(
      response['data'] as Map<String, dynamic>? ?? {},
    );
  }

  // PUT /api/products/:id
  static Future<Map<String, dynamic>> updateProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    final uid = await _uid();
    final payload = Map<String, dynamic>.from(data);
    payload['user_id'] = uid;
    final response = await ApiClient.put('/api/products/$id', payload);
    return Map<String, dynamic>.from(
      response['data'] as Map<String, dynamic>? ?? {},
    );
  }

  // DELETE /api/products/:id
  static Future<void> deleteProduct(String id) async {
    final uid = await _uid();
    await ApiClient.delete('/api/products/$id', body: {'user_id': uid});
  }
}
