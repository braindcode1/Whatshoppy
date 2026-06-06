import 'package:flutter/material.dart';
import 'package:whatshoppy2/theme/app_theme.dart';
import 'package:whatshoppy2/screens/bottom.dart';
import 'package:whatshoppy2/screens/chat_screen.dart';
import 'package:whatshoppy2/services/message_service.dart';

class InboxListScreen extends StatefulWidget {
  const InboxListScreen({super.key});

  @override
  State<InboxListScreen> createState() => _InboxListScreenState();
}

class _InboxListScreenState extends State<InboxListScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _searchController.addListener(_filterConversations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _unreadBadge(dynamic unread) {
    if (unread == true) return 1;
    if (unread is num && unread != 0) return unread.toInt().clamp(0, 99);
    return 0;
  }

  Future<void> _fetchConversations() async {
    try {
      final rawRows = await MessageService.getInboxItems();

      if (!mounted) return;

      setState(() {
        _conversations = rawRows.map((row) {
          final title = row['title']?.toString() ?? '';
          return {
            ...row,
            'name': title,
            'avatar': title.isNotEmpty ? title[0].toUpperCase() : '?',
            'lastMessage': row['subtitle']?.toString() ?? '',
            'time': row['time_label']?.toString() ?? '',
            'unread': _unreadBadge(row['unread']),
            'online': false,
          };
        }).toList();
        _filteredConversations = _conversations;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', 'Failed to load inbox'),
            ),
            backgroundColor: AppTheme.cancelledColor,
          ),
        );
      }
    }
  }

  void _filterConversations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredConversations = _conversations.where((conversation) {
        final name = conversation['name']?.toString().toLowerCase() ?? '';
        final sub = conversation['lastMessage']?.toString().toLowerCase() ?? '';
        final typ = conversation['type']?.toString().toLowerCase() ?? '';
        final tl = conversation['time']?.toString().toLowerCase() ?? '';
        return name.contains(query) ||
            sub.contains(query) ||
            typ.contains(query) ||
            tl.contains(query);
      }).toList();
    });
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversation: conversation),
            ),
          ).then((_) => _fetchConversations());
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Text(
                      conversation['avatar'],
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (conversation['online'])
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.shippedColor,
                          border: Border.all(color: AppTheme.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          conversation['name'],
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          conversation['time'],
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation['lastMessage'],
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: conversation['unread'] > 0 
                                  ? AppTheme.textDark 
                                  : AppTheme.greyText,
                              fontWeight: conversation['unread'] > 0 
                                  ? FontWeight.w500 
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation['unread'] > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Text(
                              '${conversation['unread']}',
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search inbox…',
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.greyText,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _fetchConversations,
                  child: _filteredConversations.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: AppTheme.greyText,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No inbox items found',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppTheme.greyText,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ]
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredConversations.length,
                          itemBuilder: (context, index) {
                            return _buildConversationCard(_filteredConversations[index]);
                          },
                        ),
                ),
          ),
        ],
      ),
      bottomNavigationBar: const Bottom(currentIndex: 0),
    );
  }
}
