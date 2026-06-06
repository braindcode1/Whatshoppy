import 'package:whatshoppy2/services/api_client.dart';

class PricePredictionInput {
  final String brand;
  final String category;
  final String color;
  final String size;
  final String material;
  final String gender;
  final String season;
  final String brandTier;

  const PricePredictionInput({
    required this.brand,
    required this.category,
    required this.color,
    required this.size,
    required this.material,
    required this.gender,
    required this.season,
    required this.brandTier,
  });

  Map<String, dynamic> toJson() {
    return {
      'Brand': brand,
      'Category': category,
      'Color': color,
      'Size': size,
      'Material': material,
      'Gender': gender,
      'Season': season,
      'Brand_Tier': brandTier,
    };
  }
}

class PricePredictionService {
  static Future<double> predictBestPrice(PricePredictionInput input) async {
    try {
      final response = await ApiClient.post(
        '/api/ai/predict-price',
        input.toJson(),
      );
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final rawPrice = data['recommended_price'] ?? response['recommended_price'];

      if (rawPrice is num) {
        return rawPrice.toDouble();
      }

      throw const ApiException('The server returned an invalid price.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to predict price: $e');
    }
  }
}
