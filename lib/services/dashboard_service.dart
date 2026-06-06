import 'package:whatshoppy2/services/api_client.dart';
import 'package:whatshoppy2/services/local_storage_service.dart';

class DashboardStats {
  final int productsCount;
  final int clientsCount;
  final int ordersCount;
  final int pendingOrders;
  final double totalRevenue;

  const DashboardStats({
    required this.productsCount,
    required this.clientsCount,
    required this.ordersCount,
    required this.pendingOrders,
    required this.totalRevenue,
  });
}

class DashboardFetchResult {
  final DashboardStats stats;
  final bool isEmptyBusinessData;
  final bool isPermissionOrSessionIssue;
  final String? diagnosticMessage;

  const DashboardFetchResult({
    required this.stats,
    required this.isEmptyBusinessData,
    required this.isPermissionOrSessionIssue,
    this.diagnosticMessage,
  });
}

class DashboardService {
  /// Calls GET /api/dashboard?user_id=<uid>
  static Future<DashboardFetchResult> loadDashboard() async {
    final String uid;
    try {
      uid = await LocalStorageService.getCurrentUserId();
    } catch (e) {
      return DashboardFetchResult(
        stats: _zero(),
        isEmptyBusinessData: false,
        isPermissionOrSessionIssue: true,
        diagnosticMessage: 'Not logged in. Please sign in again.',
      );
    }

    try {
      final response = await ApiClient.get(
        '/api/dashboard',
        queryParams: {'user_id': uid},
      );

      final data = response['data'] as Map<String, dynamic>? ?? {};

      final stats = DashboardStats(
        productsCount: _parseInt(data['products_count']),
        clientsCount:  _parseInt(data['clients_count']),
        ordersCount:   _parseInt(data['orders_count']),
        pendingOrders: _parseInt(data['pending_orders']),
        totalRevenue:  _parseDouble(data['total_revenue']),
      );

      final allZero = stats.productsCount == 0 &&
          stats.clientsCount == 0 &&
          stats.ordersCount == 0;

      return DashboardFetchResult(
        stats: stats,
        isEmptyBusinessData: allZero,
        isPermissionOrSessionIssue: false,
      );
    } on ApiException catch (e) {
      return DashboardFetchResult(
        stats: _zero(),
        isEmptyBusinessData: false,
        isPermissionOrSessionIssue: true,
        diagnosticMessage: e.message,
      );
    } catch (e) {
      rethrow;
    }
  }

  static DashboardStats _zero() => const DashboardStats(
        productsCount: 0,
        clientsCount: 0,
        ordersCount: 0,
        pendingOrders: 0,
        totalRevenue: 0,
      );

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
