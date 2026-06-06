import 'package:flutter/material.dart';
import 'package:whatshoppy2/theme/app_theme.dart';
import 'package:whatshoppy2/services/order_service.dart';
import 'bottom.dart';

class OrdersScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrdersScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late String currentStatus;
  bool _isUpdating = false;
  List<Map<String, dynamic>> _lineItems = [];

  @override
  void initState() {
    super.initState();
    currentStatus = widget.order["status"] ?? "Pending";
    _loadLineItems();
  }

  Future<void> _loadLineItems() async {
    final id = widget.order['id']?.toString();
    if (id == null || id.isEmpty) return;
    try {
      final items = await OrderService.getOrderLineItems(id);
      if (mounted) {
        setState(() => _lineItems = items);
      }
    } catch (_) {
      // Fall back to aggregate count in UI
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case "Pending":
        return AppTheme.pendingColor;
      case "Processing":
        return AppTheme.processingColor;
      case "Shipped":
        return AppTheme.shippedColor;
      case "Delivered":
        return Colors.green[700]!;
      case "Cancelled":
        return AppTheme.cancelledColor;
      default:
        return AppTheme.greyText;
    }
  }

  Future<void> _updateStatus(String? newStatus) async {
    if (newStatus == null || newStatus == currentStatus) return;

    setState(() => _isUpdating = true);

    try {
      await OrderService.updateOrderStatus(
        widget.order["id"].toString(),
        newStatus,
      );

      setState(() {
        currentStatus = newStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Order status updated"),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', 'Failed to update status'),
            ),
            backgroundColor: AppTheme.cancelledColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget buildProduct(String name, int qty, double price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Qty : $qty",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              "${price.toStringAsFixed(2)} €",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color color = statusColor(currentStatus);

    final String clientName = widget.order["client"] ?? "Unknown Client";
    final String clientPhone = widget.order["phone"] ?? "No phone";
    final String clientAddress =
        widget.order["address"] ?? "No address provided";

    final String invoiceNumber =
        widget.order["order_number"] ?? widget.order["id"] ?? "";

    final itemsList = _lineItems;

    final double price = widget.order["price"] is double
        ? widget.order["price"]
        : double.tryParse(widget.order["price"].toString()) ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Invoice $invoiceNumber",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Customer",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),

              Text(
                clientName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                clientPhone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),

              const SizedBox(height: 8),

              Text(
                clientAddress,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),

              const SizedBox(height: 14),

              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Text(
                    "Status : ",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (_isUpdating)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: currentStatus,
                          icon: Icon(Icons.arrow_drop_down, color: color),
                          dropdownColor: Colors.white,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                          items: const [
                            'Pending',
                            'Processing',
                            'Shipped',
                            'Delivered',
                            'Cancelled',
                          ].map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            );
                          }).toList(),
                          onChanged: _updateStatus,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 22),
              const Divider(),
              const SizedBox(height: 14),

              const Text(
                "Products",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              if (itemsList.isEmpty)
                Text(
                  "${widget.order["items"] ?? 0} items in this order.",
                  style: const TextStyle(color: Colors.grey),
                )
              else
                ...itemsList.map((m) {
                  final unit = m["unit_price"];
                  final unitDouble = unit is num
                      ? unit.toDouble()
                      : double.tryParse(unit?.toString() ?? '0') ?? 0.0;
                  return buildProduct(
                    m["product_name"] ?? "Product",
                    m["quantity"] ?? 1,
                    unitDouble,
                  );
                }),

              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 20),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "${price.toStringAsFixed(2)} €",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Bottom(currentIndex: 2),
    );
  }
}