import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:easy_localization/easy_localization.dart';

import 'app.dart';
import 'services/notification_service.dart';

final notificationService = NotificationService();

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    await GoogleSignIn.instance.initialize(
      serverClientId: '953599885752-l2nlnb9oajklp5buqh01d9seeskc71nn.apps.googleusercontent.com',
    );
    await EasyLocalization.ensureInitialized();

    await notificationService.initialize();

    runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('uk')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const ProviderScope(
          child: HabitBetApp(),
        ),
      ),
    );
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
