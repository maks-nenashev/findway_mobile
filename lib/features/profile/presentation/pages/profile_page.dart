import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../../../injection_container.dart';
// 👉 ИСПОЛЬЗУЕМ ALIAS (auth), ЧТОБЫ ИЗБЕЖАТЬ КОНФЛИКТА С LogoutRequested
import '../../../auth/presentation/bloc/auth_bloc.dart' as auth;

class ProfilePage extends StatelessWidget {
  final String currentLocale;

  const ProfilePage({super.key, required this.currentLocale});

  @override
  Widget build(BuildContext context) {
    const Color neonCyan = Color(0xFF00F2FF);
    const Color darkSlate = Color(0xFF1E293B);

    // Локализация "на лету"
    final bool isUk = currentLocale == 'uk';
    final String txtMyAds = isUk ? 'МОЇ ОГОЛОШЕННЯ' : 'MY ADS';
    final String txtMessages = isUk ? 'ПОВІДОМЛЕННЯ' : 'MESSAGES';
    final String txtSignOut = isUk ? 'ВИХІД' : 'SIGN OUT';
    final String txtCabinet = isUk ? 'Мій кабінет' : 'My Profile';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: BlocConsumer<auth.AuthBloc, auth.AuthState>(
        listener: (context, authState) {
          if (authState is auth.AuthInitial) {
            // Если вышли — выбрасываем на логин и чистим историю навигации
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
                  slivers: [
                    // 1. НАВИГАЦИЯ (Стрелка назад и кнопка выхода)
                    SliverAppBar(
                      floating: true,
                      pinned: true,
                      backgroundColor: const Color(0xFFF0F4F8),
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

                    // 3. СТАТИСТИКА (Кликабельная)
                    SliverToBoxAdapter(
                      child: _buildStats(context, dash.stats, neonCyan, txtMyAds, txtMessages),
                    ),

                    // 4. СЕКЦИИ ОБЪЯВЛЕНИЙ
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final section = dash.sections[index];
                          if (section.items.isEmpty) return const SizedBox.shrink();
                          return _buildSection(section);
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
                          label: Text(txtSignOut, style: const TextStyle(color: Colors.redAccent, fontFamily: 'Orbitron')),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              }

              if (state is ProfileError) {
                return Center(child: Text('Error: ${state.message}'));
              }

              return const SizedBox();
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(dynamic user, Color accent, Color bg) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: accent,
            child: CircleAvatar(
              radius: 39,
              backgroundImage: (user.avatar != null && user.avatar.toString().isNotEmpty) 
                  ? NetworkImage(user.avatar) 
                  : null,
              child: (user.avatar == null) ? const Icon(Icons.person, size: 40) : null,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username.toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                Text(user.email, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
          _statItem(labelAds, stats.totalAds.toString(), accent),
          const SizedBox(width: 12),
          _statItem(labelMsg, stats.unreadMessages.toString(), Colors.orangeAccent, onTap: () {
            Navigator.pushNamed(context, '/chat'); // Убедись, что этот маршрут есть в main.dart
          }),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 8, fontFamily: 'Orbitron')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(dynamic section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
          child: Text(section.title.toUpperCase(), 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Orbitron', color: Color(0xFF1E293B))),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.items.length,
            itemBuilder: (context, index) {
              final item = section.items[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: (item.imageUrl != null)
                        ? Image.network(item.imageUrl, height: 90, width: 140, fit: BoxFit.cover)
                        : Container(height: 90, color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, 
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.1)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}