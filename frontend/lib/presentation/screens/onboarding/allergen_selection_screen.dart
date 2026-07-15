import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../data/repositories/allergen_repository.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';

class AllergenSelectionScreen extends ConsumerStatefulWidget {
  const AllergenSelectionScreen({super.key});

  @override
  ConsumerState<AllergenSelectionScreen> createState() =>
      _AllergenSelectionScreenState();
}

class _AllergenSelectionScreenState
    extends ConsumerState<AllergenSelectionScreen> {
  final Set<int> _selectedIds = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final savedIds = ref.read(selectedAllergenIdsProvider);
    _selectedIds.addAll(savedIds);
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(allergenRepositoryProvider);

      // Save locally
      await repo.saveSelectedAllergenIds(_selectedIds.toList());
      ref.read(selectedAllergenIdsProvider.notifier).state =
          _selectedIds.toList();

      // Sync to Supabase if authenticated
      final authState = ref.read(authStateProvider).valueOrNull;
      if (authState != null && authState.isAuthenticated) {
        // Did not await this on purpose to not block UI?
        // No, better await it or let it run in background.
        // For onboarding, safer to await to ensure data integrity before Home.
        try {
          await repo.syncToSupabase(_selectedIds.toList());
        } catch (e) {
          // Ignore sync error, local save is enough for now
        }
      }

      // Mark as complete
      await ref.read(authStateProvider.notifier).completeOnboarding();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
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
    final allergensAsync = ref.watch(allergensListProvider);

    return Scaffold(
      body: SafeArea(
        child: allergensAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Hata: $e')),
          data: (allergens) => Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(EnteraShapes.paddingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(32),
                    Text(
                      'Hassasiyetlerin neler?',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const Gap(8),
                    Text(
                      'Besin hassasiyetlerini seç. Tespit ettiğimizde seni uyaracağız.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: EnteraColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              // Allergen chips
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EnteraShapes.paddingL,
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: allergens.map((allergen) {
                      final isSelected = _selectedIds.contains(allergen.id);

                      return _AllergenChip(
                        name: allergen.name,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(allergen.id);
                            } else {
                              _selectedIds.add(allergen.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Bottom section
              Container(
                padding: const EdgeInsets.all(EnteraShapes.paddingL),
                child: Column(
                  children: [
                    if (_selectedIds.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: EnteraColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_selectedIds.length} hassasiyet seçildi',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const Gap(16),
                    ],
                    EnteraPrimaryButton(
                      label: _selectedIds.isEmpty ? 'Atla' : 'Devam Et',
                      onPressed: _saveAndContinue,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllergenChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _AllergenChip({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? EnteraColors.primary : EnteraColors.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? EnteraColors.primary : EnteraColors.border,
            ),
          ),
          child: Text(
            name,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected ? Colors.white : EnteraColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ),
      ),
    );
  }
}
