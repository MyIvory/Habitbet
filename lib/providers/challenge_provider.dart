import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge.dart';
import '../models/day_record.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

final myChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  final user = authState.value;
  if (user == null) return Stream.value([]);

  return firestoreService.myChallengesStream(user.uid);
});

final arbitrationChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  final user = authState.value;
  if (user == null) return Stream.value([]);

  return firestoreService.arbitrationChallengesStream(user.uid);
});

final challengeDetailProvider =
    StreamProvider.family<Challenge?, String>((ref, challengeId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.challengeStream(challengeId);
});

final dayRecordsProvider =
    StreamProvider.family<List<DayRecord>, String>((ref, challengeId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.dayRecordsStream(challengeId);
});

final pendingReviewsProvider =
    StreamProvider.family<List<DayRecord>, String>((ref, challengeId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.pendingReviewsStream(challengeId);
});
