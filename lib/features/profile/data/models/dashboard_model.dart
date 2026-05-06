// lib/features/profile/data/models/dashboard_model.dart

// 1. ГЛАВНЫЙ КЛАСС (тот самый, который "не найден")
class DashboardModel {
  final UserInfo user;
  final UserStats stats;
  final List<AdsSection> sections;

  DashboardModel({
    required this.user, 
    required this.stats, 
    required this.sections
  });

  factory DashboardModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DashboardModel.empty();
    return DashboardModel(
      user: UserInfo.fromJson(json['user']),
      stats: UserStats.fromJson(json['stats']),
      sections: (json['ads_sections'] as List?)
              ?.map((s) => AdsSection.fromJson(s))
              .toList() ?? [],
    );
  }

  factory DashboardModel.empty() => DashboardModel(
    user: UserInfo.empty(),
    stats: UserStats.empty(),
    sections: [],
  );
}

// 2. ИНФОРМАЦИЯ О ПОЛЬЗОВАТЕЛЕ
class UserInfo {
  final int id;
  final String username;
  final String email;
  final String? avatar;

  UserInfo({required this.id, required this.username, required this.email, this.avatar});

  factory UserInfo.empty() => UserInfo(id: 0, username: 'Guest', email: '');

  factory UserInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return UserInfo.empty();
    return UserInfo(
      id: json['id'] ?? 0,
      username: json['username'] ?? 'Unknown',
      email: json['email'] ?? '',
      avatar: json['avatar'],
    );
  }
}

// 3. СТАТИСТИКА (исправлено именование)
class UserStats {
  final int totalAds;
  final int unreadMessages;

  UserStats({required this.totalAds, required this.unreadMessages});

  factory UserStats.empty() => UserStats(totalAds: 0, unreadMessages: 0);

  factory UserStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return UserStats.empty();
    return UserStats(
      totalAds: json['total_ads'] ?? 0,          // из snake_case (Rails)
      unreadMessages: json['unread_messages'] ?? 0, // в camelCase (Dart)
    );
  }
}

// 4. СЕКЦИИ ОБЪЯВЛЕНИЙ (People, Animals, Things)
class AdsSection {
  final String category;
  final String title;
  final List<AdItem> items;

  AdsSection({required this.category, required this.title, required this.items});

  factory AdsSection.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AdsSection(category: '', title: '', items: []);
    return AdsSection(
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      items: (json['items'] as List?)
              ?.map((i) => AdItem.fromJson(i))
              .toList() ?? [],
    );
  }
}

// 5. КОНКРЕТНОЕ ОБЪЯВЛЕНИЕ
class AdItem {
  final int id;
  final String title;
  final String? imageUrl;

  AdItem({required this.id, required this.title, this.imageUrl});

  factory AdItem.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AdItem(id: 0, title: '');
    return AdItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}