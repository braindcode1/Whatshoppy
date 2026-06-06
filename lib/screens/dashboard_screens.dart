import 'package:flutter/material.dart';
import 'package:whatshoppy2/theme/app_theme.dart';
import 'package:whatshoppy2/services/dashboard_service.dart';
import 'package:whatshoppy2/screens/clients_screen.dart';
import 'package:whatshoppy2/screens/order_list_screen.dart';
import 'package:whatshoppy2/screens/stock_screen.dart';
import 'package:whatshoppy2/screens/add_product_screen.dart';
import 'package:whatshoppy2/screens/settings_screen.dart';
import 'package:whatshoppy2/screens/revenue_analytics_screen.dart';
import 'package:whatshoppy2/screens/bottom.dart';
import 'package:whatshoppy2/screens/chatbot_screen.dart';
import 'package:whatshoppy2/widgets/shimmer_loader.dart';

class DashboardScreens extends StatefulWidget {
  final String? userId;
  const DashboardScreens({super.key, this.userId});

  @override
  State<DashboardScreens> createState() => _DashboardScreensState();
}

class _DashboardScreensState extends State<DashboardScreens>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;

  int _productsCount = 0;
  int _clientsCount = 0;
  int _ordersCount = 0;
  int _pendingOrders = 0;
  double _totalRevenue = 0.0;

  bool _emptyBusinessData = false;
  bool _liveDataOk = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _fetchDashboard();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emptyBusinessData = false;
      _liveDataOk = false;
    });

    try {
      final result = await DashboardService.loadDashboard();
      if (!mounted) return;

      if (result.isPermissionOrSessionIssue) {
        setState(() {
          _errorMessage = result.diagnosticMessage ??
              'Could not load your data. Please sign in again.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _productsCount = result.stats.productsCount;
        _clientsCount = result.stats.clientsCount;
        _ordersCount = result.stats.ordersCount;
        _pendingOrders = result.stats.pendingOrders;
        _totalRevenue = result.stats.totalRevenue;
        _emptyBusinessData = result.isEmptyBusinessData;
        _liveDataOk = true;
        _isLoading = false;
      });
      _fadeController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        if (_errorMessage!.isEmpty) _errorMessage = 'Could not load dashboard';
        _isLoading = false;
      });
    }
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 👋';
    return 'Good Evening 🌙';
  }

  String _formatRevenue(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Intercept the system back button on Dashboard.
      // canPop: false means the back gesture/button is consumed here.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Ask the user before exiting the app entirely.
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit WhatShoppy?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.cancelledColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        if (shouldExit == true && context.mounted) {
          // Pop with the system navigator to actually exit.
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightBackground,
        appBar: _buildAppBar(),
        body: RefreshIndicator(
          onRefresh: _fetchDashboard,
          color: AppTheme.primaryGreen,
          child: _isLoading
              ? _buildShimmer()
              : _errorMessage != null
                  ? _buildError()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: _buildBody(),
                      ),
                    ),
        ),
        bottomNavigationBar: const Bottom(currentIndex: 0),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, animation, __) => const ChatbotScreen(),
              transitionsBuilder: (_, animation, __, child) =>
                  ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: AppTheme.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.smart_toy_rounded, size: 26),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  // ─── AppBar ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.white,
      elevation: 0,
      // No back arrow on Dashboard — it is the root screen after login.
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppTheme.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'WhatShoppy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        if (_liveDataOk)
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Live',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 22),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ],
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_emptyBusinessData) ...[
            _buildEmptyBanner(),
            const SizedBox(height: 16),
          ],

          // Greeting
          Text(
            _getGreeting(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.greyText,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Business Overview',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
              ),
              const Spacer(),
              if (_liveDataOk)
                Material(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.push(
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
                        transitionDuration:
                            const Duration(milliseconds: 300),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.smart_toy_rounded,
                            color: AppTheme.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Ask AI',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Revenue card (full width, prominent)
          _buildRevenueCard(),
          const SizedBox(height: 14),

          // Pending orders
          _buildPendingCard(),
          const SizedBox(height: 20),

          // KPI grid
          Text(
            'Quick Access',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  title: 'Clients',
                  value: '$_clientsCount',
                  icon: Icons.people_rounded,
                  color: AppTheme.processingColor,
                  screen: const ClientsScreen(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  title: 'Orders',
                  value: '$_ordersCount',
                  icon: Icons.shopping_bag_rounded,
                  color: AppTheme.darkGreen,
                  screen: const OrdersListScreen(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  title: 'Products',
                  value: '$_productsCount',
                  icon: Icons.inventory_2_rounded,
                  color: AppTheme.shippedColor,
                  screen: const StockScreen(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildAddProductCard()),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Revenue Card ─────────────────────────────────────────────────────────────
  Widget _buildRevenueCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RevenueAnalyticsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.greenShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Total Revenue',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_formatRevenue(_totalRevenue)} €',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap to view analytics →',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pending Card ─────────────────────────────────────────────────────────────
  Widget _buildPendingCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrdersListScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderGrey),
          boxShadow: AppTheme.subtleShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.pendingColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.schedule_rounded,
                color: AppTheme.pendingColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Orders',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.greyText,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_pendingOrders orders awaiting',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _pendingOrders > 0
                    ? AppTheme.pendingColor.withValues(alpha: 0.1)
                    : AppTheme.shippedColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_pendingOrders',
                style: TextStyle(
                  color: _pendingOrders > 0
                      ? AppTheme.pendingColor
                      : AppTheme.shippedColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── KPI Card ─────────────────────────────────────────────────────────────────
  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return Material(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppTheme.greyText.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.greyText,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: AppTheme.textDark,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Add Product Card ─────────────────────────────────────────────────────────
  Widget _buildAddProductCard() {
    return Material(
      color: AppTheme.primaryGreen,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddProductScreen()),
        ),
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add Product',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Quick\nAdd',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Empty Banner ─────────────────────────────────────────────────────────────
  Widget _buildEmptyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.storefront_rounded,
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
                  'Your workspace is ready',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.darkGreen,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Add products, clients and orders to get started.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.greyText,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shimmer ──────────────────────────────────────────────────────────────────
  Widget _buildShimmer() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoader(width: 140, height: 14),
          const SizedBox(height: 8),
          const ShimmerLoader(width: 220, height: 28),
          const SizedBox(height: 24),
          const ShimmerLoader(
            height: 110,
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          const SizedBox(height: 14),
          const ShimmerLoader(
            height: 72,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          const SizedBox(height: 20),
          const ShimmerLoader(width: 120, height: 14),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: ShimmerKPICard()),
              SizedBox(width: 12),
              Expanded(child: ShimmerKPICard()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: ShimmerKPICard()),
              SizedBox(width: 12),
              Expanded(child: ShimmerKPICard()),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Error ────────────────────────────────────────────────────────────────────
  Widget _buildError() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.cancelledColor.withValues(alpha: 0.3),
              ),
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cancelledColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 36,
                    color: AppTheme.cancelledColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not load dashboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _fetchDashboard,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
