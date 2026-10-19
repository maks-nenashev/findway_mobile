import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart' as auth;
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfilePage extends StatefulWidget {
  final String currentLocale;

  const ProfilePage({super.key, required this.currentLocale});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _navy = Color(0xFF121629);
  static const Color _navyLight = Color(0xFF20283D);
  static const Color _cyan = Color(0xFF00E5F2);
  static const Color _orange = Color(0xFFFF8A00);
  static const Color _green = Color(0xFF25C878);
  static const Color _pageBackground = Color(0xFFFFFFFF);

  Map<String, dynamic> _translations = const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _loadTranslationsAndRefresh();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocale != widget.currentLocale) {
      _loadTranslationsAndRefresh();
    }
  }

  void _loadTranslationsAndRefresh() {
    final cleanLocale = widget.currentLocale.trim().toLowerCase().split(RegExp('[-_]')).first;
    
    // 1. Загружаем словари перевода UI
    _loadTranslations(cleanLocale);
    
    // 2. Уведомляем ProfileBloc о необходимости перезапросить данные с бэкенда на новой локали
    context.read<ProfileBloc>().add(FetchProfileEvent(locale: cleanLocale));
  }

  Future<void> _loadTranslations(String locale) async {
    try {
      final response = await sl<Dio>().get(
        '/api/v1/search/new_meta',
        queryParameters: {'locale': locale},
      );

      final dynamic body = response.data;
      if (body is! Map) return;

      final dynamic rawTranslations = body['translations'] ?? body;
      if (rawTranslations is! Map) return;

      final translations = <String, dynamic>{};
      _flattenTranslations(rawTranslations, translations);

      if (!mounted) return;
      setState(() {
        _translations = translations;
      });
    } catch (error) {
      debugPrint('ProfilePage i18n: failed to load Rails translations: $error');
    }
  }

  void _flattenTranslations(
    Map<dynamic, dynamic> source,
    Map<String, dynamic> target, [
    String prefix = '',
  ]) {
    source.forEach((dynamic rawKey, dynamic value) {
      final key = rawKey.toString();
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map) {
        _flattenTranslations(value, target, fullKey);
      } else if (value != null && value.toString().trim().isNotEmpty) {
        final strVal = value.toString();
        target[fullKey] = strVal;
        target[fullKey.toLowerCase()] = strVal;
        target[key] = strVal;
        target[key.toLowerCase()] = strVal;
      }
    });
  }

  String _tr(String key, String fallback) {
    if (_translations.isEmpty) return fallback;

    var value = _translations[key];
    if (value != null && value.toString().trim().isNotEmpty) return value.toString();

    value = _translations[key.toLowerCase()];
    if (value != null && value.toString().trim().isNotEmpty) return value.toString();

    final lastSegment = key.split('.').last;
    value = _translations[lastSegment];
    if (value != null && value.toString().trim().isNotEmpty) return value.toString();

    value = _translations[lastSegment.toLowerCase()];
    if (value != null && value.toString().trim().isNotEmpty) return value.toString();

    return fallback;
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');

  String _localizedSectionTitle(dynamic section) {
    final rawTitle = (section.title ?? '').toString();
    final category = _normalize((section.category ?? '').toString());

    if (category == 'people' || category.contains('article')) {
      return _tr('dashboard.index.people', 'People');
    }
    if (category == 'animals' || category.contains('sense')) {
      return _tr('dashboard.index.animals', 'Animals');
    }
    if (category == 'things' || category.contains('thing')) {
      return _tr('dashboard.index.things', 'Things');
    }

    return _tr('dashboard.index.$category', rawTitle.isNotEmpty ? rawTitle : category);
  }

  String _categoryKey(dynamic section) {
    final raw = _normalize((section.category ?? section.title ?? '').toString());
    if (raw.contains('animal') || raw.contains('sense') || raw.contains('pet')) {
      return 'animals';
    }
    if (raw.contains('thing') || raw.contains('item') || raw.contains('artifact')) {
      return 'things';
    }
    return 'people';
  }

  Color _sectionAccent(dynamic section) {
    switch (_categoryKey(section)) {
      case 'animals':
        return _orange;
      case 'things':
        return _green;
      default:
        return _cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: BlocConsumer<auth.AuthBloc, auth.AuthState>(
        listener: (context, authState) {
          if (authState is auth.AuthInitial) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
        },
        builder: (context, authState) {
          return BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: _cyan),
                );
              }

              if (state is ProfileLoaded) {
                final dashboard = state.dashboard;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      pinned: true,
                      backgroundColor: _navy,
                      elevation: 0,
                      leading: IconButton(
                        tooltip: _tr('messages.back', 'Back'),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: _cyan,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      title: Text(
                        _tr('dashboard.index.profil', 'Profile').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.7,
                        ),
                      ),
                      actions: [
                        IconButton(
                          tooltip: _tr('menu.exit', 'Logout'),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFFF5A69),
                          ),
                          onPressed: () => context
                              .read<auth.AuthBloc>()
                              .add(auth.LogoutRequested()),
                        ),
                        const SizedBox(width: 6),
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(2),
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: _cyan,
                            boxShadow: [
                              BoxShadow(
                                color: _cyan.withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildHeader(dashboard.user),
                    ),
                    SliverToBoxAdapter(
                      child: _buildStats(
                        context,
                        dashboard.stats,
                        _tr('dashboard.index.ads', 'My posts'),
                        _tr('dashboard.index.messages', 'Messages'),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final section = dashboard.sections[index];
                          if (section.items.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return _buildSection(context, section);
                        },
                        childCount: dashboard.sections.length,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                      sliver: SliverToBoxAdapter(
                        child: OutlinedButton.icon(
                          onPressed: () => context
                              .read<auth.AuthBloc>()
                              .add(auth.LogoutRequested()),
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFFF5A69),
                          ),
                          label: Text(
                            _tr('menu.exit', 'LOGOUT').toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFFF5A69),
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: const Color(0xFFFF5A69)
                                  .withValues(alpha: 0.65),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                );
              }

              if (state is ProfileError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: ${state.message}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cyan.withValues(alpha: 0.75), width: 1),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [_cyan, Color(0xFF3C82FF), _green, _cyan],
              ),
            ),
            child: CircleAvatar(
              radius: 37,
              backgroundColor: _navy,
              backgroundImage:
                  (user.avatarUrl != null &&
                          user.avatarUrl.toString().isNotEmpty)
                      ? CachedNetworkImageProvider(user.avatarUrl.toString())
                      : null,
              child: (user.avatarUrl == null ||
                      user.avatarUrl.toString().isEmpty)
                  ? const Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: Colors.white70,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email.toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB9C4D5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _cyan.withValues(alpha: 0.09),
                    border: Border.all(
                      color: _cyan.withValues(alpha: 0.35),
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _tr('menu.personal_account', 'Personal account').toUpperCase(),
                        style: const TextStyle(
                          color: _cyan,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.7,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(
    BuildContext context,
    dynamic stats,
    String labelAds,
    String labelMessages,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statItem(
            label: labelAds,
            value: stats.totalAds.toString(),
            icon: Icons.grid_view_rounded,
            accent: _cyan,
          ),
          const SizedBox(width: 12),
          _statItem(
            label: labelMessages,
            value: stats.unreadMessages.toString(),
            icon: Icons.markunread_rounded,
            accent: _orange,
            onTap: () => Navigator.pushNamed(context, '/chat'),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: _navy,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 17, 12, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.65)),
            ),
            child: Column(
              children: [
                Icon(icon, color: accent, size: 25),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: TextStyle(
                    color: accent,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE4EAF3),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Orbitron',
                    letterSpacing: 0.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, dynamic section) {
    final accent = _sectionAccent(section);
    final title = _localizedSectionTitle(section);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 7,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    fontFamily: 'Orbitron',
                    color: _navy,
                    letterSpacing: 0.75,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${section.items.length}',
                  style: TextStyle(
                    color: accent == _green ? const Color(0xFF148951) : accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.items.length,
            itemBuilder: (context, index) {
              final item = section.items[index];
              return _buildAdCard(context, item, section.category, accent);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdCard(
    BuildContext context,
    dynamic item,
    String category,
    Color accent,
  ) {
    return Container(
      width: 164,
      margin: const EdgeInsets.only(right: 13, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: _navy,
        borderRadius: BorderRadius.circular(17),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/post_details',
              arguments: {
                'id': item.id,
                'category': category,
              },
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.imageUrl != null &&
                  item.imageUrl.toString().isNotEmpty)
                CachedNetworkImage(
                  imageUrl: item.imageUrl.toString(),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildPlaceholder(accent),
                  errorWidget: (context, url, error) =>
                      _buildPlaceholder(accent),
                )
              else
                _buildPlaceholder(accent),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.15),
                      _navy.withValues(alpha: 0.97),
                    ],
                    stops: const [0.0, 0.42, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.65),
                        blurRadius: 7,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _tr('dashboard.index.open', 'Open'),
                          style: TextStyle(
                            fontSize: 9,
                            color: accent,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                            letterSpacing: 0.45,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: accent,
                        ),
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

  Widget _buildPlaceholder(Color accent) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_navyLight, _navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_outlined,
              color: accent.withValues(alpha: 0.8),
              size: 32,
            ),
            const SizedBox(height: 7),
            Text(
              _tr('shared.no_photo', 'NO PHOTO'),
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.58),
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}