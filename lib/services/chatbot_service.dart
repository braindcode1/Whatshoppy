import 'package:whatshoppy2/services/api_client.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toHistoryJson() => {
        'role': isUser ? 'user' : 'model',
        'text': text,
      };
}

class ChatbotService {
  /// Sends a message to the chatbot and returns the AI reply.
  static Future<String> sendMessage(
    String message,
    List<ChatMessage> history,
  ) async {
    try {
      final response = await ApiClient.post('/api/rag/ask-navigation', {
        'question': message,
      });

      return response['answer']?.toString() ??
          'Sorry, I could not generate a response.';
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to connect to chatbot: $e');
    }
  }
}
