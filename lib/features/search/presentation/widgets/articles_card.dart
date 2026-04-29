import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../pages/post_card_page.dart';

class ArticleCard extends StatefulWidget {
  final dynamic post;
  final String currentLocale;

  const ArticleCard({required this.post, required this.currentLocale, Key? key}) : super(key: key);

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  late PageController _pageController;
  int _currentPage = 0;
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _parseImages();
  }

void _parseImages() {
    final List<String> temp = [];
    final dynamic imagesData = widget.post['images_urls'] ?? widget.post['images'] ?? widget.post['photos'];

    if (imagesData is List && imagesData.isNotEmpty) {
      temp.addAll(imagesData.map((e) => e.toString()));
    } else if (widget.post['image_url'] != null) {
      temp.add(widget.post['image_url'].toString());
    }

    // ✅ ОБНОВЛЕННАЯ ЛОГИКА ЗАГЛУШЕК ДЛЯ КАРТОЧКИ
    if (temp.isEmpty) {
      // Пытаемся достать категорию из данных поста
      final String cat = (widget.post['category'] ?? '').toString().toLowerCase();
      
      switch (cat) {
        case 'animals':
          temp.add('assets/images/cat.png');
          break;
        case 'things':
          temp.add('assets/images/things.png');
          break;
        case 'people':
        default:
          temp.add('assets/images/peop.png');
          break;
      }
    }

    setState(() => _images = temp);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String statusLabel = (widget.post['choice_label'] ?? '').toString().toUpperCase();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. ПЕРЕЛИСТЫВАНИЕ (Нижний слой)
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final imgPath = _images[index];
                  // ✅ ИСПРАВЛЕНО: Детектор нажатий возвращен на саму картинку.
                  // Теперь PageView снова может ловить жесты свайпа.
                  return GestureDetector(
                    onTap: _navigateToDetails,
                    child: imgPath.startsWith('http')
                        ? Image.network(
                            imgPath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset('assets/images/peop.png', fit: BoxFit.cover),
                          )
                        : Image.asset(
                            imgPath,
                            fit: BoxFit.cover,
                          ),
                  );
                },
              ),
            ),

            // 2. ГРАДИЕНТ (Визуал - сквозной благодаря IgnorePointer)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    ),
                  ),
                ),
              ),
            ),

            // 3. ТЕКСТ (Пропускает нажатия сквозь себя на картинку)
            Positioned(
              left: 12, right: 12, bottom: 12,
              child: IgnorePointer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (statusLabel.isNotEmpty) _buildStatusBadge(statusLabel),
                    Text(
                      widget.post['title'] ?? "",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Orbitron'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // 4. УПРАВЛЕНИЕ (Верхний слой, перехватывает клики только на своих элементах)
            if (_images.length > 1) ...[
              if (_currentPage > 0)
                Positioned(
                  left: 5, top: 0, bottom: 0,
                  child: Center(child: _buildArrow(Icons.arrow_back_ios_new, () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease))),
                ),
              if (_currentPage < _images.length - 1)
                Positioned(
                  right: 5, top: 0, bottom: 0,
                  child: Center(child: _buildArrow(Icons.arrow_forward_ios, () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease))),
                ),
              Positioned(
                bottom: 50, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_images.length, (i) => _buildDot(i == _currentPage)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToDetails() async {
    final bloc = context.read<SearchBloc>();
    bloc.add(LoadPostDetails(
      id: widget.post['id'],
      category: widget.post['category'] ?? 'people',
      locale: widget.currentLocale,
    ));
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BlocProvider.value(value: bloc, child: const SearchDetailsPage())),
    );
    if (context.mounted) bloc.add(RestoreSearch());
  }

  Widget _buildStatusBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00F2FF).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF00F2FF), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF00F2FF), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
    );
  }

  Widget _buildArrow(IconData icon, VoidCallback action) {
    return GestureDetector(
      onTap: action,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildDot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      height: 3, width: active ? 10 : 3,
      decoration: BoxDecoration(color: active ? const Color(0xFF00F2FF) : Colors.white38, borderRadius: BorderRadius.circular(2)),
    );
  }
}