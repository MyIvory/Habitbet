class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final int challengesCreated;
  final int challengesCompleted;
  final int challengesFailed;
  final int totalStaked;
  final int totalLost;
  final int ratingTotal;
  final int ratingCount;
  final String? fcmToken;
  final bool notificationsEnabled;
  final String locale;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.challengesCreated = 0,
    this.challengesCompleted = 0,
    this.challengesFailed = 0,
    this.totalStaked = 0,
    this.totalLost = 0,
    this.ratingTotal = 0,
    this.ratingCount = 0,
    this.fcmToken,
    this.notificationsEnabled = true,
    this.locale = 'en',
    required this.createdAt,
  });

  double get ratingAverage =>
      ratingCount == 0 ? 0 : ratingTotal / ratingCount;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String? ?? '',
      challengesCreated: json['challengesCreated'] as int? ?? 0,
      challengesCompleted: json['challengesCompleted'] as int? ?? 0,
      challengesFailed: json['challengesFailed'] as int? ?? 0,
      totalStaked: json['totalStaked'] as int? ?? 0,
      totalLost: json['totalLost'] as int? ?? 0,
      ratingTotal: json['ratingTotal'] as int? ?? 0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      fcmToken: json['fcmToken'] as String?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      locale: json['locale'] as String? ?? 'en',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'challengesCreated': challengesCreated,
      'challengesCompleted': challengesCompleted,
      'challengesFailed': challengesFailed,
      'totalStaked': totalStaked,
      'totalLost': totalLost,
      'ratingTotal': ratingTotal,
      'ratingCount': ratingCount,
      'fcmToken': fcmToken,
      'notificationsEnabled': notificationsEnabled,
      'locale': locale,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    int? challengesCreated,
    int? challengesCompleted,
    int? challengesFailed,
    int? totalStaked,
    int? totalLost,
    int? ratingTotal,
    int? ratingCount,
    String? fcmToken,
    bool? notificationsEnabled,
    String? locale,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      challengesCreated: challengesCreated ?? this.challengesCreated,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      challengesFailed: challengesFailed ?? this.challengesFailed,
      totalStaked: totalStaked ?? this.totalStaked,
      totalLost: totalLost ?? this.totalLost,
      ratingTotal: ratingTotal ?? this.ratingTotal,
      ratingCount: ratingCount ?? this.ratingCount,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locale: locale ?? this.locale,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
