import 'package:flutter/material.dart';
import 'package:whatshoppy2/theme/app_theme.dart';
import 'package:whatshoppy2/services/message_service.dart';

/// Detail view for one inbox row; if [related_client_id] is set, shows all items
/// for the same user with that [related_client_id] (thread), ordered for chat.
class ChatScreen extends StatefulWidget {
  /// Typically one row from [MessageService.getInboxItems] (includes id, title, …).
  final Map<String, dynamic> conversation;

  const ChatScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _safeString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString();
    return text.trim().isEmpty ? fallback : text;
  }

  static int _unreadCount(dynamic u) {
    if (u == true) return 1;
    if (u is num && u != 0) return u.toInt();
    return 0;
  }

  static bool _isOutgoingType(dynamic type) {
    final t = type?.toString().toLowerCase() ?? '';
    return t.contains('business') ||
        t.contains('outbound') ||
        t.contains('sent') ||
        t == 'admin';
  }

  String _nowTimeLabel() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  String _getInitial() {
    final title = _safeString(widget.conversation['title'], fallback: 'I');
    return title.isNotEmpty ? title[0].toUpperCase() : '?';
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final id = _safeString(widget.conversation['id']);
      if (id.isEmpty) {
        setState(() {
          _messages = [];
          _isLoading = false;
        });
        return;
      }

      if (_unreadCount(widget.conversation['unread']) > 0) {
        await MessageService.markAsRead(id);
      }

      final all = await MessageService.getInboxItems();
      final related = widget.conversation['related_client_id'];

      List<Map<String, dynamic>> thread;
      final relatedStr = related?.toString() ?? '';
      if (relatedStr.isNotEmpty) {
        thread = all
            .where((r) => (r['related_client_id']?.toString() ?? '') == relatedStr)
            .toList();
      } else {
        thread = all.where((r) => _safeString(r['id']) == id).toList();
      }

      // Newest-first from API → reverse so oldest appears at top of chat
      thread = thread.reversed.toList();

      if (!mounted) return;

      setState(() {
        _messages = thread.map((msg) {
          final outgoing = _isOutgoingType(msg['type']);
          final title = _safeString(msg['title']);
          final subtitle = _safeString(msg['subtitle']);
          final body = title.isEmpty
              ? subtitle
              : subtitle.isEmpty
                  ? title
                  : '$title\n$subtitle';
          return {
            'id': _safeString(msg['id']),
            'text': body,
            'time': _safeString(msg['time_label']),
            'isMe': outgoing,
          };
        }).toList();

        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', 'Failed to load messages'),
          ),
          backgroundColor: AppTheme.cancelledColor,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final relatedClient = widget.conversation['related_client_id'];
      final relatedOrder = widget.conversation['related_order_id'];
      final relatedProduct = widget.conversation['related_product_id'];

      final payload = <String, dynamic>{
        'title': 'You',
        'subtitle': text,
        'type': 'business',
        'time_label': _nowTimeLabel(),
        'unread': false,
      };

      if (relatedClient != null && relatedClient.toString().isNotEmpty) {
        payload['related_client_id'] = relatedClient;
      }
      if (relatedOrder != null && relatedOrder.toString().isNotEmpty) {
        payload['related_order_id'] = relatedOrder;
      }
      if (relatedProduct != null && relatedProduct.toString().isNotEmpty) {
        payload['related_product_id'] = relatedProduct;
      }

      final msg = await MessageService.createInboxItem(payload);

      if (!mounted) return;

      setState(() {
        _messages.add({
          'id': _safeString(msg['id']),
          'text': _safeString(msg['subtitle'], fallback: text),
          'time': _safeString(msg['time_label']),
          'isMe': true,
        });
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', 'Failed to send message'),
          ),
          backgroundColor: AppTheme.cancelledColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isMe = message['isMe'] == true;
    final String text = _safeString(message['text']);
    final String time = _safeString(message['time']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              child: Text(
                _getInitial(),
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryGreen : AppTheme.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft:
                      isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight:
                      isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    softWrap: true,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.textDark,
                      fontSize: 16,
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.greyText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightBackground,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Add a note…',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    hintStyle: TextStyle(
                      color: AppTheme.greyText,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;

    final String title = _safeString(
      conversation['title'],
      fallback: 'Inbox',
    );

    final String type = _safeString(conversation['type']);
    final String related = [
      if (_safeString(conversation['related_order_id']).isNotEmpty)
        'Order: ${_safeString(conversation['related_order_id'])}',
      if (_safeString(conversation['related_product_id']).isNotEmpty)
        'Product: ${_safeString(conversation['related_product_id'])}',
      if (_safeString(conversation['related_client_id']).isNotEmpty)
        'Client: ${_safeString(conversation['related_client_id'])}',
    ].where((s) => s.isNotEmpty).join(' · ');

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,

      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              child: Text(
                _getInitial(),
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (type.isNotEmpty || related.isNotEmpty)
                    Text(
                      [if (type.isNotEmpty) type, if (related.isNotEmpty) related]
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.greyText,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No inbox entries to show yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.greyText,
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchMessages,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                      ),
          ),

          _buildMessageInput(),
        ],
      ),
    );
  }
}
