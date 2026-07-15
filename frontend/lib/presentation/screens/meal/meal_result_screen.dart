import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../data/repositories/meal_repository.dart';
import '../../../core/theme/theme.dart';

class MealResultScreen extends ConsumerWidget {
  final Map<String, dynamic>? analysisResult;

  const MealResultScreen({super.key, this.analysisResult});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (analysisResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analiz')),
        body: const Center(child: Text('Analiz verisi yok')),
      );
    }

    final analysis =
        MealAnalysis.fromJson(analysisResult!['analysis'] ?? analysisResult!);
    final imageBytes = analysisResult!['imageBytes'] as Uint8List?;

    final hasWarnings = analysis.hasWarnings;
    final riskColor = _getStatusColor(analysis.riskLevel, hasWarnings);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Analiz Sonuçları',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Yemek Adı (Başlık)
                    if (analysis.summary != null)
                      Text(
                        analysis.summary!,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                        textAlign: TextAlign.center,
                      ),

                    const Gap(16),

                    // 2. Kompakt Yemek Fotoğrafı (Ekranın 1/3'ü)
                    if (imageBytes != null)
                      Container(
                        width: MediaQuery.of(context).size.width * 0.35,
                        height: MediaQuery.of(context).size.width * 0.35,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    const Gap(20),

                    // 3. Güvenlik Durumu Kartı
                    _buildStatusCard(context, analysis, riskColor, hasWarnings),

                    const Gap(24),

                    // 4. Tespit Edilen İçerikler Başlığı
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'TESPİT EDİLEN İÇERİKLER',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                      ),
                    ),

                    const Gap(12),

                    // 5. İçerik Listesi
                    _buildIngredientsList(context, analysis),

                    // 6. Alerjen Uyarıları (varsa)
                    if (analysis.detectedAllergens.isNotEmpty) ...[
                      const Gap(24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ALERJEN UYARILARI',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[400],
                                  ),
                        ),
                      ),
                      const Gap(12),
                      _buildAllergensList(context, analysis),
                    ],

                    const Gap(32),
                  ],
                ),
              ),
            ),

            // Alt Butonlar
            _buildBottomButtons(context, ref, analysis),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, MealAnalysis analysis,
      Color statusColor, bool hasWarnings) {
    final icon = hasWarnings ? Icons.warning_amber_rounded : Icons.check_circle;
    final title = hasWarnings ? 'Dikkat Gerekiyor' : 'Güvenli Görünüyor';
    final description = hasWarnings
        ? 'Bazı alerjenler tespit edildi. Detayları kontrol edin.'
        : 'Bilinen bir alerjen tespit edilmedi.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 28),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hasWarnings ? '⚠️' : '✅',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Gap(6),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsList(BuildContext context, MealAnalysis analysis) {
    if (analysis.detectedIngredients.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Malzeme tespit edilemedi',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: analysis.detectedIngredients.asMap().entries.map((entry) {
          final index = entry.key;
          final ingredient = entry.value;
          final name = ingredient['name'] as String? ?? 'Bilinmiyor';
          final confidence =
              (ingredient['confidence'] as num?)?.toDouble() ?? 0.5;
          final isLastItem = index == analysis.detectedIngredients.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    // İkon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: EnteraColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        confidence >= 0.8 ? Icons.check : Icons.help_outline,
                        color: confidence >= 0.8
                            ? EnteraColors.success
                            : Colors.orange,
                        size: 16,
                      ),
                    ),
                    const Gap(12),
                    // Malzeme adı
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    // Güven skoru
                    if (confidence >= 0.9)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: EnteraColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Kesin',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: EnteraColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isLastItem) Divider(height: 1, color: Colors.grey[200]),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAllergensList(BuildContext context, MealAnalysis analysis) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(
        children: analysis.detectedAllergens.map((allergen) {
          final name = allergen['name'] as String? ?? 'Bilinmiyor';
          final trigger = allergen['trigger_ingredient'] as String? ?? '';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red[400], size: 20),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                      ),
                      if (trigger.isNotEmpty)
                        Text(
                          'Kaynak: $trigger',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red[400],
                                  ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomButtons(
      BuildContext context, WidgetRef ref, MealAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Reddet butonu
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/meal/capture'),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Tekrar Çek'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Gap(12),
          // Onayla butonu
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Save to local storage
                final repo = ref.read(mealRepositoryProvider);
                await repo.saveMeal(analysis);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Yemek kaydedildi!'),
                    backgroundColor: Colors.green,
                  ),
                );
                context.go('/home');
              },
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EnteraColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String riskLevel, bool hasWarnings) {
    if (hasWarnings || riskLevel == 'high') return Colors.red;
    if (riskLevel == 'medium') return Colors.orange;
    if (riskLevel == 'low') return Colors.amber;
    return EnteraColors.success;
  }
}
