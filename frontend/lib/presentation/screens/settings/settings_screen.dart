import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';
import '../../../data/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
    final displayName = authState.valueOrNull?.displayName;
    final email = authState.valueOrNull?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EnteraShapes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section
              BentoCard(
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: EnteraColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Icon(
                        Icons.person,
                        color: EnteraColors.primary,
                        size: 32,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName ?? 'Misafir',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (email != null) ...[
                            const Gap(4),
                            Text(
                              email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: EnteraColors.textSecondary,
                                  ),
                            ),
                          ],
                          if (!isAuthenticated) ...[
                            const Gap(4),
                            Text(
                              'Misafir olarak kullanıyorsunuz',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: EnteraColors.warning,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Gap(24),

              // Settings Options
              Text(
                'TERCIHLER',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.5,
                      color: EnteraColors.textTertiary,
                    ),
              ),
              const Gap(12),

              // Allergen Settings
              _SettingsTile(
                icon: Icons.warning_amber_outlined,
                title: 'Hassasiyetler & Alerjiler',
                subtitle: 'Besin hassasiyetlerini düzenle',
                onTap: () => context.go('/onboarding'),
              ),

              const Gap(32),

              // Account Actions
              if (isAuthenticated) ...[
                Text(
                  'HESAP',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                        color: EnteraColors.textTertiary,
                      ),
                ),
                const Gap(12),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(Icons.logout, color: EnteraColors.error),
                    label: const Text(
                      'Çıkış Yap',
                      style: TextStyle(color: EnteraColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: EnteraColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ] else ...[
                // Login prompt for guests
                Text(
                  'HESAP',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                        color: EnteraColors.textTertiary,
                      ),
                ),
                const Gap(12),

                EnteraPrimaryButton(
                  label: 'Giriş Yap veya Kayıt Ol',
                  onPressed: () => context.go('/login'),
                ),

                const Gap(8),
                Center(
                  child: Text(
                    'Verilerini senkronize etmek için giriş yap',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content:
            const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(
              'Çıkış Yap',
              style: TextStyle(color: EnteraColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EnteraColors.surface,
      borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
            border: Border.all(color: EnteraColors.borderLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: EnteraColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: EnteraColors.primary, size: 20),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Gap(2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: EnteraColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
