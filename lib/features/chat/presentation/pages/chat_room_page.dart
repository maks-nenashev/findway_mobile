import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  // FindWay visual identity: deep navy cards, neon cyan outlines,
  // electric-blue actions and warm orange secondary accents.
  static const Color _pageBackground = Color(0xFFF4F5FA);
  static const Color _surface = Color(0xFF151529);
  static const Color _surfaceRaised = Color(0xFF1D293B);
  static const Color _navBackground = Color(0xFF080812);
  static const Color _accentBlue = Color(0xFF3478FF);
  static const Color _accentCyan = Color(0xFF00E5FF);
  static const Color _accentRed = Color(0xFFFF365B);
  static const String _logoAsset = 'assets/images/findway_logo.png';
  static const int _systemUserId = 1;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool get _isSystemUser => widget.recipientId == _systemUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    context.read<ChatBloc>().add(
          FetchMessages(
            recipientId: widget.recipientId,
            locale: widget.currentLocale,
          ),
        );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _translationsForState(ChatState state) {
    if (state is ChatLoaded) return state.translations;
    if (state is ChatLoading) return state.translations;
    if (state is InboxLoaded) return state.translations;
    return const <String, dynamic>{};
  }

  String _translation(
    Map<String, dynamic> translations,
    String key, {
    required String fallback,
  }) {
    final value = translations[key];
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  /// Reads centralized Rails translations from the current ChatBloc state.
  /// Keep a readable fallback in case the metadata endpoint is temporarily unavailable.
  String _tr(String key, {required String fallback}) {
    final translations = _translationsForState(context.read<ChatBloc>().state);
    return _translation(translations, key, fallback: fallback);
  }

  void _onSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(
          SendMessage(
            recipientId: widget.recipientId,
            body: text,
            locale: widget.currentLocale,
          ),
        );
    _messageController.clear();
  }

  /// Handles links in chat messages: internal FindWay entities first,
  /// external HTTP(S) URLs second. This keeps existing post navigation intact.
  Future<bool> _handleUrlTap(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return true;

    try {
      final normalizedUrl = cleanUrl.toLowerCase().startsWith('www.')
          ? 'https://$cleanUrl'
          : cleanUrl;
      final uri = Uri.tryParse(normalizedUrl);
      if (uri == null) return true;

      const entityMapping = <String, String>{
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
        'animals': 'animal',
        'animal': 'animal',
      };

      final segments = uri.pathSegments;
      for (var i = 0; i < segments.length - 1; i++) {
        final entityType = entityMapping[segments[i].toLowerCase()];
        final entityId = int.tryParse(segments[i + 1]);
        if (entityType != null && entityId != null) {
          debugPrint(
            '[ChatRoom] Internal link tapped -> Opening $entityType #$entityId',
          );
          _navigateToEntity(entityType, entityId);
          return true;
        }
      }

      if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
        final host = uri.host.toLowerCase();
        final isInternalHost = host.contains('findway') ||
            host == 'localhost' ||
            host == '127.0.0.1' ||
            host.startsWith('10.') ||
            host.startsWith('192.168.');

        if (!isInternalHost) {
          final opened = await canLaunchUrl(uri) &&
              await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!opened && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: _surface,
                behavior: SnackBarBehavior.floating,
                content: Text(
                  _tr(
                    'messages.show.link_error',
                    fallback: 'Could not open the link',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[ChatRoom] Error in _handleUrlTap: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _surface,
            behavior: SnackBarBehavior.floating,
            content: Text(
              _tr(
                'messages.show.link_error',
                fallback: 'Could not open the link',
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }

    return true;
  }

  /// Opens the real post detail page for a FindWay entity URL.
  void _navigateToEntity(String entityType, int id) {
    if (!mounted) return;

    String category = 'people';
    if (entityType == 'biometric' ||
        entityType == 'biometric_match' ||
        entityType == 'sense' ||
        entityType == 'animal') {
      category = 'animals';
    } else if (entityType == 'item' || entityType == 'thing') {
      category = 'things';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider<SearchBloc>(
          create: (context) => sl<SearchBloc>()
            ..add(
              LoadPostDetails(
                id: id,
                category: category,
                locale: widget.currentLocale,
              ),
            ),
          child: PostCardPage(initialCategory: category),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _accentRed.withValues(alpha: 0.65)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _accentRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: _accentRed.withValues(alpha: 0.7)),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: _accentRed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _tr('api.delete.delete_title', fallback: 'Delete chat?'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          _tr(
            'api.delete.delete_message',
            fallback: 'This will permanently erase all messages for both sides.',
          ),
          style: const TextStyle(
            color: Color(0xFF9BA5BE),
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              _tr('api.delete.cancel', fallback: 'Cancel'),
              style: const TextStyle(
                color: _accentCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _accentRed.withValues(alpha: 0.16),
              foregroundColor: _accentRed,
              side: const BorderSide(color: _accentRed, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            ),
            onPressed: () {
              context.read<ChatBloc>().add(
                    DeleteChat(recipientId: widget.recipientId),
                  );
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(
              _tr('api.delete.confirm', fallback: 'Delete').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({
    required double radius,
    required bool systemUser,
  }) {
    if (systemUser) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _surfaceRaised,
        child: ClipOval(
          child: Image.asset(
            _logoAsset,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.location_on_rounded,
              color: _accentCyan,
              size: radius * 1.35,
            ),
          ),
        ),
      );
    }

    final url = widget.avatarUrl;
    if (url != null && url.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _surfaceRaised,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: _surfaceRaised,
      child: Icon(
        Icons.person_rounded,
        size: radius * 1.15,
        color: _accentCyan,
      ),
    );
  }

  Widget _buildEmptyConversation(Map<String, dynamic> translations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _accentCyan.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: _accentCyan.withValues(alpha: 0.09),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _surfaceRaised,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _accentCyan.withValues(alpha: 0.7)),
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  size: 32,
                  color: _accentCyan,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _translation(
                  translations,
                  'messages.show.empty_conversation',
                  fallback: 'Start the conversation',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _translation(
                  translations,
                  'messages.show.empty_conversation_hint',
                  fallback: 'Write a message to get things going.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9BA5BE),
                  fontSize: 13,
                  height: 1.45,
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _surface,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _navBackground,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: _pageBackground,
        appBar: AppBar(
          toolbarHeight: 76,
          backgroundColor: _surface,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: _surface,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 58,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              tooltip: _tr('messages.show.back', fallback: 'Back'),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _accentCyan,
                size: 19,
              ),
            ),
          ),
          titleSpacing: 2,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _accentCyan, width: 1.3),
                  boxShadow: [
                    BoxShadow(
                      color: _accentCyan.withValues(alpha: 0.18),
                      blurRadius: 9,
                    ),
                  ],
                ),
                child: _buildAvatar(radius: 21, systemUser: _isSystemUser),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.recipientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: _accentRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _accentRed.withValues(alpha: 0.75)),
                  boxShadow: [
                    BoxShadow(
                      color: _accentRed.withValues(alpha: 0.10),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: _tr('api.delete.delete_title', fallback: 'Delete chat'),
                  onPressed: _showDeleteDialog,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: _accentRed,
                    size: 21,
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                color: _accentCyan.withValues(alpha: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: _accentCyan.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(_accentCyan),
                        ),
                      ),
                    );
                  }

                  if (state is ChatError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _accentCyan.withValues(alpha: 0.55),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off_rounded,
                                size: 38,
                                color: _accentCyan,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFE9F0FF),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _accentCyan,
                                  side: const BorderSide(color: _accentCyan),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _loadMessages,
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(
                                  _tr('messages.show.try_again', fallback: 'Try again'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (state is ChatLoaded) {
                    final messages = state.messages.reversed.toList();
                    if (messages.isEmpty) {
                      return _buildEmptyConversation(state.translations);
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(13, 15, 13, 22),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final bool isMe = msg.senderId != widget.recipientId;
                        return _buildMessageBubble(msg, isMe);
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  /// Clean, familiar chat bubbles: quiet surfaces, readable text and no neon outlines.
  /// The FindWay identity remains in the header and composer, as requested.
  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    final bool isSystemMessage = !isMe && msg.senderId == _systemUserId;

    const Color messageTextColor = Color(0xFF1E293B);
    const Color incomingBackground = Color(0xFFFFFFFF);
    const Color outgoingBackground = Color(0xFFE7F7F7);
    const Color incomingBorder = Color(0xFFE5EAF1);
    const Color outgoingBorder = Color(0xFFC7E8E7);
    const Color incomingTimestamp = Color(0xFF8791A3);
    const Color outgoingTimestamp = Color(0xFF4B8585);
    const Color incomingLink = Color(0xFF2563EB);
    const Color outgoingLink = Color(0xFF087F8C);

    final Color bubbleBackground = isMe ? outgoingBackground : incomingBackground;
    final Color bubbleBorder = isMe ? outgoingBorder : incomingBorder;
    final Color timestampColor = isMe ? outgoingTimestamp : incomingTimestamp;
    final Color linkColor = isMe ? outgoingLink : incomingLink;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isSystemMessage) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _buildAvatar(radius: 14, systemUser: true),
              ),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.80,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(15, 11, 14, 8),
                  decoration: BoxDecoration(
                    color: bubbleBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 6),
                      bottomRight: Radius.circular(isMe ? 6 : 18),
                    ),
                    border: Border.all(color: bubbleBorder, width: 0.8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D182235),
                        blurRadius: 7,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LinkifiedMessageText(
                        text: msg.body,
                        textColor: messageTextColor,
                        linkColor: linkColor,
                        onUrlTap: _handleUrlTap,
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          DateFormat('HH:mm').format(msg.createdAt),
                          style: TextStyle(
                            color: timestampColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 13, 12, 8 + bottomInset),
      decoration: BoxDecoration(
        color: _navBackground,
        border: Border(
          top: BorderSide(color: _accentCyan.withValues(alpha: 0.85), width: 1.1),
        ),
        boxShadow: [
          BoxShadow(
            color: _accentCyan.withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 0.5,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141629),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: _accentCyan.withValues(alpha: 0.66),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accentCyan.withValues(alpha: 0.07),
                    blurRadius: 11,
                  ),
                ],
              ),
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  final translations = _translationsForState(state);
                  final hint = _translation(
                    translations,
                    'messages.show.placeholder_message',
                    fallback: 'Write a message...',
                  );

                  return TextField(
                    controller: _messageController,
                    maxLines: 5,
                    minLines: 1,
                    cursorColor: _accentCyan,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.35,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        color: Color(0xFF7D879F),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 13, right: 8),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF63718D),
                          size: 19,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 42),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _onSend(),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, value, _) {
              final canSend = value.text.trim().isNotEmpty;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 51,
                height: 51,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: canSend
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_accentCyan, _accentBlue],
                        )
                      : null,
                  color: canSend ? null : const Color(0xFF191C30),
                  border: Border.all(
                    color: canSend
                        ? _accentCyan
                        : _accentCyan.withValues(alpha: 0.48),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accentCyan.withValues(alpha: canSend ? 0.30 : 0.09),
                      blurRadius: canSend ? 16 : 8,
                      spreadRadius: canSend ? 0.5 : 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: canSend ? _onSend : null,
                    child: Icon(
                      Icons.send_rounded,
                      color: canSend ? _navBackground : _accentCyan,
                      size: 22,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}

/// Displays plain text, HTML links and regular URLs as tappable links.
class _LinkifiedMessageText extends StatefulWidget {
  final String text;
  final Color textColor;
  final Color linkColor;
  final Future<bool> Function(String url) onUrlTap;

  const _LinkifiedMessageText({
    required this.text,
    required this.textColor,
    required this.linkColor,
    required this.onUrlTap,
  });

  @override
  State<_LinkifiedMessageText> createState() => _LinkifiedMessageTextState();
}

class _LinkifiedMessageTextState extends State<_LinkifiedMessageText> {
  static final RegExp _htmlAnchorPattern = RegExp(
    r'<a\b[^>]*href\s*=\s*["\x27]([^"\x27]+)["\x27][^>]*>(.*?)</a\s*>',
    caseSensitive: false,
    dotAll: true,
  );

  static final RegExp _htmlTagPattern = RegExp(r'<[^>]*>');
  static final RegExp _urlPattern = RegExp(
    r'((?:https?://|www\.)[^\s<>"\u0000-\u001F]+)',
    caseSensitive: false,
  );
  static final RegExp _htmlEntityPattern = RegExp(
    r'&(?:amp|lt|gt|quot|apos|#39|#\d+|#x[0-9a-fA-F]+);',
    caseSensitive: false,
  );

  final List<TapGestureRecognizer> _recognizers = [];
  late List<InlineSpan> _spans;

  @override
  void initState() {
    super.initState();
    _spans = _buildMessageSpans(widget.text);
  }

  @override
  void didUpdateWidget(covariant _LinkifiedMessageText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.linkColor != widget.linkColor) {
      _disposeRecognizers();
      _spans = _buildMessageSpans(widget.text);
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  String _decodeHtml(String input) {
    return input.replaceAllMapped(_htmlEntityPattern, (match) {
      final entity = match.group(0)!;
      final value = entity.substring(1, entity.length - 1);

      switch (value.toLowerCase()) {
        case 'amp':
          return '&';
        case 'lt':
          return '<';
        case 'gt':
          return '>';
        case 'quot':
          return '"';
        case 'apos':
        case '#39':
          return "'";
      }

      try {
        if (value.startsWith('#x') || value.startsWith('#X')) {
          final codePoint = int.parse(value.substring(2), radix: 16);
          if (codePoint >= 0 && codePoint <= 0x10FFFF) {
            return String.fromCharCode(codePoint);
          }
        } else if (value.startsWith('#')) {
          final codePoint = int.parse(value.substring(1));
          if (codePoint >= 0 && codePoint <= 0x10FFFF) {
            return String.fromCharCode(codePoint);
          }
        }
      } catch (_) {
        // Keep the original entity if it cannot be decoded.
      }

      return entity;
    });
  }

  String _cleanUrl(String value) {
    var url = value;
    while (url.isNotEmpty &&
        RegExp(r'[.,!?;:)\]}]').hasMatch(url[url.length - 1])) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  String _normalizeUrl(String value) {
    final cleaned = _decodeHtml(_cleanUrl(value.trim()));
    if (cleaned.toLowerCase().startsWith('www.')) {
      return 'https://$cleaned';
    }
    return cleaned;
  }

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(_normalizeUrl(value));
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  bool _isInternalEntityUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;

    const entitySegments = <String>{
      'biometrics', 'biometric', 'biometric_matches', 'biometric_match',
      'articles', 'article', 'posts', 'post', 'matches', 'match',
      'items', 'item', 'senses', 'sense', 'things', 'thing',
      'people', 'animals', 'animal',
    };

    final segments = uri.pathSegments;
    for (var i = 0; i < segments.length - 1; i++) {
      if (entitySegments.contains(segments[i].toLowerCase()) &&
          int.tryParse(segments[i + 1]) != null) {
        return true;
      }
    }
    return false;
  }

  bool _isClickableUrl(String value) =>
      _isHttpUrl(value) || _isInternalEntityUrl(value);

  TapGestureRecognizer _createRecognizer(String url) {
    final recognizer = TapGestureRecognizer()..onTap = () => widget.onUrlTap(url);
    _recognizers.add(recognizer);
    return recognizer;
  }

  List<InlineSpan> _buildPlainTextSpans(String text) {
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _urlPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      final matchedText = match.group(0)!;
      final url = _cleanUrl(matchedText);
      final trailing = matchedText.substring(url.length);

      if (url.isNotEmpty && _isHttpUrl(url)) {
        spans.add(
          TextSpan(
            text: url,
            style: TextStyle(
              color: widget.linkColor,
              decoration: TextDecoration.underline,
              decorationColor: widget.linkColor,
            ),
            recognizer: _createRecognizer(url),
          ),
        );
      } else if (url.isNotEmpty) {
        spans.add(TextSpan(text: url));
      }

      if (trailing.isNotEmpty) {
        spans.add(TextSpan(text: trailing));
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return spans;
  }

  List<InlineSpan> _buildMessageSpans(String source) {
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final match in _htmlAnchorPattern.allMatches(source)) {
      if (match.start > cursor) {
        final before = source.substring(cursor, match.start);
        final cleanedBefore = before.replaceAll(_htmlTagPattern, '');
        spans.addAll(_buildPlainTextSpans(_decodeHtml(cleanedBefore)));
      }

      final href = _decodeHtml(match.group(1)!.trim());
      final label = _decodeHtml(
        match.group(2)!.replaceAll(_htmlTagPattern, ''),
      );

      if (_isClickableUrl(href)) {
        spans.add(
          TextSpan(
            text: label,
            style: TextStyle(
              color: widget.linkColor,
              decoration: TextDecoration.underline,
              decorationColor: widget.linkColor,
            ),
            recognizer: _createRecognizer(href),
          ),
        );
      } else {
        spans.add(TextSpan(text: label));
      }
      cursor = match.end;
    }

    if (cursor < source.length) {
      final remainder = source.substring(cursor).replaceAll(_htmlTagPattern, '');
      spans.addAll(_buildPlainTextSpans(_decodeHtml(remainder)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(
        style: TextStyle(
          color: widget.textColor,
          fontSize: 15,
          height: 1.35,
        ),
        children: _spans,
      ),
    );
  }
}