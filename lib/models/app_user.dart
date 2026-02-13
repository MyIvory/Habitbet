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
  final String? fcmToken;
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
    this.fcmToken,
    required this.createdAt,
  });

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
      fcmToken: json['fcmToken'] as String?,
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
      'fcmToken': fcmToken,
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
    String? fcmToken,
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
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
