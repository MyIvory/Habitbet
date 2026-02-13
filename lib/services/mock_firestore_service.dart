import 'dart:async';

import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/challenge.dart';
import '../models/day_record.dart';

class MockFirestoreService {
  final Map<String, AppUser> _users = {};
  final Map<String, Challenge> _challenges = {};
  final Map<String, List<DayRecord>> _dayRecords = {};

  final _usersController = StreamController<Map<String, AppUser>>.broadcast();
  final _challengesController =
      StreamController<Map<String, Challenge>>.broadcast();
  final Map<String, StreamController<List<DayRecord>>> _dayRecordControllers =
      {};

  MockFirestoreService() {
    _seedData();
  }

  void _seedData() {
    const uuid = Uuid();

    final user = AppUser(
      uid: 'mock_user_001',
      email: 'demo@habitbet.app',
      displayName: 'Demo User',
      challengesCreated: 2,
      challengesCompleted: 1,
      challengesFailed: 0,
      totalStaked: 5000,
      totalLost: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    _users[user.uid] = user;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Active challenge
    final challenge1Id = uuid.v4();
    _challenges[challenge1Id] = Challenge(
      id: challenge1Id,
      creatorId: 'mock_user_001',
      creatorName: 'Demo User',
      arbiterId: 'arbiter_001',
      arbiterName: 'John Arbiter',
      arbiterEmail: 'john@example.com',
      title: 'Morning Run 5km',
      description: 'Run at least 5km every morning before 9 AM',
      stakeAmountCents: 2500,
      charityId: 'red_cross',
      charityName: 'Red Cross',
      durationDays: 21,
      requiredDaysPerWeek: 5,
      startDate: today.subtract(const Duration(days: 7)),
      endDate: today.add(const Duration(days: 14)),
      status: ChallengeStatus.active,
      stripePaymentIntentId: 'pi_mock_1',
      completedDays: 5,
      missedDays: 1,
      createdAt: today.subtract(const Duration(days: 8)),
    );

    // Generate day records for challenge 1
    final days1 = <DayRecord>[];
    for (var i = 0; i < 21; i++) {
      final date = today.subtract(const Duration(days: 7)).add(Duration(days: i));
      DayStatus status;
      if (date.isBefore(today.subtract(const Duration(days: 1)))) {
        status = i % 7 == 5
            ? DayStatus.missed
            : i == 6
                ? DayStatus.proofSubmitted
                : DayStatus.approved;
      } else if (date.isAtSameMomentAs(today)) {
        status = DayStatus.pending;
      } else {
        status = DayStatus.pending;
      }
      days1.add(DayRecord(
        id: uuid.v4(),
        challengeId: challenge1Id,
        date: date,
        status: status,
        proofImageUrl: status == DayStatus.approved || status == DayStatus.proofSubmitted
            ? 'https://picsum.photos/400/300?random=$i'
            : null,
        proofNote: status == DayStatus.proofSubmitted ? 'Ran 5.2km today!' : null,
        submittedAt: status != DayStatus.pending && status != DayStatus.missed
            ? date.add(const Duration(hours: 8))
            : null,
      ));
    }
    _dayRecords[challenge1Id] = days1;

    // Completed challenge
    final challenge2Id = uuid.v4();
    _challenges[challenge2Id] = Challenge(
      id: challenge2Id,
      creatorId: 'mock_user_001',
      creatorName: 'Demo User',
      arbiterId: 'arbiter_002',
      arbiterName: 'Jane Smith',
      arbiterEmail: 'jane@example.com',
      title: 'Read 30 minutes',
      description: 'Read a non-fiction book for at least 30 minutes',
      stakeAmountCents: 2500,
      charityId: 'unicef',
      charityName: 'UNICEF',
      durationDays: 14,
      requiredDaysPerWeek: 7,
      startDate: today.subtract(const Duration(days: 28)),
      endDate: today.subtract(const Duration(days: 14)),
      status: ChallengeStatus.completed,
      stripePaymentIntentId: 'pi_mock_2',
      completedDays: 14,
      missedDays: 0,
      createdAt: today.subtract(const Duration(days: 29)),
    );
    _dayRecords[challenge2Id] = [];

    // Challenge where user is arbiter
    final challenge3Id = uuid.v4();
    _challenges[challenge3Id] = Challenge(
      id: challenge3Id,
      creatorId: 'other_user_001',
      creatorName: 'Alice Wonder',
      arbiterId: 'mock_user_001',
      arbiterName: 'Demo User',
      arbiterEmail: 'demo@habitbet.app',
      title: 'No Sugar Challenge',
      description: 'No added sugar in meals for the whole period',
      stakeAmountCents: 5000,
      charityId: 'wwf',
      charityName: 'WWF',
      durationDays: 30,
      requiredDaysPerWeek: 7,
      startDate: today.subtract(const Duration(days: 3)),
      endDate: today.add(const Duration(days: 27)),
      status: ChallengeStatus.active,
      stripePaymentIntentId: 'pi_mock_3',
      completedDays: 2,
      missedDays: 0,
      createdAt: today.subtract(const Duration(days: 4)),
    );

    final days3 = <DayRecord>[];
    for (var i = 0; i < 30; i++) {
      final date = today.subtract(const Duration(days: 3)).add(Duration(days: i));
      DayStatus status;
      if (i < 2) {
        status = DayStatus.approved;
      } else if (i == 2) {
        status = DayStatus.proofSubmitted;
      } else {
        status = DayStatus.pending;
      }
      days3.add(DayRecord(
        id: uuid.v4(),
        challengeId: challenge3Id,
        date: date,
        status: status,
        proofImageUrl: status != DayStatus.pending
            ? 'https://picsum.photos/400/300?random=${100 + i}'
            : null,
        proofNote: status == DayStatus.proofSubmitted
            ? 'Had a salad for lunch, grilled chicken for dinner!'
            : null,
        submittedAt: status != DayStatus.pending
            ? date.add(const Duration(hours: 20))
            : null,
      ));
    }
    _dayRecords[challenge3Id] = days3;
  }

  // ── Users ──

  Future<void> createUser(AppUser user) async {
    _users[user.uid] = user;
    _usersController.add(_users);
  }

  Future<AppUser?> getUser(String uid) async {
    return _users[uid];
  }

  Stream<AppUser?> userStream(String uid) {
    return Stream.value(_users[uid]).asBroadcastStream().asyncExpand((_) async* {
      yield _users[uid];
      await for (final _ in _usersController.stream) {
        yield _users[uid];
      }
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    final user = _users[uid];
    if (user == null) return;
    _users[uid] = AppUser.fromJson({...user.toJson(), ...data});
    _usersController.add(_users);
  }

  // ── Challenges ──

  Future<void> createChallenge(Challenge challenge) async {
    _challenges[challenge.id] = challenge;
    _challengesController.add(_challenges);
  }

  Future<Challenge?> getChallenge(String id) async {
    return _challenges[id];
  }

  Stream<Challenge?> challengeStream(String id) async* {
    yield _challenges[id];
    await for (final _ in _challengesController.stream) {
      yield _challenges[id];
    }
  }

  Stream<List<Challenge>> myChallengesStream(String userId) async* {
    yield _challenges.values
        .where((c) => c.creatorId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await for (final _ in _challengesController.stream) {
      yield _challenges.values
          .where((c) => c.creatorId == userId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  Stream<List<Challenge>> arbitrationChallengesStream(String userId) async* {
    yield _challenges.values
        .where((c) => c.arbiterId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await for (final _ in _challengesController.stream) {
      yield _challenges.values
          .where((c) => c.arbiterId == userId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  Future<void> updateChallenge(String id, Map<String, dynamic> data) async {
    final challenge = _challenges[id];
    if (challenge == null) return;
    _challenges[id] = Challenge.fromJson({...challenge.toJson(), ...data});
    _challengesController.add(_challenges);
  }

  // ── Day Records ──

  StreamController<List<DayRecord>> _getDayRecordController(String challengeId) {
    return _dayRecordControllers.putIfAbsent(
      challengeId,
      () => StreamController<List<DayRecord>>.broadcast(),
    );
  }

  Future<void> createDayRecord(DayRecord record) async {
    _dayRecords.putIfAbsent(record.challengeId, () => []);
    _dayRecords[record.challengeId]!.add(record);
    _getDayRecordController(record.challengeId)
        .add(_dayRecords[record.challengeId]!);
  }

  Stream<List<DayRecord>> dayRecordsStream(String challengeId) async* {
    final records = _dayRecords[challengeId] ?? [];
    yield records..sort((a, b) => a.date.compareTo(b.date));
    await for (final _ in _getDayRecordController(challengeId).stream) {
      final r = _dayRecords[challengeId] ?? [];
      yield r..sort((a, b) => a.date.compareTo(b.date));
    }
  }

  Future<void> updateDayRecord(
    String challengeId,
    String recordId,
    Map<String, dynamic> data,
  ) async {
    final records = _dayRecords[challengeId];
    if (records == null) return;
    final idx = records.indexWhere((r) => r.id == recordId);
    if (idx == -1) return;
    records[idx] = DayRecord.fromJson({...records[idx].toJson(), ...data});
    _getDayRecordController(challengeId).add(records);
    _challengesController.add(_challenges);
  }

  Stream<List<DayRecord>> pendingReviewsStream(String challengeId) async* {
    final records = _dayRecords[challengeId] ?? [];
    yield records.where((r) => r.status == DayStatus.proofSubmitted).toList();
    await for (final _ in _getDayRecordController(challengeId).stream) {
      final r = _dayRecords[challengeId] ?? [];
      yield r.where((r) => r.status == DayStatus.proofSubmitted).toList();
    }
  }

  void dispose() {
    _usersController.close();
    _challengesController.close();
    for (final c in _dayRecordControllers.values) {
      c.close();
    }
  }
}
