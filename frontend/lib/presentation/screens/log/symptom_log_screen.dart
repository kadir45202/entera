import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../data/repositories/log_repository.dart';
import '../../../core/theme/theme.dart';

class SymptomLogScreen extends ConsumerStatefulWidget {
  const SymptomLogScreen({super.key});

  @override
  ConsumerState<SymptomLogScreen> createState() => _SymptomLogScreenState();
}

class _SymptomLogScreenState extends ConsumerState<SymptomLogScreen> {
  String? _selectedSymptom;
  int _severity = 5;
  String _notes = '';
  bool _isSaving = false;

  final _symptoms = [
    'Şişkinlik',
    'Kabızlık',
    'İshal',
    'Mide bulantısı',
    'Karın ağrısı',
    'Reflü',
    'Gaz',
    'Diğer',
  ];

  Future<void> _save() async {
    if (_selectedSymptom == null) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(logRepositoryProvider).logSymptom(
            symptomType: _selectedSymptom!,
            severity: _severity,
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

  Color _getSeverityColor() {
    if (_severity <= 3) return EnteraColors.success;
    if (_severity <= 6) return EnteraColors.warning;
    return EnteraColors.error;
  }

  String _getSeverityLabel() {
    if (_severity <= 3) return 'Hafif';
    if (_severity <= 6) return 'Orta';
    return 'Şiddetli';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Semptom Kaydı'),
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
                    // Symptom type
                    Text(
                      'SEMPTOM TİPİ',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            letterSpacing: 1.5,
                          ),
                    ),
                    const Gap(12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _symptoms.map((symptom) {
                        final isSelected = _selectedSymptom == symptom;
                        return Material(
                          color: isSelected
                              ? EnteraColors.primary
                              : EnteraColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedSymptom = symptom);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Text(
                                symptom,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : EnteraColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const Gap(32),

                    // Severity
                    Text(
                      'ŞİDDET',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            letterSpacing: 1.5,
                          ),
                    ),
                    const Gap(16),
                    BentoCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getSeverityLabel(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: _getSeverityColor(),
                                    ),
                              ),
                              Text(
                                '$_severity / 10',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const Gap(16),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: _getSeverityColor(),
                              thumbColor: _getSeverityColor(),
                              inactiveTrackColor:
                                  _getSeverityColor().withOpacity(0.2),
                              overlayColor:
                                  _getSeverityColor().withOpacity(0.1),
                            ),
                            child: Slider(
                              value: _severity.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              onChanged: (v) {
                                setState(() => _severity = v.round());
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Hafif',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Şiddetli',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

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
                onPressed: _selectedSymptom == null ? null : _save,
                isLoading: _isSaving,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
