import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:whatshoppy2/services/ai_service.dart';
import 'package:whatshoppy2/services/api_client.dart';
import 'package:whatshoppy2/services/product_service.dart';
import 'package:whatshoppy2/services/category_service.dart';

import 'package:whatshoppy2/screens/price_prediction_screen.dart';
import 'package:whatshoppy2/theme/app_theme.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  String _selectedCategory = 'General';
  bool _isLoading = false;
  bool _isAnalyzing = false;
  File? _selectedImage;
  String? _aiError;
  double? _predictedPrice;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryService.fetchCategories();
      if (mounted) {
        setState(() {
          if (cats.isNotEmpty) {
            _categories = cats;
            if (!_categories.contains(_selectedCategory)) {
              _selectedCategory = _categories.first;
            }
          }
        });
      }
    } catch (e) {
      // Ignore fallback
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

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Image Picker ────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await _showImageSourceDialog();
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _aiError = null;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Select Image Source',
                style: Theme.of(
                  ctx,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            _sourceOption(
              ctx,
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              subtitle: 'Use your camera',
              color: AppTheme.processingColor,
              source: ImageSource.camera,
            ),
            const SizedBox(height: 8),
            _sourceOption(
              ctx,
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              subtitle: 'Pick an existing photo',
              color: AppTheme.primaryGreen,
              source: ImageSource.gallery,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sourceOption(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required ImageSource source,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.pop(ctx, source),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(subtitle, style: Theme.of(ctx).textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.greyText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── AI Analysis ─────────────────────────────────────────────────────────────
  Future<void> _analyzeWithAI() async {
    if (_selectedImage == null) {
      _showSnackBar('Please select an image first', isError: true);
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _aiError = null;
    });

    try {
      final prediction = await AiService.analyzeProductImage(_selectedImage!);

      if (!mounted) return;

      final predictedCategory = prediction.category;

      setState(() {
        // Classic category-based mapping for name, SKU and description
        String finalName = '';
        String finalDescription = '';
        // ignore: unused_local_variable
      bool isClothingClass = false;

        final categoryLower = predictedCategory.toLowerCase();

        if (categoryLower == 'blazer') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Classic Slim Fit Blazer';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Elegant and versatile slim-fit blazer, perfect for both formal and semi-formal occasions.';
        } else if (categoryLower == 'pants' || categoryLower == 'celana_panjang') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Classic Cotton Chino Pants';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Comfortable and durable cotton chino pants, perfect for everyday casual or smart wear.';
        } else if (categoryLower == 'shorts' || categoryLower == 'celana_pendek') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Casual Summer Denim Shorts';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Lightweight and breathable denim shorts, ideal for warm summer days.';
        } else if (categoryLower == 'dress' || categoryLower == 'gaun') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Elegant Floral Summer Dress';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Beautiful floral pattern summer dress with a light, flowing fabric.';
        } else if (categoryLower == 'hoodie') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Cozy Oversized Fleece Hoodie';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Warm and soft fleece hoodie, featuring an adjustable drawstring hood and front pouch pocket.';
        } else if (categoryLower == 'denim jacket' || categoryLower == 'jaket_denim') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Blue Denim Jacket';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Classic style blue denim jacket made from high-quality durable cotton denim.';
        } else if (categoryLower == 'sports jacket' || categoryLower == 'jaket_olahraga') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Performance Athletic Sports Jacket';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Lightweight, windproof sports jacket designed for optimal comfort during athletic training.';
        } else if (categoryLower == 'jacket' || categoryLower == 'jaket') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Classic Leather Biker Jacket';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Timeless leather biker jacket with zip closures and classic styling.';
        } else if (categoryLower == 'jeans') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Classic Fit Straight Jeans';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Traditional straight fit denim jeans with five pockets and zip fly.';
        } else if (categoryLower == 't-shirt' || categoryLower == 'kaos') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Premium Cotton T-Shirt';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Soft, breathable premium cotton t-shirt with a classic crew neck design.';
        } else if (categoryLower == 'shirt' || categoryLower == 'kemeja') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Formal Slim Fit Button Shirt';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Classic button-down dress shirt made from wrinkle-resistant cotton blend.';
        } else if (categoryLower == 'coat' || categoryLower == 'mantel') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Winter Wool Blend Coat';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Warm and stylish wool blend overcoat, perfect for cold winter weather.';
        } else if (categoryLower == 'polo shirt' || categoryLower == 'polo') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Classic Fit Polo Shirt';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Sporty and classic fit polo shirt made from breathable pique knit fabric.';
        } else if (categoryLower == 'skirt' || categoryLower == 'rok') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'High Waisted Pleated Skirt';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Charming pleated skirt with a high-waisted fit, ideal for school or casual outings.';
        } else if (categoryLower == 'sweater' || categoryLower == 'sweter') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Cozy Knit Pullover Sweater';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Soft knit pullover sweater with ribbed cuffs and hem, keeping you warm in style.';
        } else if (categoryLower.contains('cloth') || categoryLower == 'clothing' || categoryLower == 'clothes') {
          isClothingClass = true;
          finalName = prediction.name.isNotEmpty ? prediction.name : 'Classic Cotton Denim Jacket';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'High-quality cotton fabric, comfortable and stylish for everyday wear.';
        } else if (categoryLower.contains('electr')) {
          finalName = prediction.name.isNotEmpty 
              ? prediction.name 
              : 'Premium Wireless Smart Headphones';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Noise-cancelling, bluetooth-enabled smart headphones with superior bass.';
        } else if (categoryLower.contains('food')) {
          finalName = prediction.name.isNotEmpty 
              ? prediction.name 
              : 'Organic Whole Food Mix';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Fresh, 100% organic and nutrient-rich ingredients sourced locally.';
        } else if (categoryLower.contains('hand')) {
          finalName = prediction.name.isNotEmpty 
              ? prediction.name 
              : 'Handcrafted Wooden Ornament';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Expertly carved from premium wood, each piece is unique and beautiful.';
        } else if (categoryLower.contains('book')) {
          finalName = prediction.name.isNotEmpty 
              ? prediction.name 
              : 'Inspiring Novel Bestseller';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'An engaging and thought-provoking read that will keep you hooked until the last page.';
        } else if (categoryLower.contains('home')) {
          finalName = prediction.name.isNotEmpty 
              ? prediction.name 
              : 'Elegant Home Ceramic Vase';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Beautifully crafted ceramic vase, perfect for bringing elegance to your living room.';
        } else if (categoryLower.contains('sport')) {
          finalName = prediction.name.isNotEmpty 
              ? prediction.name 
              : 'High-Performance Sports Gear';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Durable, lightweight and designed to optimize your training and performance.';
        } else if (categoryLower.contains('beaut')) {
          finalName = prediction.name.isNotEmpty 
              ? prediction.name 
              : 'Nourishing Face & Body Cream';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Enriched with organic essential oils to nourish, hydrate and protect your skin.';
        } else if (categoryLower.contains('format')) {
          finalName = prediction.name.isNotEmpty 
              ? prediction.name 
              : 'E-Learning Training Bundle';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Comprehensive study material and video lectures to master the subject in weeks.';
        } else {
          finalName = prediction.name.isNotEmpty 
              ? prediction.name 
              : 'General Store Product';
          finalDescription = prediction.description.isNotEmpty 
              ? prediction.description 
              : 'Excellent quality product, perfect for a wide range of everyday uses.';
        }

        String targetCategory = predictedCategory;
        if (isClothingClass) {
          if (_categories.contains('Clothes')) {
            targetCategory = 'Clothes';
          } else if (_categories.contains('Clothing')) {
            targetCategory = 'Clothing';
          } else {
            targetCategory = 'Clothes';
          }
        }

        String matchedCategory = _categories.firstWhere(
          (cat) => cat.toLowerCase() == targetCategory.toLowerCase(),
          orElse: () {
            _categories.add(targetCategory);
            return targetCategory;
          },
        );
        _selectedCategory = matchedCategory;

        _nameController.text = finalName;
        _descriptionController.text = finalDescription;
        _skuController.text = _generateSku(_selectedCategory, finalName);

        _isAnalyzing = false;
      });

      _showSnackBar('ML model detected: $predictedCategory');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _aiError = 'ML analysis failed: $e';
        _isAnalyzing = false;
      });
    }
  }

  String _generateSku(String category, String name) {
    // 1. Category Code (first 3 letters in uppercase)
    String catCode = 'GEN';
    final cleanCat = category.trim().replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (cleanCat.length >= 3) {
      catCode = cleanCat.substring(0, 3).toUpperCase();
    } else if (cleanCat.isNotEmpty) {
      catCode = cleanCat.toUpperCase().padRight(3, 'X');
    }

    // 2. Name Code (first 3 letters of the last word in uppercase)
    String nameCode = 'PRD';
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isNotEmpty) {
      final lastWord = words.last.replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (lastWord.length >= 3) {
        nameCode = lastWord.substring(0, 3).toUpperCase();
      } else if (lastWord.isNotEmpty) {
        nameCode = lastWord.toUpperCase().padRight(3, 'X');
      }
    }

    // 3. Suffix (e.g. '003' style, random 3-digit padded number)
    final randomNum = Random().nextInt(998) + 1;
    final suffix = randomNum.toString().padLeft(3, '0');

    return '$catCode-$nameCode-$suffix';
  }

  // ─── Save Product ─────────────────────────────────────────────────────────────
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productData = {
        'name': _nameController.text.trim(),
        'sku': _skuController.text.trim().isEmpty
            ? 'PROD-${DateTime.now().millisecondsSinceEpoch}'
            : _skuController.text.trim(),
        'category': _selectedCategory,
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'description': _descriptionController.text.trim(),
        'image': null,
      };

      final saved = await ProductService.createProduct(productData);

      if (!mounted) return;
      _showSnackBar('Product added successfully');
      Navigator.pop(context, saved);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? AppTheme.cancelledColor
            : AppTheme.primaryGreen,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Add Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image + AI Section ──────────────────────────────────────────
              _buildImageSection(),
              const SizedBox(height: 20),

              // ── Product Info ────────────────────────────────────────────────
              _sectionLabel('Product Information'),
              const SizedBox(height: 12),
              _buildCard(
                children: [
                  _field(
                    controller: _nameController,
                    label: 'Product Name',
                    hint: 'e.g. Wireless Headphones Pro',
                    icon: Icons.inventory_2_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Product name is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _skuController,
                    label: 'SKU (Optional)',
                    hint: 'Auto-generated if empty',
                    icon: Icons.tag_rounded,
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Describe your product...',
                    icon: Icons.description_outlined,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            prefixIcon: const Icon(Icons.category_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppTheme.borderGrey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppTheme.borderGrey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryGreen,
                                width: 1.5,
                              ),
                            ),
                          ),
                          items: _categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v!),
                        ),
                      ),
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
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Pricing & Stock ─────────────────────────────────────────────
              _sectionLabel('Pricing & Stock'),
              const SizedBox(height: 12),
              _buildCard(
                children: [
                  _field(
                    controller: _priceController,
                    label: 'Price (€)',
                    hint: '0.00',
                    icon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(v.trim()) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildPredictPriceButton(),
                  if (_predictedPrice != null) ...[
                    const SizedBox(height: 12),
                    _buildPredictedPriceCard(),
                  ],
                  const SizedBox(height: 18),
                  _field(
                    controller: _stockController,
                    label: 'Stock',
                    hint: '0',
                    icon: Icons.inventory_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(v.trim()) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Actions ─────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: AppTheme.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.white,
                              ),
                            )
                          : const Text(
                              'Add Product',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Image Section ────────────────────────────────────────────────────────────
  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: AppTheme.subtleShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.primaryGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Product Analysis',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Upload an image to auto-fill product details',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Image preview / picker
          GestureDetector(
            onTap: _isAnalyzing ? null : _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: _selectedImage != null
                    ? Colors.transparent
                    : AppTheme.lightBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedImage != null
                      ? AppTheme.primaryGreen.withValues(alpha: 0.4)
                      : AppTheme.borderGrey,
                  width: _selectedImage != null ? 2 : 1,
                  style: _selectedImage != null
                      ? BorderStyle.solid
                      : BorderStyle.solid,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_selectedImage!, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(
                              alpha: 0.08,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 32,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to upload product image',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppTheme.textMedium,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JPG, PNG or WEBP • Max 10MB',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
            ),
          ),

          if (_selectedImage != null) ...[
            const SizedBox(height: 12),

            // AI Generate button
            SizedBox(
              width: double.infinity,
              child: _isAnalyzing
                  ? _buildAnalyzingState()
                  : ElevatedButton.icon(
                      onPressed: _analyzeWithAI,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text('Generate Automatically'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],

          if (_aiError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cancelledColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.cancelledColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.cancelledColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _aiError!,
                      style: const TextStyle(
                        color: AppTheme.cancelledColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF6366F1),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Analyzing image with AI...',
            style: TextStyle(
              color: Color(0xFF6366F1),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6366F1),
            ),
          ),
        ],
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
                    Text(
                      'AI Recommended Price',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                    Text(
                      '${_predictedPrice!.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w800,
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

  // ─── Helpers ──────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool isPassword = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator,
    );
  }
}
