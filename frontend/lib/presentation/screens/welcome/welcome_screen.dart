import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/user_profile_repository.dart';
import '../../../data/repositories/allergen_repository.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/theme/theme.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  String? _selectedGender;
  final Set<String> _selectedAllergens = {};
  bool _isSaving = false;

  final _genders = [
    {'value': 'male', 'label': 'Erkek', 'icon': Icons.male},
    {'value': 'female', 'label': 'Kadın', 'icon': Icons.female},
    {'value': 'other', 'label': 'Diğer', 'icon': Icons.transgender},
  ];

  final _commonAllergens = [
    'Gluten',
    'Laktoz',
    'Fıstık',
    'Yumurta',
    'Deniz Ürünleri',
    'Soya',
    'Fındık',
    'Süt',
  ];

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    print('🚀 Save and Continue clicked');

    // 0. Capture dependencies early (so we can use them even if widget unmounts)
    final authNotifier = ref.read(authStateProvider.notifier);
    final userRepo = ref.read(userProfileRepositoryProvider);
    final allergenRepo = ref.read(allergenRepositoryProvider);
    // Capture the state notifier provider so we can update it later
    final welcomeNotifier = ref.read(hasCompletedWelcomeProvider.notifier);

    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }
    if (_selectedGender == null) {
      print('❌ Gender not selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen cinsiyet seçin')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Guest Login (Create User)
      final currentAuthState = ref.read(authStateProvider);

      print(
          '🔐 Current Auth State: ${currentAuthState.valueOrNull?.isAuthenticated}');

      if (currentAuthState.valueOrNull?.isAuthenticated != true) {
        print('🔐 Attempting Guest Login...');
        await authNotifier.guestLogin();
      } else {
        print('🔐 Already authenticated, skipping login');
      }

      // Check if login successful (Using Supabase client directly)
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Misafir girişi yapılamadı (Kullanıcı null)');
      }
      print('✅ Login successful/confirmed. User ID: ${currentUser.id}');

      // 2. Update Profile with Age/Gender (Using captured repo)
      print('📝 Updating profile...');

      // Also save allergens to allergen repository
      if (_selectedAllergens.isNotEmpty) {
        print('📝 Saving allergens locally...');
        final allAllergens = await allergenRepo.getAllAllergens();
        final matchingIds = allAllergens
            .where((a) => _selectedAllergens
                .any((s) => a.name.toLowerCase().contains(s.toLowerCase())))
            .map((a) => a.id)
            .toList();
        await allergenRepo.saveSelectedAllergenIds(matchingIds);

        // Sync allergens to Supabase
        if (currentUser != null) {
          print('☁️ Syncing allergens to Supabase...');
          try {
            await allergenRepo.syncToSupabase(matchingIds);
          } catch (e) {
            print('⚠️ Allergen sync warning: $e');
          }
        }
      }

      await userRepo.updateProfile(
        age: int.parse(_ageController.text),
        gender: _selectedGender!,
        allergens: _selectedAllergens.toList(),
      );
      print('✅ Profile updated');

      // 3. Mark Welcome Complete & Onboarding Complete
      print('🏁 Marking welcome as completed...');
      await userRepo.setWelcomeCompleted();

      // Force update provider state (Using captured notifier)
      welcomeNotifier.state = true;

      await authNotifier.completeOnboarding();
      print('✅ All completion steps finished');

      if (mounted) {
        print('👉 Navigating to /home');
        context.go('/home');
      }
    } catch (e, stack) {
      print('❌ Error in _saveAndContinue: $e');
      print(stack);
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EnteraShapes.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Gap(40),

                // Logo
                Center(
                  child: Text(
                    'Entera',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: EnteraColors.primary,
                          fontWeight: FontWeight.w300,
                        ),
                  ),
                ),
                const Gap(8),
                Center(
                  child: Text(
                    'Sindirim Sağlığı Asistanın',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: EnteraColors.textSecondary,
                        ),
                  ),
                ),

                const Gap(48),

                // Age input
                Text(
                  'YAŞINIZ',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                      ),
                ),
                const Gap(8),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Örn: 25',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Yaş gerekli';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
                      return 'Geçerli bir yaş girin';
                    }
                    return null;
                  },
                ),

                const Gap(24),

                // Gender selection
                Text(
                  'CİNSİYET',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                      ),
                ),
                const Gap(12),
                Row(
                  children: _genders.map((gender) {
                    final isSelected = _selectedGender == gender['value'];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: gender != _genders.last ? 8 : 0,
                        ),
                        child: Material(
                          color: isSelected
                              ? EnteraColors.primary
                              : EnteraColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedGender = gender['value'] as String;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? EnteraColors.primary
                                      : EnteraColors.border,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    gender['icon'] as IconData,
                                    color: isSelected
                                        ? Colors.white
                                        : EnteraColors.textPrimary,
                                    size: 28,
                                  ),
                                  const Gap(4),
                                  Text(
                                    gender['label'] as String,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : EnteraColors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const Gap(32),

                // Allergens (optional)
                Row(
                  children: [
                    Text(
                      'ALERJİLER',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            letterSpacing: 1.5,
                          ),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: EnteraColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Opsiyonel',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  'Varsa besin hassasiyetlerini seç',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Gap(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonAllergens.map((allergen) {
                    final isSelected = _selectedAllergens.contains(allergen);
                    return Material(
                      color: isSelected
                          ? EnteraColors.primary
                          : EnteraColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedAllergens.remove(allergen);
                            } else {
                              _selectedAllergens.add(allergen);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(
                            allergen,
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

                const Gap(48),

                // Start button
                EnteraPrimaryButton(
                  label: 'Başla',
                  onPressed: _saveAndContinue,
                  isLoading: _isSaving,
                ),

                const Gap(16),

                // Privacy note
                Center(
                  child: Text(
                    'Verileriniz güvenle saklanır ve paylaşılmaz.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: EnteraColors.textTertiary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Gap(24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
