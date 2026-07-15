import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../data/providers/auth_provider.dart';
import '../../../data/repositories/meal_repository.dart';
import '../../../data/repositories/log_repository.dart';
import '../../../core/theme/theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
    final userName = authState.valueOrNull?.greeting ?? 'Misafir';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EnteraShapes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              _buildHeader(context, userName, isAuthenticated),

              const Gap(32),

              // Bento Grid
              _buildBentoGrid(context),

              const Gap(32),

              // Recent Activity
              _buildRecentSection(context, ref),

              // Guest notice
              if (!isAuthenticated) ...[
                const Gap(24),
                _buildGuestNotice(context),
              ],
            ],
          ),
        ),
      ),

      // FAB - Primary action
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: EnteraShadows.fab,
        ),
        child: FloatingActionButton.large(
          onPressed: () => context.go('/meal/capture'),
          elevation: 0,
          child: const Icon(Icons.add, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader(BuildContext context, String userName, bool isAuth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Merhaba, $userName',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const Gap(4),
            Text(
              _getDateString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EnteraColors.textSecondary,
                  ),
            ),
          ],
        ),
        if (!isAuth)
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Giriş Yap'),
          )
        else
          IconButton(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.person_outline),
            style: IconButton.styleFrom(
              backgroundColor: EnteraColors.surfaceAlt,
            ),
          ),
      ],
    );
  }

  Widget _buildBentoGrid(BuildContext context) {
    return Column(
      children: [
        // Top row - 2 items
        Row(
          children: [
            // Quick Action - Snap & Check
            Expanded(
              flex: 3,
              child: _BentoTile(
                title: 'Fotoğraf Çek',
                subtitle: 'Yemeğini analiz et',
                icon: Icons.camera_alt_outlined,
                color: EnteraColors.primary,
                onTap: () => context.go('/meal/capture'),
                height: 140,
              ),
            ),
            const Gap(12),
            // AI Chat
            Expanded(
              flex: 2,
              child: _BentoTile(
                title: 'AI',
                subtitle: 'Soru sor',
                icon: Icons.chat_bubble_outline,
                color: EnteraColors.success,
                onTap: () => context.go('/chat'),
                height: 140,
              ),
            ),
          ],
        ),

        const Gap(12),

        // Bottom row - 3 items
        Row(
          children: [
            Expanded(
              child: _BentoTile(
                title: 'Dışkı',
                subtitle: 'Kaydet',
                icon: Icons.water_drop_outlined,
                color: EnteraColors.warning,
                onTap: () => context.go('/log/stool'),
                height: 100,
                compact: true,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _BentoTile(
                title: 'Semptom',
                subtitle: 'Takip et',
                icon: Icons.healing_outlined,
                color: EnteraColors.error,
                onTap: () => context.go('/log/symptom'),
                height: 100,
                compact: true,
              ),
            ),
            const Gap(12),
            Expanded(
              child: _BentoTile(
                title: 'Analiz',
                subtitle: 'İçgörüler',
                icon: Icons.insights_outlined,
                color: EnteraColors.primary,
                onTap: () => context.go('/insights'),
                height: 100,
                compact: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentSection(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealHistoryProvider);
    final logs = ref.watch(allLogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SON AKTİVİTELER',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 1.5,
                color: EnteraColors.textTertiary,
              ),
        ),
        const Gap(16),
        if (meals.isEmpty && logs.isEmpty)
          _buildEmptyState(context)
        else
          _RecentActivityList(meals: meals, logs: logs),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return BentoCard(
      child: Column(
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 48,
            color: EnteraColors.textTertiary,
          ),
          const Gap(12),
          Text(
            'Henüz aktivite yok',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Gap(4),
          Text(
            'İlk yemeğini analiz etmek için + butonuna dokun',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildGuestNotice(BuildContext context) {
    return BentoCard(
      backgroundColor: EnteraColors.primary.withOpacity(0.05),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: EnteraColors.primary,
            size: 20,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Misafir Modu',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Gap(2),
                Text(
                  'Verilerini senkronize etmek için giriş yap',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDateString() {
    final now = DateTime.now();
    final months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    final days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}

// ============================================
// BENTO TILE
// ============================================

class _BentoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double height;
  final bool compact;

  const _BentoTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.height = 120,
    this.compact = false,
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
          height: height,
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
            border: Border.all(color: EnteraColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: compact ? 20 : 24,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: compact
                        ? Theme.of(context).textTheme.titleSmall
                        : Theme.of(context).textTheme.titleMedium,
                  ),
                  if (!compact) ...[
                    const Gap(2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// RECENT ACTIVITY LIST
// ============================================

class _RecentActivityList extends StatelessWidget {
  final List<MealAnalysis> meals;
  final List<HealthLog> logs;

  const _RecentActivityList({
    required this.meals,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    // Combine and sort by time
    final items = [
      ...meals.take(3).map((meal) => _ActivityEntry(
            icon: Icons.restaurant_outlined,
            color: EnteraColors.primary,
            title: 'Yemek analiz edildi',
            subtitle: meal.riskLevel == 'none'
                ? 'Sorun yok'
                : '${meal.detectedAllergens.length} alerjen',
            time: meal.createdAt,
            riskLevel: meal.riskLevel,
          )),
      ...logs.take(3).map((log) => _ActivityEntry(
            icon: log.type == LogType.stool
                ? Icons.water_drop_outlined
                : Icons.healing_outlined,
            color: log.type == LogType.stool
                ? EnteraColors.warning
                : EnteraColors.error,
            title: log.type == LogType.stool
                ? 'Dışkı: Tip ${log.value}'
                : log.tags.firstOrNull ?? 'Semptom',
            subtitle: log.type == LogType.stool
                ? BristolScale.shortDescriptions[log.value] ?? ''
                : 'Şiddet ${log.value}/10',
            time: log.createdAt,
          )),
    ];

    items.sort((a, b) => b.time.compareTo(a.time));

    return Column(
      children: items.take(5).map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ActivityRow(entry: item),
        );
      }).toList(),
    );
  }
}

class _ActivityEntry {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime time;
  final String? riskLevel;

  _ActivityEntry({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    this.riskLevel,
  });
}

class _ActivityRow extends StatelessWidget {
  final _ActivityEntry entry;

  const _ActivityRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: entry.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(entry.icon, color: entry.color, size: 18),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                entry.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (entry.riskLevel != null) ...[
          RiskIndicator(level: entry.riskLevel!),
          const Gap(8),
        ],
        Text(
          _formatTime(entry.time),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk';
    if (diff.inHours < 24) return '${diff.inHours}sa';
    return '${diff.inDays}g';
  }
}
