import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notification_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('profile'.tr()),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('error_generic'.tr(args: ['$e']))),
        data: (user) {
          if (user == null) {
            return Center(child: Text('not_logged_in'.tr()));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar and name
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: user.photoUrl.isNotEmpty
                          ? NetworkImage(user.photoUrl)
                          : null,
                      child: user.photoUrl.isEmpty
                          ? Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 32),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.displayName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Stats
              Text(
                'statistics'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'stat_created'.tr(),
                      value: '${user.challengesCreated}',
                      icon: Icons.flag,
                      color: colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      label: 'stat_completed'.tr(),
                      value: '${user.challengesCompleted}',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      label: 'stat_failed'.tr(),
                      value: '${user.challengesFailed}',
                      icon: Icons.cancel,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'stat_total_staked'.tr(),
                      value: '\$${(user.totalStaked / 100).toStringAsFixed(0)}',
                      icon: Icons.attach_money,
                      color: colorScheme.secondary,
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      label: 'stat_lost_to_charity'.tr(),
                      value: '\$${(user.totalLost / 100).toStringAsFixed(0)}',
                      icon: Icons.favorite,
                      color: Colors.pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'stat_rating'.tr(),
                      value: user.ratingCount == 0
                          ? '—'
                          : user.ratingAverage.toStringAsFixed(1),
                      icon: Icons.star,
                      color: Colors.amber,
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      label: 'stat_rating_count'.tr(),
                      value: '${user.ratingCount}',
                      icon: Icons.rate_review,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Settings
              Text(
                'settings'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: Text('notifications'.tr()),
                value: user.notificationsEnabled,
                onChanged: (enabled) async {
                  final firestoreService = ref.read(firestoreServiceProvider);
                  if (enabled) {
                    final fcmToken = await NotificationService().getToken();
                    await firestoreService.updateUser(user.uid, {
                      'notificationsEnabled': true,
                      'fcmToken': fcmToken,
                    });
                  } else {
                    await firestoreService.updateUser(user.uid, {
                      'notificationsEnabled': false,
                      'fcmToken': null,
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text('language'.tr()),
                trailing: Text(
                  context.locale.languageCode == 'uk'
                      ? 'language_ukrainian'.tr()
                      : 'language_english'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
                onTap: () {
                  final newLocale = context.locale.languageCode == 'en'
                      ? const Locale('uk')
                      : const Locale('en');
                  context.setLocale(newLocale);
                  final firestoreService = ref.read(firestoreServiceProvider);
                  firestoreService.updateUser(user.uid, {
                    'locale': newLocale.languageCode,
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: Text('privacy_policy'.tr()),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  launchUrl(Uri.parse(AppConstants.privacyPolicyUrl));
                },
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: Text('terms_of_service'.tr()),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  launchUrl(Uri.parse(AppConstants.termsUrl));
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.logout, color: colorScheme.error),
                title: Text(
                  'sign_out'.tr(),
                  style: TextStyle(color: colorScheme.error),
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('sign_out'.tr()),
                      content: Text('sign_out_confirm'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('cancel'.tr()),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('sign_out'.tr()),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    final authService = ref.read(authServiceProvider);
                    await authService.signOut();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
