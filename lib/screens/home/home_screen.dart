import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../models/challenge.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/user_provider.dart';
import 'widgets/challenge_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeTag = context.locale.toLanguageTag();

    return Scaffold(
      appBar: AppBar(
        title: const Text('HabitBet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
        bottom: TabBar(
          key: ValueKey(localeTag),
          controller: _tabController,
          tabs: [
            Tab(text: 'tab_my_challenges'.tr()),
            Tab(text: 'tab_to_arbitrate'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MyChallengesTab(),
          _ArbitrationTab(),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => context.push(AppRoutes.createChallenge),
            icon: const Icon(Icons.add),
            label: Text('new_challenge'.tr()),
          );
        },
      ),
    );
  }
}

class _MyChallengesTab extends ConsumerWidget {
  const _MyChallengesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(myChallengesProvider);

    return challengesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('error_generic'.tr(args: ['$e']))),
      data: (challenges) {
        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'no_challenges_yet'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'no_challenges_hint'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChallengeCard(
                challenge: challenge,
                onTap: () => context.push('/challenge/${challenge.id}'),
              ),
            );
          },
        );
      },
    );
  }
}

class _ArbitrationTab extends ConsumerWidget {
  const _ArbitrationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingArbiterRequestsProvider);
    final acceptedAsync = ref.watch(acceptedArbitrationProvider);

    return CustomScrollView(
      slivers: [
        // Pending requests section
        pendingAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: Center(child: Text('error_generic'.tr(args: ['$e']))),
          ),
          data: (pending) {
            if (pending.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'pending_requests'.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    );
                  }
                  final challenge = pending[index - 1];
                  return _PendingArbiterRequestCard(challenge: challenge);
                },
                childCount: pending.length + 1,
              ),
            );
          },
        ),

        // Accepted arbitrations section
        acceptedAsync.when(
          loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          error: (e, _) => SliverToBoxAdapter(
            child: Center(child: Text('error_generic'.tr(args: ['$e']))),
          ),
          data: (accepted) {
            if (accepted.isEmpty) {
              // Check if pending is also empty to show the empty state
              final pending = pendingAsync.value ?? [];
              if (pending.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.gavel_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no_arbitration_requests'.tr(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'no_arbitration_hint'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'active_arbitrations'.tr(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    );
                  }
                  final challenge = accepted[index - 1];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ChallengeCard(
                      challenge: challenge,
                      onTap: () => context.push('/arbitrate/${challenge.id}'),
                    ),
                  );
                },
                childCount: accepted.length + 1,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PendingArbiterRequestCard extends ConsumerWidget {
  final Challenge challenge;

  const _PendingArbiterRequestCard({required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'pending'.tr(),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'from_user'.tr(args: [challenge.creatorName]),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'stake_and_days'.tr(args: [
                  challenge.stakeAmountDollars.toStringAsFixed(0),
                  '${challenge.durationDays}',
                ]),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
              if (challenge.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 4),
                  title: Text(
                    'description_label'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  children: [
                    Text(
                      challenge.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _declineRequest(context, ref),
                    child: Text('decline'.tr()),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _acceptRequest(context, ref),
                    child: Text('accept'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptRequest(BuildContext context, WidgetRef ref) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateChallenge(challenge.id, {
        'arbiterStatus': ArbiterStatus.accepted.name,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('accepted_arbitration'.tr(args: [challenge.title]))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('failed_to_accept'.tr(args: ['$e']))),
        );
      }
    }
  }

  Future<void> _declineRequest(BuildContext context, WidgetRef ref) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateChallenge(challenge.id, {
        'arbiterStatus': ArbiterStatus.declined.name,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('declined_arbitration'.tr(args: [challenge.title]))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('failed_to_decline'.tr(args: ['$e']))),
        );
      }
    }
  }
}
