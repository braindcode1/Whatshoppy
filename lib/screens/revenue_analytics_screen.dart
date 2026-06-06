import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:whatshoppy2/theme/app_theme.dart';
import 'package:whatshoppy2/screens/bottom.dart';
import 'package:whatshoppy2/services/order_service.dart';

class RevenueAnalyticsScreen extends StatefulWidget {
  const RevenueAnalyticsScreen({super.key});

  @override
  State<RevenueAnalyticsScreen> createState() => _RevenueAnalyticsScreenState();
}

class _RevenueAnalyticsScreenState extends State<RevenueAnalyticsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  double todayRevenue = 0;
  double weeklyTotal = 0;
  double monthlyTotal = 0;
  double totalRevenue = 0;
  double profitMargin = 25;

  List<double> weeklyRevenue = List.filled(7, 0);
  List<double> monthlyRevenue = List.filled(12, 0);

  final List<String> weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRevenueData();
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _fetchRevenueData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await OrderService.getOrders();

      final now = DateTime.now();

      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      double newTodayRevenue = 0;
      double newWeeklyTotal = 0;
      double newMonthlyTotal = 0;
      double newTotalRevenue = 0;

      final newWeeklyRevenue = List<double>.filled(7, 0);
      final newMonthlyRevenue = List<double>.filled(12, 0);

      for (final order in orders) {
        final total = _parseDouble(order['total']);
        final status = (order['status'] ?? '').toString().toLowerCase();

        if (status == 'cancelled') continue;

        final date = _parseDate(order['placed_at'] ?? order['created_at']);
        if (date == null) continue;

        newTotalRevenue += total;

        if (_sameDay(date, now)) {
          newTodayRevenue += total;
        }

        final isSameMonth = date.year == now.year && date.month == now.month;
        if (isSameMonth) {
          newMonthlyTotal += total;
        }

        final weekIndex = date.difference(startOfWeek).inDays;
        if (weekIndex >= 0 && weekIndex < 7) {
          newWeeklyRevenue[weekIndex] += total;
          newWeeklyTotal += total;
        }

        if (date.year == now.year) {
          newMonthlyRevenue[date.month - 1] += total;
        }
      }

      if (!mounted) return;

      setState(() {
        todayRevenue = newTodayRevenue;
        weeklyTotal = newWeeklyTotal;
        monthlyTotal = newMonthlyTotal;
        totalRevenue = newTotalRevenue;
        weeklyRevenue = newWeeklyRevenue;
        monthlyRevenue = newMonthlyRevenue;
        _isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _errorMessage = "Request timeout";
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e
            .toString()
            .replaceFirst('Exception: ', 'Failed to load revenue analytics');
        _isLoading = false;
      });
    }
  }

  String _formatMoney(double value) {
    return "${value.toStringAsFixed(2)} €";
  }

  double _maxY(List<double> values) {
    final maxValue = values.fold<double>(
      0,
      (previous, current) => current > previous ? current : previous,
    );

    if (maxValue <= 0) return 100;
    return maxValue + (maxValue * 0.25);
  }

  List<Map<String, dynamic>> _buildProfitData() {
    return List.generate(12, (index) {
      final revenue = monthlyRevenue[index];
      final profit = revenue * (profitMargin / 100);

      return {
        'month': months[index],
        'revenue': revenue,
        'profit': profit,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text("Revenue Analytics"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRevenueData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _fetchRevenueData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                "Today's Revenue",
                                _formatMoney(todayRevenue),
                                Icons.trending_up,
                                AppTheme.primaryGreen,
                                "From today's orders",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                "Weekly Total",
                                _formatMoney(weeklyTotal),
                                Icons.calendar_view_week,
                                AppTheme.processingColor,
                                "Current week",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                "Monthly Total",
                                _formatMoney(monthlyTotal),
                                Icons.calendar_month,
                                AppTheme.pendingColor,
                                "Current month",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                context,
                                "Total Revenue",
                                _formatMoney(totalRevenue),
                                Icons.show_chart,
                                AppTheme.shippedColor,
                                "All non-cancelled orders",
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, "Revenue Evolution"),
                        _buildMonthlyChart(),
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, "Weekly Revenue"),
                        _buildWeeklyChart(),
                        const SizedBox(height: 24),
                        _buildSectionTitle(context, "Profit Analysis"),
                        _buildProfitAnalysis(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: const Bottom(currentIndex: 0),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.greyText),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? "Failed to load revenue analytics",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.greyText),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchRevenueData,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 11,
              minY: 0,
              maxY: _maxY(monthlyRevenue),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppTheme.borderGrey,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();

                      if (i >= 0 && i < months.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            months[i],
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      }

                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: monthlyRevenue.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value);
                  }).toList(),
                  isCurved: true,
                  color: AppTheme.primaryGreen,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: _maxY(weeklyRevenue),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppTheme.borderGrey,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();

                      if (i >= 0 && i < weekDays.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            weekDays[i],
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      }

                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ),
              ),
              barGroups: weeklyRevenue.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      width: 16,
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfitAnalysis() {
    final profitData = _buildProfitData();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: profitData.map((item) {
            final revenue = item["revenue"] as double;
            final profit = item["profit"] as double;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      item["month"],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Revenue: ${revenue.toStringAsFixed(2)}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Profit: ${profit.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}