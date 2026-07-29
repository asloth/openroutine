import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_prefs.dart';
import '../../state/app_prefs_provider.dart';

/// 3 intro slides + a storage-choice page, per docs/SPEC.md §7 screen 1.
/// Local-only is selected by default and fully functional; Google Drive is
/// shown but disabled ("Coming soon") — this session's decision to lock the
/// UI shape in now so M4 only flips a flag, not redesigns a screen.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;
  static const _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pageCount - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    await ref.read(onboardingCompleteProvider.notifier).complete();
    if (mounted) context.go('/routines');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(l10n.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _Slide(
                    title: l10n.onboardingSlide1Title,
                    body: l10n.onboardingSlide1Body,
                    icon: Icons.folder_shared_outlined,
                  ),
                  _Slide(
                    title: l10n.onboardingSlide2Title,
                    body: l10n.onboardingSlide2Body,
                    icon: Icons.timer_outlined,
                  ),
                  _Slide(
                    title: l10n.onboardingSlide3Title,
                    body: l10n.onboardingSlide3Body,
                    icon: Icons.smart_toy_outlined,
                  ),
                  const _StorageChoiceSlide(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pageCount; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _page == _pageCount - 1
                        ? l10n.onboardingGetStarted
                        : l10n.onboardingNext,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.title, required this.body, required this.icon});

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 96, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StorageChoiceSlide extends ConsumerWidget {
  const _StorageChoiceSlide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mode = ref.watch(storageModeSettingProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onboardingStorageChoiceTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingStorageChoiceBody,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          RadioGroup<StorageMode>(
            groupValue: mode,
            onChanged: (value) {
              if (value != null) {
                ref.read(storageModeSettingProvider.notifier).setMode(value);
              }
            },
            child: Column(
              children: [
                RadioListTile<StorageMode>(
                  value: StorageMode.local,
                  title: Text(l10n.storageModeLocalOnly),
                  subtitle: Text(l10n.onboardingStorageLocalDescription),
                ),
                RadioListTile<StorageMode>(
                  value: StorageMode.drive,
                  enabled: false,
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.storageModeGoogleDrive),
                      const SizedBox(width: 8),
                      _ComingSoonBadge(text: l10n.comingSoon),
                    ],
                  ),
                  subtitle: Text(l10n.onboardingStorageDriveDescription),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
