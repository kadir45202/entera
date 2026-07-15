import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../data/repositories/log_repository.dart';
import '../../../core/theme/theme.dart';

class StoolLogScreen extends ConsumerStatefulWidget {
  const StoolLogScreen({super.key});

  @override
  ConsumerState<StoolLogScreen> createState() => _StoolLogScreenState();
}

class _StoolLogScreenState extends ConsumerState<StoolLogScreen> {
  int? _selectedType;
  String _notes = '';
  bool _isSaving = false;

  Future<void> _save() async {
    if (_selectedType == null) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(logRepositoryProvider).logStool(
            bristolType: _selectedType!,
            notes: _notes.isEmpty ? null : _notes,
          );
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydetme başarısız: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Dışkı Kaydı'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(EnteraShapes.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BRISTOL ÖLÇEĞİ',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            letterSpacing: 1.5,
                          ),
                    ),
                    const Gap(8),
                    Text(
                      'Size en uygun tipi seçin',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Gap(16),

                    // Bristol scale options (1-7)
                    ...List.generate(7, (index) {
                      final type = index + 1;
                      final isSelected = _selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BristolOption(
                          type: type,
                          emoji: BristolScale.emojis[type] ?? '❓',
                          description: BristolScale.descriptions[type] ?? '',
                          shortDesc: BristolScale.shortDescriptions[type] ?? '',
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selectedType = type);
                          },
                        ),
                      );
                    }),

                    const Gap(24),

                    // Notes
                    Text(
                      'NOTLAR (Opsiyonel)',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            letterSpacing: 1.5,
                          ),
                    ),
                    const Gap(8),
                    TextField(
                      maxLines: 2,
                      onChanged: (v) => _notes = v,
                      decoration: const InputDecoration(
                        hintText: 'Ek bilgi ekle...',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom button
            Container(
              padding: const EdgeInsets.all(EnteraShapes.paddingL),
              child: EnteraPrimaryButton(
                label: 'Kaydet',
                onPressed: _selectedType == null ? null : _save,
                isLoading: _isSaving,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BristolOption extends StatelessWidget {
  final int type;
  final String emoji;
  final String description;
  final String shortDesc;
  final bool isSelected;
  final VoidCallback onTap;

  const _BristolOption({
    required this.type,
    required this.emoji,
    required this.description,
    required this.shortDesc,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? EnteraColors.primary.withOpacity(0.05)
          : EnteraColors.surface,
      borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
            border: Border.all(
              color:
                  isSelected ? EnteraColors.primary : EnteraColors.borderLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tip $type - $shortDesc',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isSelected ? EnteraColors.primary : null,
                          ),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: EnteraColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
