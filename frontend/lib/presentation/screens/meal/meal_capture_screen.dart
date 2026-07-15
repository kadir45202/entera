import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gap/gap.dart';

import '../../../data/repositories/meal_repository.dart';
import '../../../core/theme/theme.dart';

class MealCaptureScreen extends ConsumerStatefulWidget {
  const MealCaptureScreen({super.key});

  @override
  ConsumerState<MealCaptureScreen> createState() => _MealCaptureScreenState();
}

class _MealCaptureScreenState extends ConsumerState<MealCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  Uint8List? _imageBytes;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _error = null;
        });
        await _analyzeImage(bytes);
      }
    } catch (e) {
      setState(() {
        _error = 'Fotoğraf alınamadı';
      });
    }
  }

  Future<void> _analyzeImage(Uint8List imageBytes) async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });
    
    try {
      final repo = ref.read(mealRepositoryProvider);
      final analysis = await repo.analyzeMeal(imageBytes);
      
      if (mounted) {
        context.go('/meal/result', extra: {
          'analysis': analysis.toJson(),
          'imageBytes': imageBytes,
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Analiz başarısız. Lütfen tekrar deneyin.';
        _isAnalyzing = false;
      });
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
        title: const Text('Yemek Analizi'),
      ),
      body: SafeArea(
        child: _isAnalyzing
            ? _buildAnalyzingState(context)
            : _buildCaptureState(context),
      ),
    );
  }

  Widget _buildCaptureState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EnteraShapes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview area
          Expanded(
            child: BentoCard(
              padding: EdgeInsets.zero,
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: EnteraColors.textTertiary,
                          ),
                          const Gap(16),
                          Text(
                            'Yemeğinin fotoğrafını çek',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: EnteraColors.textSecondary,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            'Alerjen kontrolü yapacağız',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          
          const Gap(24),
          
          // Error message
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EnteraColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: EnteraColors.error,
                    size: 20,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: EnteraColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(16),
          ],
          
          // Capture buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri'),
                ),
              ),
              const Gap(16),
              Expanded(
                flex: 2,
                child: EnteraPrimaryButton(
                  label: 'Fotoğraf Çek',
                  icon: Icons.camera_alt,
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EnteraShapes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image preview with overlay
          Expanded(
            child: Stack(
              children: [
                if (_imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(EnteraShapes.cardRadius),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                      ),
                      const Gap(24),
                      Text(
                        'Analiz ediliyor...',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Gap(24),
          
          // Loading skeleton
          Shimmer.fromColors(
            baseColor: EnteraColors.border,
            highlightColor: EnteraColors.surfaceAlt,
            child: Column(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Gap(12),
                Container(
                  height: 20,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
