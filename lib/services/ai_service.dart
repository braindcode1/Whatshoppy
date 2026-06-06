import 'dart:convert';
import 'dart:io';

import 'package:whatshoppy2/services/api_client.dart';

class AiProductResult {
  final String name;
  final String description;
  final String category;
  final List<String> tags; ///Liste de mots-clés Exemple ["blue","denim","casual"]
  final double? estimatedPrice;

  const AiProductResult({
    required this.name,
    required this.description,
    required this.category,
    required this.tags,
    this.estimatedPrice,
  });
}

/// AI service connected to local Python FastAPI model.
/// Uses backend Node.js API through ApiClient.
/// Works with:
/// - USB adb reverse
/// - Real Android phone
/// - Emulator
class AiService {
  static Future<AiProductResult> analyzeProductImage(
    File imageFile,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();

      final base64Image = base64Encode(bytes);

      final mimeType = _detectMimeType(
        imageFile.path,
      );

      final response = await ApiClient.post(
        '/api/ai/analyze-image',
        {
          'image_base64': base64Image,
          'mime_type': mimeType,
        },
      );

      final data =
          response['data'] as Map<String, dynamic>? ??
              {};

      final rawTags = data['tags'];

      final tags = rawTags is List
          ? rawTags
              .map(
                (t) => t.toString().trim(),
              )
              .toList()
          : <String>[];

      double? price;

      final rawPrice =
          data['estimated_price'];

      if (rawPrice is num) {
        price = rawPrice.toDouble();
      }

      return AiProductResult(
        name:
            (data['name'] as String? ?? '')
                .trim(),

        description:
            (data['description']
                        as String? ??
                    '')
                .trim(),

        category:
            (data['category']
                        as String? ??
                    'General')
                .trim(),

        tags: tags,

        estimatedPrice: price,
      );
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        'Cannot reach AI backend.\n'
        'Make sure:\n'
        '1. node server.js is running\n'
        '2. Python AI model is running on port 8000\n'
        '3. adb reverse is active\n'
        '4. Phone is connected with USB debugging',
      );
    } catch (e) {
      throw ApiException(
        'Failed to analyze image: $e',
      );
    }
  }

  static String _detectMimeType(
    String path,
  ) {
    final lower = path.toLowerCase();

    if (lower.endsWith('.png')) {
      return 'image/png';
    }

    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }

    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }

    return 'image/jpeg';
  }
}

class AiServiceException
    extends ApiException {
  const AiServiceException(
    super.message,
  );
}