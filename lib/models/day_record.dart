enum DayStatus { pending, proofSubmitted, approved, rejected, missed }

class DayRecord {
  final String id;
  final String challengeId;
  final DateTime date;
  final DayStatus status;
  final String? proofImageUrl;
  final String? proofNote;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final int proofAttempts;

  const DayRecord({
    required this.id,
    required this.challengeId,
    required this.date,
    this.status = DayStatus.pending,
    this.proofImageUrl,
    this.proofNote,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
    this.proofAttempts = 0,
  });

  bool get needsProof => status == DayStatus.pending;
  bool get canResubmit => status == DayStatus.rejected && proofAttempts < 3;
  bool get needsReview => status == DayStatus.proofSubmitted;

  factory DayRecord.fromJson(Map<String, dynamic> json) {
    return DayRecord(
      id: json['id'] as String,
      challengeId: json['challengeId'] as String,
      date: DateTime.parse(json['date'] as String),
      status: DayStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DayStatus.pending,
      ),
      proofImageUrl: json['proofImageUrl'] as String?,
      proofNote: json['proofNote'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'] as String)
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      proofAttempts: json['proofAttempts'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'date': date.toIso8601String(),
      'status': status.name,
      'proofImageUrl': proofImageUrl,
      'proofNote': proofNote,
      'rejectionReason': rejectionReason,
      'submittedAt': submittedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'proofAttempts': proofAttempts,
    };
  }

  DayRecord copyWith({
    String? id,
    String? challengeId,
    DateTime? date,
    DayStatus? status,
    String? proofImageUrl,
    String? proofNote,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    int? proofAttempts,
  }) {
    return DayRecord(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      date: date ?? this.date,
      status: status ?? this.status,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      proofNote: proofNote ?? this.proofNote,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      proofAttempts: proofAttempts ?? this.proofAttempts,
    );
  }
}
