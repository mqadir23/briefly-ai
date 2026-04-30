import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../providers/preferences_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Set<String> _selectedInterests = {};
  String _selectedRegion   = 'Global';
  String _selectedLanguage = 'en';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _finish() async {
    final notifier = ref.read(preferencesProvider.notifier);
    await notifier.updateInterests(_selectedInterests.toList());
    await notifier.updateRegion(_selectedRegion);
    await notifier.updateLanguage(_selectedLanguage);
    await notifier.setOnboardingDone();
    if (mounted) Navigator.of(context).pushReplacementNamed('/home');
  }

  bool get _canContinue {
    if (_currentPage == 0) return _selectedInterests.isNotEmpty;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress dots ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(3, (i) => _buildDot(i)),
              ),
            ),

            // ── Pages ────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _buildInterestsPage(),
                  _buildRegionPage(),
                  _buildLanguagePage(),
                ],
              ),
            ),

            // ── Bottom buttons ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _canContinue ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor:
                          AppColors.dividerColor,
                      disabledForegroundColor:
                          AppColors.textHint,
                    ),
                    child: Text(
                      _currentPage < 2 ? 'Continue' : 'Get Started',
                    ),
                  ),
                  if (_currentPage > 0) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _prevPage,
                      child: const Text(
                        'Back',
                        style: TextStyle(
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Progress dot ───────────────────────────────────────────────────────────

  Widget _buildDot(int index) {
    final active = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 6),
      width:  active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active
            ? AppColors.primaryBlue
            : AppColors.dividerColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ── Page 1: Interests ─────────────────────────────────────────────────────

  Widget _buildInterestsPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'What interests\nyou?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pick at least one topic to personalise your feed.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.newsCategories.map((cat) {
                  final selected = _selectedInterests.contains(cat);
                  return GestureDetector(
                    onTap: () => setState(() => selected
                        ? _selectedInterests.remove(cat)
                        : _selectedInterests.add(cat)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryBlue
                                .withOpacity(0.15)
                            : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryBlue
                              : AppColors.dividerColor,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      // ✅ FIX: no icon inside the chip row — avoids overflow
                      child: Text(
                        selected ? '✓  $cat' : cat,
                        style: TextStyle(
                          color: selected
                              ? AppColors.primaryBlue
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 2: Region ────────────────────────────────────────────────────────

  Widget _buildRegionPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Your region?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll focus InsightLens on news from your area.",
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.separated(
              itemCount: AppConstants.regions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final region   = AppConstants.regions[i];
                final selected = region == _selectedRegion;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedRegion = region),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryBlue
                              .withOpacity(0.12)
                          : AppColors.bgCard,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMd),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryBlue
                            : AppColors.dividerColor,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          region,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primaryBlue
                                : AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 3: Language ──────────────────────────────────────────────────────

  Widget _buildLanguagePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Preferred\nlanguage?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Summaries will be translated into this language.',
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView(
              children: AppConstants.supportedLanguages.entries
                  .map((e) {
                final selected = e.key == _selectedLanguage;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedLanguage = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryBlue
                              .withOpacity(0.12)
                          : AppColors.bgCard,
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMd),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryBlue
                            : AppColors.dividerColor,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.value,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.primaryBlue
                                    : AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            Text(
                              e.key.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}