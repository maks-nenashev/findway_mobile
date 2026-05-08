import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart' as auth;

class ProfilePage extends StatelessWidget {
  final String currentLocale;

  const ProfilePage({super.key, required this.currentLocale});

  @override
  Widget build(BuildContext context) {
    const Color neonCyan = Color(0xFF00F2FF);
    const Color darkSlate = Color(0xFF1E293B);

    final bool isUk = currentLocale == 'uk';
    final String txtMyAds = isUk ? 'МОЇ ОГОЛОШЕННЯ' : 'MY ADS';
    final String txtMessages = isUk ? 'ПОВІДОМЛЕННЯ' : 'MESSAGES';
    final String txtSignOut = isUk ? 'ВИХІД' : 'SIGN OUT';
    final String txtCabinet = isUk ? 'Мій кабінет' : 'My Profile';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: BlocConsumer<auth.AuthBloc, auth.AuthState>(
        listener: (context, authState) {
          if (authState is auth.AuthInitial) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
        builder: (context, authState) {
          return BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading) {
                return const Center(child: CircularProgressIndicator(color: neonCyan));
              }

              if (state is ProfileLoaded) {
                final dash = state.dashboard;
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 1. НАВИГАЦИЯ
                    SliverAppBar(
                      floating: true,
                      pinned: true,
                      backgroundColor: const Color(0xFFF8FAFC),
                      elevation: 0,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: darkSlate),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      title: Text(txtCabinet, 
                        style: const TextStyle(color: darkSlate, fontSize: 18, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.redAccent),
                          onPressed: () => context.read<auth.AuthBloc>().add(auth.LogoutRequested()),
                        ),
                      ],
                    ),

                    // 2. ШАПКА ПРОФИЛЯ
                    SliverToBoxAdapter(
                      child: _buildHeader(dash.user, neonCyan, darkSlate),
                    ),

                    // 3. СТАТИСТИКА
                    SliverToBoxAdapter(
                      child: _buildStats(context, dash.stats, neonCyan, txtMyAds, txtMessages),
                    ),

                    // 4. СЕКЦИИ ОБЪЯВЛЕНИЙ
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final section = dash.sections[index];
                          if (section.items.isEmpty) return const SizedBox.shrink();
                          return _buildSection(context, section);
                        },
                        childCount: dash.sections.length,
                      ),
                    ),

                    // 5. НИЖНЯЯ КНОПКА ВЫХОДА
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                      sliver: SliverToBoxAdapter(
                        child: OutlinedButton.icon(
                          onPressed: () => context.read<auth.AuthBloc>().add(auth.LogoutRequested()),
                          icon: const Icon(Icons.logout, color: Colors.redAccent),
                          label: Text(txtSignOut, style: const TextStyle(color: Colors.redAccent, fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 50)),
                  ],
                );
              }

              if (state is ProfileError) {
                return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)));
              }

              return const SizedBox();
            },
          );
        },
      ),
    );
  }

  // =======================================================================
  // UI КОМПОНЕНТЫ
  // =======================================================================

  Widget _buildHeader(dynamic user, Color accent, Color bg) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: bg.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: accent,
            child: CircleAvatar(
              radius: 39,
              backgroundColor: Colors.white24,
              backgroundImage: (user.avatarUrl != null && user.avatarUrl.toString().isNotEmpty) 
                  ? CachedNetworkImageProvider(user.avatarUrl) 
                  : null,
              child: (user.avatarUrl == null || user.avatarUrl.toString().isEmpty) 
                  ? const Icon(Icons.person, size: 40, color: Colors.white) 
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username.toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(user.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, dynamic stats, Color accent, String labelAds, String labelMsg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statItem(labelAds, stats.totalAds.toString(), Icons.dashboard_customize, accent, onTap: () {}),
          const SizedBox(width: 16),
          _statItem(labelMsg, stats.unreadMessages.toString(), Icons.mail_outline, Colors.orangeAccent, onTap: () {
            Navigator.pushNamed(context, '/chat'); 
          }),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, fontFamily: 'Orbitron', fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // --- ИСПРАВЛЕННЫЕ СЕКЦИИ ОБЪЯВЛЕНИЙ (Full Photo) ---

  Widget _buildSection(BuildContext context, dynamic section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Row(
            children: [
              Container(width: 4, height: 18, decoration: BoxDecoration(color: const Color(0xFF00F2FF), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(section.title.toUpperCase(), 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Orbitron', color: Color(0xFF1E293B), letterSpacing: 1.2)),
            ],
          ),
        ),
        SizedBox(
          height: 170, // Высота для красивых пропорций карточки 16:9
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.items.length,
            itemBuilder: (context, index) {
              final item = section.items[index];
              return _buildAdCard(context, item, section.category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdCard(BuildContext context, dynamic item, String category) {
    return Container(
      width: 160, // Ширина карточки
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        // Белый фон убираем, так как картинка занимает всё место
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.1), // Тень чуть гуще
            blurRadius: 10, 
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // ТЕПЕРЬ НАВИГАЦИЯ НЕ БУДЕТ ВЫБРАСЫВАТЬ (после ЭТАПА 1)
            Navigator.pushNamed(context, '/post_details', arguments: {
              'id': item.id,
              'category': category,
            });
          },
          // 👈 ВОТ КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: Архитектура Stack
          child: Stack(
            children: [
              // 1. Слой картинки (занимает ВСЁ место)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: (item.imageUrl != null && item.imageUrl.toString().isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                        errorWidget: (context, url, error) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
                ),
              ),
              // 2. Слой градиента (для читаемости текста на любом фото)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.8), // Темный низ
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // 3. Слой текста (наложен поверх градиента)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title, 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis, 
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.2, color: Colors.white), // Текст белый
                    ),
                    const SizedBox(height: 4),
                    // Визуальный индикатор (белый/циан)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text("ДЕТАЛІ", style: TextStyle(fontSize: 9, color: Color(0xFF00F2FF), fontWeight: FontWeight.w600, fontFamily: 'Orbitron')),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 8, color: Color(0xFF00F2FF)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Эстетичная заглушка (тоже градиентная)
  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF334155), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_back_outlined, color: Colors.white.withOpacity(0.2), size: 36),
            const SizedBox(height: 6),
            Text("NO PHOTO", style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }
}