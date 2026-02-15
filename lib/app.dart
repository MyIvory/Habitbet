import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'main.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';

class HabitBetApp extends ConsumerStatefulWidget {
  const HabitBetApp({super.key});

  @override
  ConsumerState<HabitBetApp> createState() => _HabitBetAppState();
}

class _HabitBetAppState extends ConsumerState<HabitBetApp> {
  @override
  void initState() {
    super.initState();

    // Navigate when user taps a push notification
    notificationService.onNotificationTap = (challengeId, type) {
      final router = ref.read(routerProvider);
      if (type == 'proof_submitted' || type == 'arbiter_request' || type == 'payment_proof_submitted') {
        router.push('/arbitrate/$challengeId');
      } else {
        router.push('/challenge/$challengeId');
      }
    };

    // Keep FCM token fresh in Firestore
    notificationService.onTokenRefresh.listen((newToken) {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        final firestoreService = ref.read(firestoreServiceProvider);
        firestoreService.updateUser(user.uid, {'fcmToken': newToken});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'HabitBet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
