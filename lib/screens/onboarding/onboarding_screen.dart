import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pageIcons = [
    Icons.flag,
    Icons.volunteer_activism,
    Icons.people,
  ];

  static const _pageTitleKeys = [
    'onboarding_title_1',
    'onboarding_title_2',
    'onboarding_title_3',
  ];

  static const _pageDescKeys = [
    'onboarding_desc_1',
    'onboarding_desc_2',
    'onboarding_desc_3',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageIcons.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _pageIcons[index],
                          size: 100,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          _pageTitleKeys[index].tr(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pageDescKeys[index].tr(),
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pageIcons.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AppButton(
                label: _currentPage == _pageIcons.length - 1
                    ? 'get_started'.tr()
                    : 'next'.tr(),
                onPressed: () {
                  if (_currentPage == _pageIcons.length - 1) {
                    context.go(AppRoutes.login);
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
            if (_currentPage < _pageIcons.length - 1)
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text('skip'.tr()),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
