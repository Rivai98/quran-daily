import 'package:equatable/equatable.dart';

/// App-visible profile row (public.profiles), 1:1 with an auth user.
class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.displayName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String displayName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, displayName, createdAt, updatedAt];

  static UserProfile? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    final id = row['id'];
    final displayName = row['display_name'];
    if (id is! String || displayName is! String) return null;
    return UserProfile(
      id: id,
      displayName: displayName,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? ''),
    );
  }
}
