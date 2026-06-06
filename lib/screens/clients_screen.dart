import 'package:flutter/material.dart';
import 'package:whatshoppy2/services/api_client.dart';
import 'package:whatshoppy2/services/client_service.dart';
import 'package:whatshoppy2/screens/bottom.dart';
import 'package:whatshoppy2/screens/client_profile.dart';
import 'package:whatshoppy2/screens/chatbot_screen.dart';
import 'package:whatshoppy2/theme/app_theme.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchClients();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _safe(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  int _safeInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Future<void> _fetchClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final raw = await ClientService.getClients();
      if (!mounted) return;

      setState(() {
        _clients = raw.map((c) => {
              'id': _safe(c['id']),
              'user_id': _safe(c['user_id']),
              'name': _safe(c['name'], fallback: 'Unknown Client'),
              'phone': _safe(c['phone'], fallback: 'No phone'),
              'address': _safe(c['address'], fallback: 'No address'),
              'last_active': _safe(c['last_active'], fallback: 'Recently'),
              'orders_count':
                  _safeInt(c['orders_count'] ?? c['order_count']),
              'avatar_color': c['avatar_color'],
              'tags': c['tags'] ?? [],
              'created_at': _safe(c['created_at']),
            }).toList();
        _filtered = _clients;
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
      _filtered = _clients.where((c) {
        return (c['name'] as String).toLowerCase().contains(q) ||
            (c['phone'] as String).toLowerCase().contains(q) ||
            (c['address'] as String).toLowerCase().contains(q);
      }).toList();
    });
  }

  Color _avatarColor(int index) {
    const colors = [
      AppTheme.primaryGreen,
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF14B8A6),
      Color(0xFFF59E0B),
      Color(0xFF6366F1),
    ];
    return colors[index % colors.length];
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
                  hintText: 'Search clients...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            : const Text('Clients'),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filtered = _clients;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchClients,
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
      body: Column(
        children: [
          // Header
          Container(
            color: AppTheme.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.processingColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.processingColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_filtered.length}',
                        style: const TextStyle(
                          color: AppTheme.processingColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'clients',
                        style: TextStyle(
                          color: AppTheme.processingColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

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
                            onRefresh: _fetchClients,
                            color: AppTheme.primaryGreen,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 12, 16, 24),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) =>
                                  _buildClientCard(_filtered[i], i),
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: const Bottom(currentIndex: 1),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client, int index) {
    final color = _avatarColor(index);
    final name = client['name'] as String;
    final phone = client['phone'] as String;
    final address = client['address'] as String;
    final orders = client['orders_count'] as int;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Material(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClientProfileScreen(client: client),
          ),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 12,
                          color: AppTheme.greyText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppTheme.greyText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Orders badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$orders',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'orders',
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
              _errorMessage ?? 'Failed to load clients',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchClients,
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
              color: AppTheme.processingColor.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: AppTheme.processingColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No clients match your search'
                : 'No clients yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.greyText,
                ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _searchController.clear(),
              child: const Text('Clear search'),
            ),
          ],
        ],
      ),
    );
  }
}
