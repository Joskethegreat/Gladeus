import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../widgets/glass_card.dart';
import '../widgets/outline_link_button.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onSave;

  const ProfileScreen({super.key, required this.profile, required this.onSave});

  // Apple system colours (dark appearance)
  static const _male = Color(0xFF0A84FF);
  static const _female = Color(0xFFFF375F);

  static const _links = <(String, IconData)>[
    ('Settings', Icons.settings_rounded),
    ('Feedback', Icons.campaign_rounded), // announcement
    ('Report', Icons.flag_rounded),
    ('Help', Icons.help_outline_rounded), // question mark
    ('Terms and Conditions', Icons.description_outlined), // script / document
  ];

  Future<void> _edit(BuildContext context) async {
    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(initial: profile)),
    );
    if (updated != null) onSave(updated);
  }

  String _num(double? v, String unit) {
    if (v == null) return '—';
    final text = v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
    return '$text$unit';
  }

  Widget? _genderSymbol() => switch (profile.gender) {
    Gender.male => const Icon(Icons.male_rounded, color: _male, size: 24),
    Gender.female => const Icon(Icons.female_rounded, color: _female, size: 24),
    _ => null, // other / prefer not to say / unset: no symbol
  };

  Widget _stat(BuildContext context, IconData icon, String text) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c.textTertiary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: c.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final symbol = _genderSymbol();

    return ListView(
      // Bottom padding keeps content clear of the floating nav bar.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 16),
          child: Text(
            'Profile',
            style: TextStyle(
              color: c.text,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
        ),
        GlassCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: c.divider,
                child: Icon(Icons.person_rounded, size: 44, color: c.textTertiary),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name gets its own full-width line (wraps instead of truncating).
                    Text(
                      profile.name.isEmpty ? 'Your name' : profile.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: profile.name.isEmpty ? c.textTertiary : c.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4, // tighter tracking at larger sizes
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ?symbol,
                        const Spacer(),
                        Text(
                          profile.age?.toString() ?? '—',
                          style: TextStyle(
                            color: c.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 20,
                      runSpacing: 6,
                      children: [
                        _stat(context, Icons.straighten_rounded, _num(profile.heightCm, 'cm')),
                        _stat(context, Icons.monitor_weight_outlined, _num(profile.weightKg, 'kg')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => _edit(context),
          icon: const Icon(Icons.edit_rounded),
          label: const Text('My Account'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFF5A623),
            foregroundColor: Colors.black87,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
        ),
        for (final (label, icon) in _links) ...[
          const SizedBox(height: 12),
          OutlineLinkButton(
            label: label,
            icon: icon,
            onPressed: label == 'Settings'
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    )
                : () {}, // TODO: hook up remaining destinations.
          ),
        ],
      ],
    );
  }
}
