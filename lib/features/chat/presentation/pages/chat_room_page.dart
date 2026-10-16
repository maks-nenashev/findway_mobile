import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../injection_container.dart';
import '../../../search/presentation/bloc/search_bloc.dart';
import '../../../search/presentation/bloc/search_event.dart';
import '../../../search/presentation/pages/post_card_page.dart';

import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../data/models/message_model.dart';

class ChatRoomPage extends StatefulWidget {
  final int recipientId;
  final String recipientName;
  final String? avatarUrl;
  final String currentLocale;

  const ChatRoomPage({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.avatarUrl,
    required this.currentLocale,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    context.read<ChatBloc>().add(FetchMessages(
      recipientId: widget.recipientId,
      locale: widget.currentLocale,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(SendMessage(
      recipientId: widget.recipientId,
      body: text,
      locale: widget.currentLocale,
    ));

    _messageController.clear();
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Chat?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "This will permanently erase all messages for both sides.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatBloc>().add(DeleteChat(recipientId: widget.recipientId));
              Navigator.pop(confirmContext);
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // БЕЗОПАСНЫЙ ПЕРЕХВАТЧИК ССЫЛОК
  // ===========================================================================
  Future<bool> _handleUrlTap(String url) async {
    final String cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return true;

    try {
      final Uri? uri = Uri.tryParse(cleanUrl);
      if (uri == null) return true;

      final List<String> segments = uri.pathSegments;

      const Map<String, String> entityMapping = {
        'biometrics': 'biometric',
        'biometric': 'biometric',
        'biometric_matches': 'biometric_match',
        'biometric_match': 'biometric_match',
        'articles': 'article',
        'article': 'article',
        'posts': 'post',
        'post': 'post',
        'matches': 'match',
        'match': 'match',
        'items': 'item',
        'item': 'item',
        'senses': 'sense',
        'sense': 'sense',
        'things': 'thing',
        'thing': 'thing',
        'people': 'people',
      };

      int entityIndex = -1;
      String? matchedEntityType;

      for (int i = 0; i < segments.length; i++) {
        final String seg = segments[i].toLowerCase();
        if (entityMapping.containsKey(seg)) {
          entityIndex = i;
          matchedEntityType = entityMapping[seg];
          break;
        }
      }

      if (entityIndex != -1 && entityIndex + 1 < segments.length && matchedEntityType != null) {
        final int? entityId = int.tryParse(segments[entityIndex + 1]);

        if (entityId != null) {
          debugPrint('[ChatRoom] Internal link tapped -> Opening PostCardPage for: $matchedEntityType #$entityId');
          _navigateToEntity(matchedEntityType, entityId);
          return true;
        }
      }

      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        final String host = uri.host.toLowerCase();
        final bool isInternalHost = host.contains('findway') ||
            host == 'localhost' ||
            host == '127.0.0.1' ||
            host.startsWith('10.') ||
            host.startsWith('192.168.');

        if (!isInternalHost && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('[ChatRoom] Error in _handleUrlTap: $e');
    }

    return true;
  }

  // ===========================================================================
  // ПЕРЕХОД НА РЕАЛЬНЫЙ PostCardPage
  // ===========================================================================
  void _navigateToEntity(String entityType, int id) {
    if (!mounted) return;

    String category = 'people';
    if (entityType == 'biometric' ||
        entityType == 'biometric_match' ||
        entityType == 'sense' ||
        entityType == 'senses' ||
        entityType == 'animal' ||
        entityType == 'animals') {
      category = 'animals';
    } else if (entityType == 'item' ||
        entityType == 'items' ||
        entityType == 'thing' ||
        entityType == 'things') {
      category = 'things';
    } else {
      category = 'people';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<SearchBloc>(
          create: (context) => sl<SearchBloc>()
            ..add(LoadPostDetails(
              id: id,
              category: category,
              locale: widget.currentLocale,
            )),
          child: PostCardPage(
            initialCategory: category,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: darkSlate, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
            onPressed: _showDeleteDialog,
          ),
          const SizedBox(width: 8),
        ],
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 20, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.recipientName.toUpperCase(),
                style: const TextStyle(
                  color: darkSlate,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ChatError) {
                  return Center(child: Text(state.message));
                }
                if (state is ChatLoaded) {
                  final messages = state.messages.reversed.toList();
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final bool isMe = msg.senderId != widget.recipientId;
                      return _buildMessageBubble(msg, isMe);
                    },
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          _buildInputArea(const Color(0xFF00F2FF), darkSlate),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: !isMe ? Border.all(color: Colors.black.withValues(alpha: 0.05)) : null,
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            HtmlWidget(
              msg.body,
              textStyle: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 15,
              ),
              onTapUrl: (url) => _handleUrlTap(url),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(msg.createdAt),
              style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(Color accentColor, Color textColor) {
    // Учитываем динамическую высоту системного навигационного бара (Safe Area)
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        12 + bottomInset, // Базовый отступ 12dp + высота системного бара
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(
                  hintText: 'Write a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _onSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}