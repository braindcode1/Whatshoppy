import 'dart:async';

import 'package:flutter/material.dart';
import 'package:whatshoppy2/services/product_service.dart';
import 'package:whatshoppy2/services/category_service.dart';
import 'package:whatshoppy2/theme/app_theme.dart';
import 'package:whatshoppy2/screens/price_prediction_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;

  String _selectedCategory = 'General';
  bool _isEditing = false;
  bool _isLoading = false;
  double? _predictedPrice;

  List<String> _categories = [
    'General',
    'Clothes',
    'Accessories',
    'Beauty',
    'Pantry',
    'Home',
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.product['name'] ?? '');
    _skuController = TextEditingController(text: widget.product['sku'] ?? '');
    _priceController = TextEditingController(
      text: (widget.product['price'] ?? '0')
          .toString()
          .replaceAll(' TND', '')
          .replaceAll('TND', '')
          .replaceAll(' €', '')
          .replaceAll('€', ''),
    );
    _stockController = TextEditingController(
      text: (widget.product['stock'] ?? 0).toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.product['description'] ?? '',
    );

    final productCategory =
        (widget.product['category'] ?? 'General').toString();

    _selectedCategory =
        _categories.contains(productCategory) ? productCategory : 'General';
    
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryService.fetchCategories();
      if (mounted) {
        setState(() {
          if (cats.isNotEmpty) {
            _categories = cats;
            final productCategory = (widget.product['category'] ?? 'General').toString();
            if (!_categories.contains(productCategory)) {
              _categories.add(productCategory);
            }
            _selectedCategory = productCategory;
          }
        });
      }
    } catch (e) {
      // Keep fallbacks
    }
  }

  Future<void> _addCategory() async {
    final catController = TextEditingController();
    final newCat = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(hintText: 'Category Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, catController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newCat != null && newCat.isNotEmpty) {
      try {
        final added = await CategoryService.addCategory(newCat);
        setState(() {
          if (!_categories.contains(added)) {
            _categories.add(added);
          }
          _selectedCategory = added;
        });
      } catch (e) {
        _showSnackBar('Failed to add category', isError: true);
      }
    }
  }

  Color _stockColor(int stock) {
    if (stock == 0) return AppTheme.cancelledColor;
    if (stock <= 10) return AppTheme.pendingColor;
    return AppTheme.primaryGreen;
  }

  String _stockText(int stock) {
    if (stock == 0) return 'Out of stock';
    if (stock <= 10) return 'Low stock';
    return 'In stock';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.cancelledColor : AppTheme.darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final productId = widget.product['id'];
    if (productId == null) {
      _showSnackBar('Product ID missing, cannot update', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final updated = await ProductService.updateProduct(
        productId.toString(),
        {
          'name': _nameController.text.trim(),
          'sku': _skuController.text.trim(),
          'category': _selectedCategory,
          'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
          'stock': int.tryParse(_stockController.text.trim()) ?? 0,
          'description': _descriptionController.text.trim(),
        },
      );

      if (!mounted) return;

      final priceVal = updated['price'];
      final updatedProduct = {
        ...widget.product,
        ...updated,
        'price': priceVal is num
            ? '${priceVal.toStringAsFixed(2)} €'
            : '${_priceController.text.trim()} €',
      };

      Navigator.pop(context, updatedProduct);
    } on TimeoutException {
      if (!mounted) return;
      _showSnackBar('Request timeout', isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', 'Failed to update product'),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${widget.product['name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.cancelledColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final productId = widget.product['id'];
    if (productId == null) {
      _showSnackBar('Product ID missing, cannot delete', isError: true);
      return;
    }

    try {
      await ProductService.deleteProduct(productId.toString());

      if (!mounted) return;
      Navigator.pop(context, {'deleted': true});
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', 'Failed to delete product'),
        isError: true,
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final isEdit = _isEditing;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryGreen),
      filled: true,
      fillColor: isEdit ? AppTheme.white : AppTheme.lightBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isEdit
              ? AppTheme.primaryGreen.withValues(alpha: 0.25)
              : AppTheme.borderGrey,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isEdit
              ? AppTheme.primaryGreen.withValues(alpha: 0.25)
              : AppTheme.borderGrey,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.dividerColor),
      ),
    );
  }

  Future<void> _openPricePrediction() async {
    final predictedPrice = await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => const PricePredictionScreen(),
      ),
    );
    if (predictedPrice != null && mounted) {
      setState(() => _predictedPrice = predictedPrice);
    }
  }

  void _applyPredictedPrice() {
    if (_predictedPrice == null) return;
    setState(() {
      _priceController.text = _predictedPrice!.toStringAsFixed(2);
      _predictedPrice = null;
    });
    _showSnackBar('Price applied to field');
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGreen.withValues(alpha: 0.18),
                AppTheme.primaryGreen.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.greyText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _premiumCard({
    required Widget child,
    bool highlight = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlight
              ? AppTheme.primaryGreen.withValues(alpha: 0.35)
              : AppTheme.borderGrey,
          width: highlight ? 1.5 : 1,
        ),
        boxShadow: highlight ? AppTheme.greenShadow : AppTheme.subtleShadow,
      ),
      child: child,
    );
  }

  Widget _buildPredictPriceButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _openPricePrediction,
        icon: const Icon(Icons.price_check_rounded, size: 16),
        label: const Text('Predict Best Price'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryGreen,
          side: const BorderSide(
            color: AppTheme.primaryGreen,
            width: 1.4,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPredictedPriceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.12),
            AppTheme.primaryGreen.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Recommended Price',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGreen,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${_predictedPrice!.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _predictedPrice = null),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppTheme.greyText,
                tooltip: 'Dismiss',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applyPredictedPrice,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Put Price in Price Field'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditModeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.14),
            AppTheme.accentGreen.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editing Mode',
                  style: TextStyle(
                    color: AppTheme.darkGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Update details below and save your changes',
                  style: TextStyle(
                    color: AppTheme.greyText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.10),
              color.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.greyText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stock = int.tryParse(_stockController.text) ?? 0;
    final stockColor = _stockColor(stock);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(_isEditing ? 'Edit Product' : 'Product Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => setState(() => _isEditing = true),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _deleteProduct,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen,
                    AppTheme.primaryGreenDark,
                    AppTheme.darkGreen.withValues(alpha: 0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
                boxShadow: AppTheme.greenShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: AppTheme.cardShadow,
                      border: Border.all(
                        color: AppTheme.white.withValues(alpha: 0.5),
                        width: 3,
                      ),
                    ),
                    child: widget.product['image'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(31),
                            child: Image.asset(
                              widget.product['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.inventory_2_rounded,
                                size: 70,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_rounded,
                            size: 70,
                            color: AppTheme.primaryGreen,
                          ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _nameController.text.isEmpty
                        ? 'Unnamed Product'
                        : _nameController.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_skuController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'SKU: ${_skuController.text}',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Text(
                      _stockText(stock),
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_isEditing) ...[
                      _buildEditModeBanner(),
                      const SizedBox(height: 20),
                    ],

                    Row(
                      children: [
                        _infoCard(
                          icon: Icons.payments_rounded,
                          title: 'Price',
                          value: '${_priceController.text} €',
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 14),
                        _infoCard(
                          icon: Icons.inventory_rounded,
                          title: 'Stock',
                          value: '$stock units',
                          color: stockColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _premiumCard(
                      highlight: _isEditing,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            icon: Icons.inventory_2_outlined,
                            title: 'Product Information',
                            subtitle: 'Name, SKU, category & description',
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _nameController,
                            enabled: _isEditing,
                            decoration: _inputDecoration(
                              'Product Name',
                              Icons.inventory_2_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter product name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _skuController,
                            enabled: _isEditing,
                            decoration: _inputDecoration(
                              'SKU',
                              Icons.qr_code_2_rounded,
                            ),
                          ),

                          const SizedBox(height: 14),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _categories.contains(_selectedCategory)
                                      ? _selectedCategory
                                      : 'General',
                                  onChanged: _isEditing
                                      ? (value) {
                                          setState(() {
                                            _selectedCategory = value!;
                                          });
                                        }
                                      : null,
                                  decoration: _inputDecoration(
                                    'Category',
                                    Icons.category_rounded,
                                  ),
                                  items: _categories.toSet().map((category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                                ),
                              ),
                              if (_isEditing) ...[
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.add),
                                    color: AppTheme.primaryGreen,
                                    onPressed: _addCategory,
                                    tooltip: 'Add new category',
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _descriptionController,
                            enabled: _isEditing,
                            maxLines: 4,
                            decoration: _inputDecoration(
                              'Description',
                              Icons.description_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _premiumCard(
                      highlight: _isEditing,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            icon: Icons.payments_outlined,
                            title: 'Pricing & Stock',
                            subtitle: 'Set price, stock level & AI suggestions',
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _priceController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                              'Price (€)',
                              Icons.payments_outlined,
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Enter price';
                              }
                              if (double.tryParse(value.trim()) == null) {
                                return 'Invalid price';
                              }
                              return null;
                            },
                          ),
                          if (_isEditing) ...[
                            const SizedBox(height: 10),
                            _buildPredictPriceButton(),
                            if (_predictedPrice != null) ...[
                              const SizedBox(height: 12),
                              _buildPredictedPriceCard(),
                            ],
                          ],
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _stockController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                              'Stock',
                              Icons.store_rounded,
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Enter stock';
                              }
                              if (int.tryParse(value.trim()) == null) {
                                return 'Invalid stock';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    if (_isEditing)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppTheme.borderGrey),
                          boxShadow: AppTheme.subtleShadow,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isEditing = false;
                                          _predictedPrice = null;
                                          _nameController.text = widget.product['name'] ?? '';
                                          _skuController.text = widget.product['sku'] ?? '';
                                          _priceController.text = (widget.product['price'] ?? '0')
                                              .toString()
                                              .replaceAll(' TND', '')
                                              .replaceAll('TND', '')
                                              .replaceAll(' €', '')
                                              .replaceAll('€', '');
                                          _stockController.text = (widget.product['stock'] ?? 0).toString();
                                          _descriptionController.text = widget.product['description'] ?? '';
                                          _selectedCategory = widget.product['category'] ?? 'General';
                                        });
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textDark,
                                  side: const BorderSide(
                                    color: AppTheme.borderGrey,
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_circle_rounded, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text(
                            'Edit Product',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}