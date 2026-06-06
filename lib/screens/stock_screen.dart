import 'package:flutter/material.dart';
import 'package:whatshoppy2/services/api_client.dart';
import 'package:whatshoppy2/services/product_service.dart';
import 'package:whatshoppy2/screens/add_product_screen.dart';
import 'package:whatshoppy2/screens/product_details_screen.dart';
import 'package:whatshoppy2/screens/bottom.dart';
import 'package:whatshoppy2/screens/chatbot_screen.dart';
import 'package:whatshoppy2/theme/app_theme.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final raw = await ProductService.getProducts();
      if (!mounted) return;

      setState(() {
        _products = raw.map((p) {
          final price = p['price'];
          return {
            'id': p['id'],
            'name': p['name'] ?? '',
            'sku': p['sku'] ?? '',
            'category': p['category'] ?? 'General',
            'price': price is num
                ? '${price.toStringAsFixed(2)} €'
                : '${price ?? 0} €',
            'stock': p['stock'] ?? 0,
            'description': p['description'] ?? '',
            'image': p['image'],
          };
        }).toList();
        _filtered = _products;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _products.where((p) {
        return (p['name'] as String).toLowerCase().contains(q) ||
            (p['category'] as String).toLowerCase().contains(q) ||
            (p['sku'] as String).toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _addProduct() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (result != null) {
      _fetchProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "${result['name']}" added'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    }
  }

  Future<void> _viewProduct(Map<String, dynamic> product) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(product: product),
      ),
    );
    if (result != null) _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            : const Text('Products'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filtered = _products;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchProducts,
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => const ChatbotScreen(),
                transitionsBuilder: (_, animation, __, child) =>
                    ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                        parent: animation, curve: Curves.easeOutBack),
                  ),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ),
            tooltip: 'AI Assistant',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Header stats
          Container(
            color: AppTheme.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                _statChip(
                  '${_filtered.length}',
                  'Products',
                  AppTheme.primaryGreen,
                ),
                const SizedBox(width: 10),
                _statChip(
                  '${_products.where((p) => (p['stock'] as int) == 0).length}',
                  'Out of stock',
                  AppTheme.cancelledColor,
                ),
                const SizedBox(width: 10),
                _statChip(
                  '${_products.where((p) {
                    final s = p['stock'] as int;
                    return s > 0 && s <= 10;
                  }).length}',
                  'Low stock',
                  AppTheme.pendingColor,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : _errorMessage != null
                    ? _buildError()
                    : _filtered.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _fetchProducts,
                            color: AppTheme.primaryGreen,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 12, 16, 100),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) =>
                                  _buildProductCard(_filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: const Bottom(currentIndex: 3),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> item) {
    final stock = item['stock'] as int;
    final stockColor = stock == 0
        ? AppTheme.cancelledColor
        : stock <= 10
            ? AppTheme.pendingColor
            : AppTheme.shippedColor;
    final stockLabel = stock == 0
        ? 'Out of stock'
        : stock <= 10
            ? 'Low stock'
            : 'In stock';

    return Material(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _viewProduct(item),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Row(
            children: [
              // Product image / icon
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.primaryGreen,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item['sku']} · ${item['category']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          item['price'] as String,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            stockLabel,
                            style: TextStyle(
                              color: stockColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stock count
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$stock',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: stockColor,
                        ),
                  ),
                  Text(
                    'units',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppTheme.greyText),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Failed to load products',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchProducts,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No products match your search'
                : 'No products yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.greyText,
                ),
          ),
          const SizedBox(height: 8),
          if (_searchController.text.isNotEmpty)
            TextButton(
              onPressed: () => _searchController.clear(),
              child: const Text('Clear search'),
            )
          else
            TextButton.icon(
              onPressed: _addProduct,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add your first product'),
            ),
        ],
      ),
    );
  }
}
