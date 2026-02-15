import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_overlay.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signIn({bool apple = false}) async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final credential = apple
          ? await authService.signInWithApple()
          : await authService.signInWithGoogle();

      final user = credential.user;
      if (user == null) throw Exception('Sign in returned no user');

      // Ensure user doc exists in Firestore
      final firestoreService = ref.read(firestoreServiceProvider);
      final existing = await firestoreService.getUser(user.uid);
      if (existing == null) {
        await firestoreService.createUser(AppUser(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'User',
          photoUrl: user.photoURL ?? '',
          createdAt: DateTime.now(),
        ));
      }

      // Save FCM token for push notifications
      final fcmToken = await NotificationService().getToken();
      if (fcmToken != null) {
        await firestoreService.updateUser(user.uid, {'fcmToken': fcmToken});
      }

      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('sign_in_failed'.tr(args: ['$e']))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'HabitBet',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'sign_in_subtitle'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const Spacer(),
                AppButton(
                  label: 'continue_with_google'.tr(),
                  icon: Icons.g_mobiledata,
                  onPressed: () => _signIn(),
                ),
                const SizedBox(height: 12),
                if (Platform.isIOS) ...[
                  AppButton(
                    label: 'continue_with_apple'.tr(),
                    icon: Icons.apple,
                    onPressed: () => _signIn(apple: true),
                    isOutlined: true,
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 24),
                Text(
                  'by_continuing'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        launchUrl(Uri.parse(AppConstants.termsUrl));
                      },
                      child: Text(
                        'terms_of_service'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      'and'.tr(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: () {
                        launchUrl(Uri.parse(AppConstants.privacyPolicyUrl));
                      },
                      child: Text(
                        'privacy_policy'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
