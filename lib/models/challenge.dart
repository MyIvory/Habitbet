enum ChallengeStatus { pending, active, completed, failed, cancelled }

enum ArbiterStatus { pending, accepted, declined }

enum PaymentProofStatus { none, pending, submitted, approved, rejected }

class Challenge {
  final String id;
  final String creatorId;
  final String creatorName;
  final String arbiterId;
  final String arbiterName;
  final String arbiterEmail;
  final ArbiterStatus arbiterStatus;
  final String title;
  final String description;
  final int stakeAmountCents;
  final String charityId;
  final String charityName;
  final int durationDays;
  final int requiredDaysPerWeek;
  final DateTime startDate;
  final DateTime endDate;
  final ChallengeStatus status;
  final PaymentProofStatus paymentProofStatus;
  final String? paymentProofImageUrl;
  final String? paymentProofNote;
  final DateTime? paymentProofSubmittedAt;
  final DateTime? paymentProofReviewedAt;
  final String? paymentProofRejectionReason;
  final int? arbiterRating;
  final String? arbiterFeedback;
  final int completedDays;
  final int missedDays;
  final DateTime createdAt;

  const Challenge({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.arbiterId,
    required this.arbiterName,
    required this.arbiterEmail,
    this.arbiterStatus = ArbiterStatus.pending,
    required this.title,
    required this.description,
    required this.stakeAmountCents,
    required this.charityId,
    required this.charityName,
    required this.durationDays,
    required this.requiredDaysPerWeek,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.paymentProofStatus = PaymentProofStatus.none,
    this.paymentProofImageUrl,
    this.paymentProofNote,
    this.paymentProofSubmittedAt,
    this.paymentProofReviewedAt,
    this.paymentProofRejectionReason,
    this.arbiterRating,
    this.arbiterFeedback,
    this.completedDays = 0,
    this.missedDays = 0,
    required this.createdAt,
  });

  double get stakeAmountDollars => stakeAmountCents / 100.0;

  double get progressPercent {
    final totalRequired = (durationDays / 7 * requiredDaysPerWeek).ceil();
    if (totalRequired == 0) return 0;
    return (completedDays / totalRequired).clamp(0.0, 1.0);
  }

  bool get isActive => status == ChallengeStatus.active;

  factory Challenge.fromJson(Map<String, dynamic> json) {
    final status = ChallengeStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ChallengeStatus.active,
    );
    final paymentProofRaw = json['paymentProofStatus'] as String?;
    final paymentProofStatus = paymentProofRaw == null
        ? (status == ChallengeStatus.failed
            ? PaymentProofStatus.pending
            : PaymentProofStatus.none)
        : PaymentProofStatus.values.firstWhere(
            (e) => e.name == paymentProofRaw,
            orElse: () => PaymentProofStatus.none,
          );

    return Challenge(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String? ?? '',
      arbiterId: json['arbiterId'] as String,
      arbiterName: json['arbiterName'] as String? ?? '',
      arbiterEmail: json['arbiterEmail'] as String? ?? '',
      arbiterStatus: ArbiterStatus.values.firstWhere(
        (e) => e.name == json['arbiterStatus'],
        orElse: () => ArbiterStatus.pending,
      ),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      stakeAmountCents: json['stakeAmountCents'] as int,
      charityId: json['charityId'] as String,
      charityName: json['charityName'] as String? ?? '',
      durationDays: json['durationDays'] as int,
      requiredDaysPerWeek: json['requiredDaysPerWeek'] as int? ?? 7,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: status,
      paymentProofStatus: paymentProofStatus,
      paymentProofImageUrl: json['paymentProofImageUrl'] as String?,
      paymentProofNote: json['paymentProofNote'] as String?,
      paymentProofSubmittedAt: json['paymentProofSubmittedAt'] != null
          ? DateTime.parse(json['paymentProofSubmittedAt'] as String)
          : null,
      paymentProofReviewedAt: json['paymentProofReviewedAt'] != null
          ? DateTime.parse(json['paymentProofReviewedAt'] as String)
          : null,
      paymentProofRejectionReason:
          json['paymentProofRejectionReason'] as String?,
      arbiterRating: json['arbiterRating'] as int?,
      arbiterFeedback: json['arbiterFeedback'] as String?,
      completedDays: json['completedDays'] as int? ?? 0,
      missedDays: json['missedDays'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'arbiterId': arbiterId,
      'arbiterName': arbiterName,
      'arbiterEmail': arbiterEmail,
      'arbiterStatus': arbiterStatus.name,
      'title': title,
      'description': description,
      'stakeAmountCents': stakeAmountCents,
      'charityId': charityId,
      'charityName': charityName,
      'durationDays': durationDays,
      'requiredDaysPerWeek': requiredDaysPerWeek,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.name,
      'paymentProofStatus': paymentProofStatus.name,
      'paymentProofImageUrl': paymentProofImageUrl,
      'paymentProofNote': paymentProofNote,
      'paymentProofSubmittedAt': paymentProofSubmittedAt?.toIso8601String(),
      'paymentProofReviewedAt': paymentProofReviewedAt?.toIso8601String(),
      'paymentProofRejectionReason': paymentProofRejectionReason,
      'arbiterRating': arbiterRating,
      'arbiterFeedback': arbiterFeedback,
      'completedDays': completedDays,
      'missedDays': missedDays,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Challenge copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? arbiterId,
    String? arbiterName,
    String? arbiterEmail,
    ArbiterStatus? arbiterStatus,
    String? title,
    String? description,
    int? stakeAmountCents,
    String? charityId,
    String? charityName,
    int? durationDays,
    int? requiredDaysPerWeek,
    DateTime? startDate,
    DateTime? endDate,
    ChallengeStatus? status,
    PaymentProofStatus? paymentProofStatus,
    String? paymentProofImageUrl,
    String? paymentProofNote,
    DateTime? paymentProofSubmittedAt,
    DateTime? paymentProofReviewedAt,
    String? paymentProofRejectionReason,
    int? arbiterRating,
    String? arbiterFeedback,
    int? completedDays,
    int? missedDays,
    DateTime? createdAt,
  }) {
    return Challenge(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      arbiterId: arbiterId ?? this.arbiterId,
      arbiterName: arbiterName ?? this.arbiterName,
      arbiterEmail: arbiterEmail ?? this.arbiterEmail,
      arbiterStatus: arbiterStatus ?? this.arbiterStatus,
      title: title ?? this.title,
      description: description ?? this.description,
      stakeAmountCents: stakeAmountCents ?? this.stakeAmountCents,
      charityId: charityId ?? this.charityId,
      charityName: charityName ?? this.charityName,
      durationDays: durationDays ?? this.durationDays,
      requiredDaysPerWeek: requiredDaysPerWeek ?? this.requiredDaysPerWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      paymentProofStatus: paymentProofStatus ?? this.paymentProofStatus,
      paymentProofImageUrl: paymentProofImageUrl ?? this.paymentProofImageUrl,
      paymentProofNote: paymentProofNote ?? this.paymentProofNote,
      paymentProofSubmittedAt:
          paymentProofSubmittedAt ?? this.paymentProofSubmittedAt,
      paymentProofReviewedAt:
          paymentProofReviewedAt ?? this.paymentProofReviewedAt,
      paymentProofRejectionReason:
          paymentProofRejectionReason ?? this.paymentProofRejectionReason,
      arbiterRating: arbiterRating ?? this.arbiterRating,
      arbiterFeedback: arbiterFeedback ?? this.arbiterFeedback,
      completedDays: completedDays ?? this.completedDays,
      missedDays: missedDays ?? this.missedDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
