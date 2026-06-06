import 'dart:async';

import 'package:flutter/material.dart';
import 'package:whatshoppy2/services/product_service.dart';

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

  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color whatsappDarkGreen = Color(0xFF075E54);
  static const Color whatsappLightGreen = Color(0xFFE7F8EF);
  static const Color background = Color(0xFFF6F7F9);
  static const Color textGrey = Color(0xFF6B7280);

  final List<String> _categories = [
    'General',
    'Formation',
    'Electronics',
    'Clothes',
    'Clothing',
    'Food',
    'Handmade',
    'Books',
    'Home',
    'Sports',
    'Beauty',
    'Other',
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

  Color _stockColor(int stock) {
    if (stock == 0) return const Color(0xFFE53935);
    if (stock <= 10) return const Color(0xFFFF9800);
    return whatsappGreen;
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
        backgroundColor: isError ? Colors.redAccent : whatsappDarkGreen,
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
              backgroundColor: Colors.redAccent,
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
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: whatsappDarkGreen),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: whatsappGreen, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
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
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: whatsappDarkGreen,
        foregroundColor: Colors.white,
        title: Text(_isEditing ? 'Edit Product' : 'Product Details'),
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
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
              decoration: const BoxDecoration(
                color: whatsappDarkGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 145,
                    height: 145,
                    decoration: BoxDecoration(
                      color: whatsappLightGreen,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: widget.product['image'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              widget.product['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.inventory_2_rounded,
                                size: 70,
                                color: whatsappDarkGreen,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_rounded,
                            size: 70,
                            color: whatsappDarkGreen,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nameController.text.isEmpty
                        ? 'Unnamed Product'
                        : _nameController.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: stockColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      _stockText(stock),
                      style: TextStyle(
                        color: stockColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        _infoCard(
                          icon: Icons.payments_rounded,
                          title: 'Price',
                          value: '${_priceController.text} €',
                          color: whatsappGreen,
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

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Product Information',
                            style: TextStyle(
                              color: whatsappDarkGreen,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),

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

                          DropdownButtonFormField<String>(
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

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pricing & Stock',
                            style: TextStyle(
                              color: whatsappDarkGreen,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  enabled: _isEditing,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(
                                    'Price',
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
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
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
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    if (_isEditing)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _isEditing = false;
                                      });
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: whatsappDarkGreen,
                                side: const BorderSide(
                                  color: whatsappDarkGreen,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: whatsappGreen,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
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
                                  : const Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ],
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
                            backgroundColor: whatsappGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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