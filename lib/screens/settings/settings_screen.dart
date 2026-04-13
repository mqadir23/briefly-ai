// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _eli5Mode         = false;
  bool _breakingNotifs   = true;
  bool _darkMode         = true;
  String _language       = 'en';
  String _region         = 'Global';
  final List<String> _interests = ['Technology', 'Finance', 'Pakistan'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Settings & Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingLg),
        children: [
          // Profile card
          _buildProfileCard(),
          const SizedBox(height: 24),

          // Preferences
          _buildSectionLabel('PREFERENCES'),
          const SizedBox(height: 10),
          _buildCard([
            _DropdownTile(
              icon: Icons.translate_rounded,
              title: 'Summary Language',
              value: AppConstants.supportedLanguages[_language] ?? 'English',
              options: AppConstants.supportedLanguages.values.toList(),
              onChanged: (v) {
                final key = AppConstants.supportedLanguages.entries
                    .firstWhere((e) => e.value == v).key;
                setState(() => _language = key);
              },
            ),
            _divider(),
            _DropdownTile(
              icon: Icons.public_rounded,
              title: 'Default Region',
              value: _region,
              options: AppConstants.regions,
              onChanged: (v) => setState(() => _region = v!),
            ),
          ]),

          const SizedBox(height: 20),

          // Interests
          _buildSectionLabel('INTERESTS'),
          const SizedBox(height: 10),
          _buildInterestsCard(),

          const SizedBox(height: 20),

          // Features
          _buildSectionLabel('FEATURES'),
          const SizedBox(height: 10),
          _buildCard([
            _SwitchTile(
              icon: Icons.child_care_rounded,
              title: 'ELI5 Mode',
              subtitle: 'Simplified explanations',
              value: _eli5Mode,
              activeColor: AppColors.amberAccent,
              onChanged: (v) => setState(() => _eli5Mode = v),
            ),
            _divider(),
            _SwitchTile(
              icon: Icons.notifications_rounded,
              title: 'Breaking News Alerts',
              subtitle: 'Push notifications for top stories',
              value: _breakingNotifs,
              onChanged: (v) => setState(() => _breakingNotifs = v),
            ),
            _divider(),
            _SwitchTile(
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              subtitle: 'Optimised for night reading',
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
            ),
          ]),

          const SizedBox(height: 20),

          // Data
          _buildSectionLabel('DATA'),
          const SizedBox(height: 10),
          _buildCard([
            _NavTile(
              icon: Icons.storage_rounded,
              title: 'Clear History',
              subtitle: 'Remove all saved summaries',
              onTap: () => _showConfirmDialog(
                  'Clear History', 'This will delete all summaries.'),
            ),
            _divider(),
            _NavTile(
              icon: Icons.bookmark_remove_rounded,
              title: 'Clear Bookmarks',
              subtitle: 'Remove all bookmarked articles',
              onTap: () {},
            ),
            _divider(),
            _NavTile(
              icon: Icons.download_rounded,
              title: 'Export Data',
              subtitle: 'Download summaries as JSON',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 20),

          // About
          _buildSectionLabel('ABOUT'),
          const SizedBox(height: 10),
          _buildCard([
            _NavTile(
              icon: Icons.info_outline_rounded,
              title: 'App Version',
              subtitle: 'v${AppConstants.appVersion}',
              onTap: null,
              trailing: const SizedBox(),
            ),
            _divider(),
            _NavTile(
              icon: Icons.code_rounded,
              title: 'GitHub Repository',
              subtitle: 'mqadir23/briefly-ai',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 32),

          // Sign out
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.redNegative,
              side: const BorderSide(color: AppColors.redNegative),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text('CS-418 Mobile App Development · BSDS-01',
              style: TextStyle(
                  color: AppColors.textHint, fontSize: 10)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Profile card ────────────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withOpacity(0.15),
            AppColors.purpleAi.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(
            color: AppColors.primaryBlue.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.purpleAi],
              ),
            ),
            child: const Center(
              child: Text('D',
                style: TextStyle(color: Colors.white,
                    fontSize: 22, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Muhammad Daniyal',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16, fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('daniyal@student.edu.pk',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Google Account',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 10, fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded,
                color: AppColors.textHint, size: 16),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── Interests chip editor ───────────────────────────────────────────────────
  Widget _buildInterestsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Topics',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12, fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              ..._interests.map((i) => Chip(
                label: Text(i),
                onDeleted: () => setState(() => _interests.remove(i)),
                deleteIcon: const Icon(Icons.close, size: 12),
                labelStyle: const TextStyle(
                    color: AppColors.primaryBlue, fontSize: 11),
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                side: const BorderSide(color: AppColors.primaryBlue, width: 1),
                deleteIconColor: AppColors.primaryBlue,
              )),
              ActionChip(
                label: const Text('+ Add'),
                labelStyle: const TextStyle(
                    color: AppColors.textHint, fontSize: 11),
                backgroundColor: AppColors.bgCardAlt,
                side: const BorderSide(color: AppColors.dividerColor),
                onPressed: () => _showAddInterestDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) => Text(label,
    style: const TextStyle(
      color: AppColors.textHint,
      fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5,
    ),
  );

  Widget _buildCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      border: Border.all(color: AppColors.dividerColor),
    ),
    child: Column(children: children),
  );

  Widget _divider() => const Divider(height: 1, indent: 50);

  void _showConfirmDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCardAlt,
        title: Text(title,
          style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message,
          style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Confirm',
              style: TextStyle(color: AppColors.redNegative)),
          ),
        ],
      ),
    );
  }

  void _showAddInterestDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCardAlt,
        title: const Text('Add Topic',
          style: TextStyle(color: AppColors.textPrimary)),
        content: Wrap(
          spacing: 8, runSpacing: 8,
          children: AppConstants.newsCategories
              .where((c) => !_interests.contains(c))
              .map((c) => ActionChip(
                label: Text(c),
                onPressed: () {
                  setState(() => _interests.add(c));
                  Navigator.pop(context);
                },
              )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable tile widgets ────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final Color? activeColor;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon, required this.title, required this.subtitle,
    required this.value, required this.onChanged, this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textHint, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
                Text(subtitle, style: const TextStyle(
                    color: AppColors.textHint, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor ?? AppColors.primaryBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _NavTile({
    required this.icon, required this.title, required this.subtitle,
    required this.onTap, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textHint, size: 18),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(
                      color: AppColors.textHint, fontSize: 11)),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.textHint, size: 13),
          ],
        ),
      ),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final List<String> options;
  final void Function(String?) onChanged;

  const _DropdownTile({
    required this.icon, required this.title, required this.value,
    required this.options, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textHint, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14)),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: AppColors.bgCardAlt,
              style: const TextStyle(
                  color: AppColors.primaryBlue, fontSize: 13),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textHint, size: 16),
              items: options.map((o) => DropdownMenuItem(
                value: o, child: Text(o))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
