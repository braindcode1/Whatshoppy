import 'package:flutter/material.dart';

import 'package:whatshoppy2/services/api_client.dart';
import 'package:whatshoppy2/services/price_prediction_service.dart';
import 'package:whatshoppy2/theme/app_theme.dart';

class PricePredictionScreen extends StatefulWidget {
  const PricePredictionScreen({super.key});

  @override
  State<PricePredictionScreen> createState() => _PricePredictionScreenState();
}

class _PricePredictionScreenState extends State<PricePredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  String _brand = _brands.first;
  String _category = _categories.first;
  String _color = _colors.first;
  String _size = _sizes.first;
  String _material = _materials.first;
  String _gender = _genders.first;
  String _season = _seasons.first;
  String _brandTier = _brandTiers.first;

  bool _isLoading = false;
  double? _recommendedPrice;
  String? _error;

  static const List<String> _brands = [
    'Nike',
    'Adidas',
    'Zara',
    'H&M',
    'Gucci',
    'Prada',
    'Levi\'s',
    'Puma',
    'Uniqlo',
    'Other',
  ];

  static const List<String> _categories = [
    'General',
    'Blazer',
    'Pants',
    'Shorts',
    'Dress',
    'Hoodie',
    'Jacket',
    'Denim Jacket',
    'Sports Jacket',
    'Jeans',
    'T-Shirt',
    'Shirt',
    'Coat',
    'Polo Shirt',
    'Skirt',
    'Sweater',
    'Other',
  ];

  static const List<String> _colors = [
    'Black',
    'White',
    'Blue',
    'Red',
    'Green',
    'Grey',
    'Brown',
    'Pink',
    'Beige',
  ];

  static const List<String> _sizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'One Size',
  ];

  static const List<String> _materials = [
    'Cotton',
    'Leather',
    'Denim',
    'Polyester',
    'Wool',
    'Silk',
    'Linen',
    'Synthetic',
  ];

  static const List<String> _genders = [
    'Unisex',
    'Men',
    'Women',
    'Kids',
  ];

  static const List<String> _seasons = [
    'All Season',
    'Spring',
    'Summer',
    'Fall',
    'Winter',
  ];

  static const List<String> _brandTiers = [
    'Premium',
    'Luxury',
    'Mid-range',
    'Budget',
  ];

  Future<void> _predictPrice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _recommendedPrice = null;
    });

    try {
      final price = await PricePredictionService.predictBestPrice(
        PricePredictionInput(
          brand: _brand,
          category: _category,
          color: _color,
          size: _size,
          material: _material,
          gender: _gender,
          season: _season,
          brandTier: _brandTier,
        ),
      );

      if (!mounted) return;
      setState(() {
        _recommendedPrice = price;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to predict price: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _recommendedPrice);
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightBackground,
        appBar: AppBar(
          title: const Text('Predict Best Price'),
          backgroundColor: AppTheme.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, _recommendedPrice);
            },
          ),
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 18),
                _buildFormCard(),
                const SizedBox(height: 18),
                if (_error != null) ...[
                  _buildError(),
                  const SizedBox(height: 14),
                ],
                if (_recommendedPrice != null) ...[
                  _buildResult(context),
                  const SizedBox(height: 14),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _predictPrice,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.white,
                            ),
                          )
                        : const Icon(Icons.trending_up_rounded, size: 20),
                    label: Text(
                      _isLoading
                          ? 'Generating price...'
                          : 'Generate Best Price for More Sales',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.price_check_rounded,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart clothing price',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose product details and let the local model recommend a selling price.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        children: [
          _dropdown(
            label: 'Brand',
            value: _brand,
            values: _brands,
            icon: Icons.local_offer_outlined,
            onChanged: (value) => setState(() => _brand = value),
          ),
          _dropdown(
            label: 'Category',
            value: _category,
            values: _categories,
            icon: Icons.category_outlined,
            onChanged: (value) => setState(() => _category = value),
          ),
          _dropdown(
            label: 'Color',
            value: _color,
            values: _colors,
            icon: Icons.palette_outlined,
            onChanged: (value) => setState(() => _color = value),
          ),
          _dropdown(
            label: 'Size',
            value: _size,
            values: _sizes,
            icon: Icons.straighten_rounded,
            onChanged: (value) => setState(() => _size = value),
          ),
          _dropdown(
            label: 'Material',
            value: _material,
            values: _materials,
            icon: Icons.texture_rounded,
            onChanged: (value) => setState(() => _material = value),
          ),
          _dropdown(
            label: 'Gender',
            value: _gender,
            values: _genders,
            icon: Icons.people_outline_rounded,
            onChanged: (value) => setState(() => _gender = value),
          ),
          _dropdown(
            label: 'Season',
            value: _season,
            values: _seasons,
            icon: Icons.wb_sunny_outlined,
            onChanged: (value) => setState(() => _season = value),
          ),
          _dropdown(
            label: 'Brand_Tier',
            value: _brandTier,
            values: _brandTiers,
            icon: Icons.workspace_premium_outlined,
            onChanged: (value) => setState(() => _brandTier = value),
            showBottomSpacing: false,
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> values,
    required IconData icon,
    required ValueChanged<String> onChanged,
    bool showBottomSpacing = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: showBottomSpacing ? 14 : 0),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
        ),
        items: values
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        validator: (value) =>
            value == null || value.trim().isEmpty ? '$label is required' : null,
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primaryGreen,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Recommended Price: ${_recommendedPrice!.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.darkGreen,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(context, _recommendedPrice);
              },
              icon: const Icon(Icons.check, color: AppTheme.white),
              label: const Text(
                'Apply to Product Price',
                style: TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cancelledColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.cancelledColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.cancelledColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppTheme.cancelledColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
