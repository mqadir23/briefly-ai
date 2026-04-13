// lib/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Selections
  final Set<String> _selectedInterests = {};
  String _selectedRegion  = 'Global';
  String _selectedLanguage = 'en';

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
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

  void _finish() {
    // Save preferences and navigate to home
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(3, (i) => _buildDot(i)),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _buildInterestsPage(),
                  _buildRegionPage(),
                  _buildLanguagePage(),
                ],
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _currentPage == 0 && _selectedInterests.isEmpty
                        ? null
                        : _nextPage,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      disabledBackgroundColor: AppColors.dividerColor,
                    ),
                    child: Text(_currentPage < 2 ? 'Continue' : 'Get Started'),
                  ),
                  if (_currentPage > 0) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                      ),
                      child: const Text('Back',
                        style: TextStyle(color: AppColors.textSecondary)),
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

  Widget _buildDot(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 6),
      width:  isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryBlue
            : AppColors.dividerColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildInterestsPage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text('What interests\nyou?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Pick at least one topic to personalise your feed.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10, runSpacing: 10,
                children: AppConstants.newsCategories.map((cat) {
                  final selected = _selectedInterests.contains(cat);
                  return GestureDetector(
                    onTap: () => setState(() {
                      selected
                          ? _selectedInterests.remove(cat)
                          : _selectedInterests.add(cat);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryBlue.withOpacity(0.15)
                            : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryBlue
                              : AppColors.dividerColor,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selected) ...[
                            const Icon(Icons.check_circle_rounded,
                              color: AppColors.primaryBlue, size: 14),
                            const SizedBox(width: 6),
                          ],
                          Text(cat,
                            style: TextStyle(
                              color: selected
                                  ? AppColors.primaryBlue
                                  : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
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

  Widget _buildRegionPage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text('Your region?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          const Text('We\'ll focus InsightLens on news from your area.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: AppConstants.regions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final region  = AppConstants.regions[i];
                final selected = region == _selectedRegion;
                return GestureDetector(
                  onTap: () => setState(() => _selectedRegion = region),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryBlue.withOpacity(0.12)
                          : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryBlue
                            : AppColors.dividerColor,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(region,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primaryBlue
                                : AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                            color: AppColors.primaryBlue, size: 20),
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

  Widget _buildLanguagePage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text('Preferred\nlanguage?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Summaries will be translated into this language.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: AppConstants.supportedLanguages.entries.map((e) {
                final selected = e.key == _selectedLanguage;
                return GestureDetector(
                  onTap: () => setState(() => _selectedLanguage = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryBlue.withOpacity(0.12)
                          : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.primaryBlue
                                    : AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                            Text(e.key.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textHint, fontSize: 11)),
                          ],
                        ),
                        const Spacer(),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                            color: AppColors.primaryBlue, size: 20),
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