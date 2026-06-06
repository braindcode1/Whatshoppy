import 'package:whatshoppy2/services/api_client.dart';
import 'package:whatshoppy2/services/local_storage_service.dart';

class MessageService {
  static Future<String> _uid() => LocalStorageService.getCurrentUserId();

  // GET /api/messages?user_id=...
  static Future<List<Map<String, dynamic>>> getInboxItems() async {
    final uid = await _uid();
    final response = await ApiClient.get(
      '/api/messages',
      queryParams: {'user_id': uid},
    );
    final raw = response['data'];
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(raw as List);
  }

  // GET /api/messages/:id?user_id=...
  static Future<List<Map<String, dynamic>>> getMessages(
    String conversationId,
  ) async {
    final uid = await _uid();
    final response = await ApiClient.get(
      '/api/messages/$conversationId',
      queryParams: {'user_id': uid},
    );
    final raw = response['data'];
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(raw as List);
  }

  // POST /api/messages/:id
  static Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final uid = await _uid();
    final response = await ApiClient.post(
      '/api/messages/$conversationId',
      {'user_id': uid, 'text': text},
    );
    return Map<String, dynamic>.from(
      response['data'] as Map<String, dynamic>? ?? {},
    );
  }

  // PUT /api/messages/:id/read — Mark conversation as read
  static Future<void> markAsRead(String conversationId) async {
    final uid = await _uid();
    try {
      await ApiClient.put(
        '/api/messages/$conversationId/read',
        {'user_id': uid},
      );
    } catch (_) {
      // Non-critical — don't block the UI
    }
  }

  // POST /api/messages — Create a new inbox item
  static Future<Map<String, dynamic>> createInboxItem(
    Map<String, dynamic> payload,
  ) async {
    final uid = await _uid();
    payload['user_id'] = uid;
    final response = await ApiClient.post('/api/messages', payload);
    return Map<String, dynamic>.from(
      response['data'] as Map<String, dynamic>? ?? {},
    );
  }
}
