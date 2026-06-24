class AppUser {
  final int? id;
  final String displayName;
  final String username;
  final String password;
  final String? avatarPath;
  final String bio;
  final String createdAt;

  const AppUser({
    this.id,
    required this.displayName,
    required this.username,
    required this.password,
    this.avatarPath,
    required this.bio,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'] as int?,
        displayName: map['display_name'] as String,
        username: map['username'] as String,
        password: map['password'] as String,
        avatarPath: map['avatar_path'] as String?,
        bio: map['bio'] as String? ?? '',
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'display_name': displayName,
        'username': username,
        'password': password,
        'avatar_path': avatarPath,
        'bio': bio,
        'created_at': createdAt,
      };

  AppUser copyWith({
    int? id,
    String? displayName,
    String? username,
    String? password,
    String? avatarPath,
    String? bio,
    String? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      password: password ?? this.password,
      avatarPath: avatarPath ?? this.avatarPath,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}