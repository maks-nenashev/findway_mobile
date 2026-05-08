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

 // 1. Обновленная секция (увеличена общая высота)
  Widget _buildSection(BuildContext context, dynamic section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF00F2FF), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(section.title.toUpperCase(), 
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, fontFamily: 'Orbitron', color: Color(0xFF1E293B), letterSpacing: 1.0)),
            ],
          ),
        ),
        SizedBox(
          height: 220, // 👉 Высота увеличена, чтобы дать "воздух" тексту
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

  // 2. Полностью переработанная карточка объявления
  Widget _buildAdCard(BuildContext context, dynamic item, String category) {
    return Container(
      width: 160, // 👉 Карточка стала шире
      margin: const EdgeInsets.only(right: 16, bottom: 16), // Отступ для тени
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1), // Тонкая рамка для контраста
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, '/post_details', arguments: {
              'id': item.id,
              'category': category,
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 🖼 КАРТИНКА (Зафиксирована высота) ---
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: (item.imageUrl != null && item.imageUrl.toString().isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildPlaceholder(),
                        errorWidget: (context, url, error) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
                ),
              ),
              // --- 📝 ТЕКСТ (Занимает оставшееся место) ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Заголовок (Expanded выталкивает кнопку вниз)
                      Expanded(
                        child: Text(
                          item.title, 
                          maxLines: 2, 
                          overflow: TextOverflow.ellipsis, 
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.2, color: Color(0xFF1E293B))
                        ),
                      ),
                      // Кнопка-индикатор в самом низу
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(), // Пустое место слева (позже сюда добавим дату)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Text("ДЕТАЛІ", style: TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 8, color: const Color(0xFF64748B)),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_back_outlined, color: Colors.blueGrey.withOpacity(0.3), size: 36),
            const SizedBox(height: 6),
            Text("NO PHOTO", style: TextStyle(fontSize: 9, color: Colors.blueGrey.withOpacity(0.5), fontWeight: FontWeight.bold, fontFamily: 'Orbitron', letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }
}