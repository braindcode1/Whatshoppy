import 'package:flutter/material.dart';
import 'package:whatshoppy2/services/api_client.dart';
import 'package:whatshoppy2/services/order_service.dart';
import 'package:whatshoppy2/screens/bottom.dart';
import 'package:whatshoppy2/screens/orders_screen.dart';
import 'package:whatshoppy2/screens/chatbot_screen.dart';
import 'package:whatshoppy2/theme/app_theme.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const _tabs = [
    'All',
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _normalizeStatus(String? s) {
    switch ((s ?? '').toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _formatDate(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    if (s.contains('T')) return s.split('T').first;
    if (s.contains(' ')) return s.split(' ').first;
    return s;
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final raw = await OrderService.getOrders();
      if (!mounted) return;

      setState(() {
        _allOrders = raw.map((o) {
          final client = o['client'] as Map<String, dynamic>? ?? {};
          return {
            'id': o['id']?.toString() ?? '',
            'order_number':
                o['order_number']?.toString() ?? o['id']?.toString() ?? '',
            'client': client['name']?.toString() ??
                o['client_name']?.toString() ??
                'Unknown',
            'date': _formatDate(o['placed_at'] ?? o['created_at']),
            'status': _normalizeStatus(o['status']?.toString()),
            'price': _parseDouble(o['total']),
            'items': _parseInt(o['items_count']),
            'phone': client['phone']?.toString() ?? '',
            'address': client['address']?.toString() ?? '',
          };
        }).toList();
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

  List<Map<String, dynamic>> _filter(String status) {
    if (status == 'All') return _allOrders;
    return _allOrders.where((o) => o['status'] == status).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppTheme.pendingColor;
      case 'Processing':
        return AppTheme.processingColor;
      case 'Shipped':
        return AppTheme.shippedColor;
      case 'Delivered':
        return AppTheme.deliveredColor;
      case 'Cancelled':
        return AppTheme.cancelledColor;
      default:
        return AppTheme.greyText;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.schedule_rounded;
      case 'Processing':
        return Icons.autorenew_rounded;
      case 'Shipped':
        return Icons.local_shipping_outlined;
      case 'Delivered':
        return Icons.check_circle_outline_rounded;
      case 'Cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchOrders,
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tabs: _tabs.map((t) {
            final count = t == 'All'
                ? _allOrders.length
                : _allOrders.where((o) => o['status'] == t).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t),
                  if (!_isLoading && count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _errorMessage != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: _tabs
                      .map((t) => _buildOrderList(t))
                      .toList(),
                ),
      bottomNavigationBar: const Bottom(currentIndex: 2),
    );
  }

  Widget _buildOrderList(String status) {
    final orders = _filter(status);

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.greyText.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: AppTheme.greyText.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              status == 'All' ? 'No orders yet' : 'No $status orders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.greyText,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: AppTheme.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildOrderCard(orders[i]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final color = _statusColor(status);
    final price = order['price'] as double;
    final items = order['items'] as int;

    return Material(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrdersScreen(order: order),
            ),
          );
          _fetchOrders();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: order number + status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order['order_number'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(status), size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Client row
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
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
                          order['client'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          order['date'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom row: items + price
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$items item${items != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMedium,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${price.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w800,
                        ),
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
              _errorMessage ?? 'Failed to load orders',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchOrders,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
