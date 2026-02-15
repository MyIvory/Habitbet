import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/challenge.dart';
import '../models/day_record.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Users ──

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  Future<void> createUser(AppUser user) async {
    await _usersRef.doc(user.uid).set(user.toJson());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return AppUser.fromJson(doc.data()!);
  }

  Stream<AppUser?> userStream(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromJson(doc.data()!);
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _usersRef.doc(uid).update(data);
  }

  Future<AppUser?> findUserByEmail(String email) async {
    final snap = await _usersRef
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return AppUser.fromJson(snap.docs.first.data());
  }

  // ── Challenges ──

  CollectionReference<Map<String, dynamic>> get _challengesRef =>
      _db.collection('challenges');

  Future<void> createChallenge(Challenge challenge) async {
    await _challengesRef.doc(challenge.id).set(challenge.toJson());
  }

  Future<Challenge?> getChallenge(String id) async {
    final doc = await _challengesRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Challenge.fromJson(doc.data()!);
  }

  Stream<Challenge?> challengeStream(String id) {
    return _challengesRef.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Challenge.fromJson(doc.data()!);
    });
  }

  Stream<List<Challenge>> myChallengesStream(String userId) {
    return _challengesRef
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Challenge.fromJson(d.data())).toList());
  }

  Stream<List<Challenge>> arbitrationChallengesStream(String userId) {
    return _challengesRef
        .where('arbiterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Challenge.fromJson(d.data())).toList());
  }

  Stream<List<Challenge>> pendingArbiterRequestsStream(String userId) {
    return _challengesRef
        .where('arbiterId', isEqualTo: userId)
        .where('arbiterStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Challenge.fromJson(d.data())).toList());
  }

  Stream<List<Challenge>> acceptedArbitrationStream(String userId) {
    return _challengesRef
        .where('arbiterId', isEqualTo: userId)
        .where('arbiterStatus', isEqualTo: 'accepted')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Challenge.fromJson(d.data())).toList());
  }

  Stream<List<AppUser>> previousArbitersStream(String userId) {
    return _challengesRef
        .where('creatorId', isEqualTo: userId)
        .where('arbiterStatus', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snap) async {
      final arbiterIds = snap.docs
          .map((d) => d.data()['arbiterId'] as String)
          .where((id) => id.isNotEmpty)
          .toSet();
      final arbiters = <AppUser>[];
      for (final id in arbiterIds) {
        final user = await getUser(id);
        if (user != null) arbiters.add(user);
      }
      return arbiters;
    });
  }

  Future<void> updateChallenge(String id, Map<String, dynamic> data) async {
    await _challengesRef.doc(id).update(data);
  }

  // ── Day Records ──

  CollectionReference<Map<String, dynamic>> _dayRecordsRef(String challengeId) =>
      _challengesRef.doc(challengeId).collection('dayRecords');

  Future<void> createDayRecord(DayRecord record) async {
    await _dayRecordsRef(record.challengeId).doc(record.id).set(record.toJson());
  }

  Stream<List<DayRecord>> dayRecordsStream(String challengeId) {
    return _dayRecordsRef(challengeId)
        .orderBy('date')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DayRecord.fromJson(d.data())).toList());
  }

  Future<void> updateDayRecord(
    String challengeId,
    String recordId,
    Map<String, dynamic> data,
  ) async {
    await _dayRecordsRef(challengeId).doc(recordId).update(data);
  }

  Stream<List<DayRecord>> pendingReviewsStream(String challengeId) {
    return _dayRecordsRef(challengeId)
        .where('status', isEqualTo: DayStatus.proofSubmitted.name)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DayRecord.fromJson(d.data())).toList());
  }
}
