import 'package:flutter/material.dart';

class ClientProfileScreen extends StatelessWidget {
  final Map<String, dynamic> client;

  const ClientProfileScreen({
    super.key,
    required this.client,
  });

  String _safeString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString();
    return text.trim().isEmpty ? fallback : text;
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Unknown date';

    final text = value.toString();

    if (text.trim().isEmpty) return 'Unknown date';

    if (text.contains('T')) {
      return text.split('T').first;
    }

    if (text.contains(' ')) {
      return text.split(' ').first;
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final String name = _safeString(
      client['name'],
      fallback: 'Unknown Client',
    );

    final String phone = _safeString(
      client['phone'],
      fallback: 'No phone',
    );

    final String address = _safeString(
      client['address'],
      fallback: 'No address',
    );

    final String lastActive = _safeString(
      client['last_active'],
      fallback: 'Active recently',
    );

    final int ordersCount = _safeInt(
      client['orders_count'] ?? client['orders'] ?? client['order_count'],
    );

    final String createdAt = _formatDate(client['created_at']);

    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Client Profile",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ───────────────── HEADER ─────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green.withOpacity(0.12),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ───────────────── CONTACT INFO ─────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Contact Information",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.green,
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Client since $createdAt",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_outlined,
                        color: Colors.green,
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lastActive,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ───────────────── ORDERS CARD ─────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.green,
                    size: 30,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Orders",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "$ordersCount orders placed by this client",
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    "$ordersCount",
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}