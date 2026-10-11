import 'package:equatable/equatable.dart';

// =============================================================================
// 1. КОРНЕВАЯ МОДЕЛЬ ДЕТАЛЬНОГО ПРОСМОТРА (PostDetailModel)
// =============================================================================
class PostDetailModel extends Equatable {
  final int id;
  final String title;
  final String text;
  final String? category; // 'people', 'animals', 'things'
  final String createdAt;
  final String local;
  
  // 👉 Геолокация и адрес (Необходимы для ShowMapWidget)
  final String address;
  final double? lat;
  final double? lng;
  
  // 👉 Специфика животных (JSONB: chip_number, passport_number, insurance_policy_id)
  final Map<String, dynamic> animalMetadata;
  
  // 👉 Вложенные сущности и медиа
  final List<String> images;
  final AuthorModel author;
  final List<CommentModel> comments;
  final PermissionsModel permissions;

  const PostDetailModel({
    required this.id,
    required this.title,
    required this.text,
    this.category,
    required this.createdAt,
    required this.local,
    this.address = '',
    this.lat,
    this.lng,
    this.animalMetadata = const {},
    required this.images,
    required this.author,
    required this.comments,
    required this.permissions,
  });

  // ---------------------------------------------------------------------------
  // Фабрика парсинга JSON
  // ---------------------------------------------------------------------------
  factory PostDetailModel.fromJson(Map<String, dynamic> json) {
    // 1. Парсинг широты (lat / latitude)
    final double? parsedLat = json['lat'] != null
        ? double.tryParse(json['lat'].toString())
        : (json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null);

    // 2. Парсинг долготы (lng / longitude)
    final double? parsedLng = json['lng'] != null
        ? double.tryParse(json['lng'].toString())
        : (json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null);

    // 3. Извлечение JSONB-поля animal_metadata
    final Map<String, dynamic> parsedAnimalMeta = json['animal_metadata'] is Map
        ? Map<String, dynamic>.from(json['animal_metadata'])
        : {};

    return PostDetailModel(
      id: json['id'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      category: json['category']?.toString() ?? json['type']?.toString() ?? json['commentable_type']?.toString(),
      createdAt: json['created_at_formatted']?.toString() ?? json['created_at']?.toString() ?? '',
      local: json['local']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      lat: parsedLat,
      lng: parsedLng,
      animalMetadata: parsedAnimalMeta,
      images: List<String>.from(json['images'] ?? []),
      author: AuthorModel.fromJson(json['author'] is Map ? json['author'] : {}),
      comments: (json['comments'] as List? ?? [])
          .map((c) => CommentModel.fromJson(c is Map ? Map<String, dynamic>.from(c) : {}))
          .toList(),
      permissions: PermissionsModel.fromJson(json['permissions'] is Map ? json['permissions'] : {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        text,
        category,
        createdAt,
        local,
        address,
        lat,
        lng,
        animalMetadata,
        images,
        author,
        comments,
        permissions,
      ];
}

// =============================================================================
// 2. МОДЕЛЬ АВТОРА ОБЪЯВЛЕНИЯ (AuthorModel)
// =============================================================================
class AuthorModel extends Equatable {
  final int id;
  final String username;
  final String? avatarUrl;

  const AuthorModel({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['id'] as int? ?? 0,
      username: json['username']?.toString() ?? 'Guest',
      avatarUrl: json['avatar_url']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, username, avatarUrl];
}

// =============================================================================
// 3. МОДЕЛЬ КОММЕНТАРИЯ (CommentModel)
// =============================================================================
class CommentModel extends Equatable {
  final int id;
  final String username;
  final String? avatarUrl;
  final String body;
  final String createdAt;
  final bool canDelete;

  const CommentModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.body,
    required this.createdAt,
    this.canDelete = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] is Map ? json['user'] as Map<String, dynamic> : null;
    final authorData = json['author'] is Map ? json['author'] as Map<String, dynamic> : null;

    final String extractedUsername = userData?['username']?.toString() ??
        authorData?['username']?.toString() ??
        'User #${json['user_id'] ?? 0}';

    final String? extractedAvatar = userData?['avatar_url']?.toString() ??
        authorData?['avatar_url']?.toString();

    final bool permissionDelete = json['permissions'] is Map
        ? (json['permissions']['can_delete'] == true)
        : (json['can_delete'] == true);

    return CommentModel(
      id: json['id'] as int? ?? 0,
      username: extractedUsername,
      avatarUrl: extractedAvatar,
      body: json['body']?.toString() ?? '',
      createdAt: json['created_at_formatted']?.toString() ?? json['created_at']?.toString() ?? '',
      canDelete: permissionDelete,
    );
  }

  @override
  List<Object?> get props => [id, username, avatarUrl, body, createdAt, canDelete];
}

// =============================================================================
// 4. МОДЕЛЬ ПРАВ ДОСТУПА К ПОСТУ (PermissionsModel)
// =============================================================================
class PermissionsModel extends Equatable {
  final bool canEdit;
  final bool canDelete;

  const PermissionsModel({
    required this.canEdit,
    required this.canDelete,
  });

  factory PermissionsModel.fromJson(Map<String, dynamic> json) {
    return PermissionsModel(
      canEdit: json['can_edit'] == true,
      canDelete: json['can_delete'] == true,
    );
  }

  @override
  List<Object?> get props => [canEdit, canDelete];
}