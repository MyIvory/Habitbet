import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await GoogleSignIn.instance.initialize(
    serverClientId: '953599885752-l2nlnb9oajklp5buqh01d9seeskc71nn.apps.googleusercontent.com',
  );

  final notificationService = NotificationService();
  await notificationService.initialize();

  // TODO: Uncomment when Stripe is configured
  // Stripe.publishableKey = AppConstants.stripePublishableKey;

  runApp(
    const ProviderScope(
      child: HabitBetApp(),
    ),
  );
}
