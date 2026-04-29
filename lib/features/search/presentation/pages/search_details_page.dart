import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_state.dart';
import '../../../../features/comments/presentation/bloc/comments_bloc.dart';
import '../../../../features/comments/presentation/bloc/comments_event.dart';
import '../../../../features/comments/presentation/bloc/comments_state.dart';
import '../../../../features/comments/data/models/comment_model.dart';
import '../../../../injection_container.dart';

class SearchDetailsPage extends StatelessWidget {
  const SearchDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is PostDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PostDetailsLoaded) {
            final post = state.post;
            final tr = state.uiTranslations;
            final String mappedCategory = _mapCategory(post.category);

            return BlocProvider(
              create: (context) => sl<CommentsBloc>(
                param1: post.id,
                param2: mappedCategory,
              )..add(const FetchComments()),
              child: Builder(
                builder: (pageContext) {
                  return CustomScrollView(
                    slivers: [
                      // 1. ГАЛЕРЕЯ (ОЖИВЛЕННАЯ)
                      _buildGallery(post),

                      // 2. КОНТЕНТНАЯ ЧАСТЬ ПОСТА
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAuthorHeader(post),
                              const Divider(height: 32),
                              Text(
                                post.title,
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                post.text,
                                style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              _buildLocationRow(post),
                              const SizedBox(height: 24),
                              
                              // ✅ ПАНЕЛЬ УПРАВЛЕНИЯ С НОВЫМИ КНОПКАМИ
                              _buildControlPanel(pageContext, tr),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),

                      // 3. СЕКЦИЯ КОММЕНТАРИЕВ
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr['comments_title'] ?? "Comments",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              _buildCommentsList(tr),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  );
                },
              ),
            );
          }

          if (state is SearchError) {
            return Center(child: Text("Помилка: ${state.message}", style: const TextStyle(color: Colors.red)));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ========== ЛОГИКА И ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ==========

  String _mapCategory(String? rawType) {
    final type = rawType?.toLowerCase() ?? 'article';
    if (type == 'article' || type == 'people') return 'people';
    if (type == 'sense' || type == 'animal' || type == 'animals') return 'animals';
    if (type == 'thing' || type == 'things') return 'things';
    return 'people';
  }

  void _showCommentSheet(BuildContext context, Map<String, dynamic> tr) {
    final controller = TextEditingController();
    final bloc = context.read<CommentsBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr['your_comment'] ?? "Your Comment",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: tr['place_writhe'] ?? "Напишіть щось...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  bloc.add(AddComment(controller.text.trim()));
                  Navigator.pop(context);
                }
              },
              child: Text(
                tr['submit_comment'] ?? "SUBMIT",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery(dynamic post) {
    return SliverAppBar(
      expandedHeight: 350.0,
      pinned: true,
      backgroundColor: const Color(0xFF0A0E14),
      flexibleSpace: FlexibleSpaceBar(
        background: _PostDetailsGallery(
          images: post.images != null ? List<String>.from(post.images) : [],
        ),
      ),
    );
  }

  // ✅ ПАНЕЛЬ УПРАВЛЕНИЯ (Старый дизайн кнопок + Новые действия + Скролл от переполнения)
  Widget _buildControlPanel(BuildContext context, Map<String, dynamic> tr) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _actionButton(Icons.arrow_back, Colors.white, () => Navigator.pop(context), bgColor: const Color(0xFF0A0E14)),
          const SizedBox(width: 12),
          _actionButton(Icons.alternate_email, Colors.cyan, () => debugPrint("Email Click")),
          const SizedBox(width: 12),
          _actionButton(Icons.chat_bubble_outline, Colors.orange, () => _showCommentSheet(context, tr)),
          const SizedBox(width: 12),
          _actionButton(Icons.edit_outlined, Colors.blueAccent, () => debugPrint("Edit Click")), // Новая кнопка Редактирования
          const SizedBox(width: 12),
          _actionButton(Icons.delete_outline, Colors.redAccent, () => debugPrint("Delete Click")), // Новая кнопка Удаления
        ],
      ),
    );
  }

  Widget _buildCommentsList(Map<String, dynamic> tr) {
    return BlocBuilder<CommentsBloc, CommentsState>(
      builder: (context, state) {
        if (state is CommentsLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        if (state is CommentsLoaded) {
          if (state.comments.isEmpty) {
            return const Center(child: Text("No comments yet", style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: state.comments.length,
            itemBuilder: (context, index) => _CommentNode(
              comment: state.comments[index],
              tr: tr,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAuthorHeader(dynamic post) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: post.author.avatarUrl != null ? NetworkImage(post.author.avatarUrl!) : null,
          child: post.author.avatarUrl == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("POSTED BY", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text(post.author.username, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const Spacer(),
        Text(post.createdAt, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildLocationRow(dynamic post) {
    return Row(
      children: [
        const Icon(Icons.location_on, color: Colors.blueAccent, size: 18),
        const SizedBox(width: 4),
        Text(post.local, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
      ],
    );
  }

  // ✅ ВОЗВРАТ К СТАРОМУ ДИЗАЙНУ КНОПОК
  Widget _actionButton(IconData icon, Color color, VoidCallback onTap, {Color? bgColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: bgColor ?? color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

// ========== ВНУТРЕННИЙ ВИДЖЕТ ГАЛЕРЕИ ДЛЯ ПОСТА ==========

class _PostDetailsGallery extends StatefulWidget {
  final List<String> images;
  const _PostDetailsGallery({required this.images});

  @override
  State<_PostDetailsGallery> createState() => _PostDetailsGalleryState();
}

class _PostDetailsGalleryState extends State<_PostDetailsGallery> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 50));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (int page) => setState(() => _currentPage = page),
          itemBuilder: (context, index) {
            // ✅ ИНТЕРАКТИВНАЯ КАРТИНКА (TAP-TO-FLIP) СОХРАНЕНА
            return GestureDetector(
              onTapUp: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx < screenWidth / 2) {
                  if (_currentPage > 0) {
                    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                } else {
                  if (_currentPage < widget.images.length - 1) {
                    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                }
              },
              child: Image.network(
                widget.images[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black87),
              ),
            );
          },
        ),
        
        // ГРАДИЕНТ НЕ БЛОКИРУЕТ НАЖАТИЯ
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black54],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),

        // Стрелки и индикаторы
        if (widget.images.length > 1) ...[
          if (_currentPage > 0)
            Positioned(
              left: 10, top: 0, bottom: 0,
              child: Center(
                child: _buildArrow(Icons.arrow_back_ios_new, () {
                  _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                }),
              ),
            ),
          if (_currentPage < widget.images.length - 1)
            Positioned(
              right: 10, top: 0, bottom: 0,
              child: Center(
                child: _buildArrow(Icons.arrow_forward_ios, () {
                  _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                }),
              ),
            ),
          Positioned(
            bottom: 20, left: 0, right: 0,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => _buildDot(index == _currentPage),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 4, width: isActive ? 16 : 4,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF00F2FF) : Colors.white54,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ========== ФУНКЦИИ И ВИДЖЕТЫ КОММЕНТАРИЕВ (БЕЗ ИЗМЕНЕНИЙ) ==========

void _showEditSheet(BuildContext context, CommentModel comment, Map<String, dynamic> tr) {
  final controller = TextEditingController(text: comment.body);
  final bloc = context.read<CommentsBloc>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tr['your_comment'] ?? "Редагувати", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent, 
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty && controller.text != comment.body) {
                bloc.add(UpdateComment(commentId: comment.id, newBody: controller.text.trim()));
              }
              Navigator.pop(context);
            },
            child: Text(tr['edit_comment'] ?? "ЗБЕРЕГТИ", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}

class _CommentNode extends StatelessWidget {
  final CommentModel comment;
  final Map<String, dynamic> tr;
  const _CommentNode({required this.comment, required this.tr});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: comment.avatarUrl != null ? NetworkImage(comment.avatarUrl!) : null,
            child: comment.avatarUrl == null ? const Icon(Icons.person, size: 20) : null,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(comment.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(comment.createdAt, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.body, style: const TextStyle(fontSize: 14)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (comment.canEdit)
                        GestureDetector(
                          onTap: () => _showEditSheet(context, comment, tr),
                          child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.edit_outlined, size: 18, color: Colors.blueAccent)),
                        ),
                      if (comment.canDelete)
                        GestureDetector(
                          onTap: () => context.read<CommentsBloc>().add(DeleteComment(commentId: comment.id)),
                          child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}