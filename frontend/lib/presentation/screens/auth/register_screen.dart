import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';
import '../../../data/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedGender;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    String? gender = _selectedGender;
    if (gender == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen cinsiyet seçin')),
        );
      }
      return;
    }

    if (!mounted) return;

    // Check if user is currently a guest
    final authNotifier = ref.read(authStateProvider.notifier);
    final isGuest = authNotifier.isGuest;

    if (isGuest) {
      // Ask user if they want to keep their guest data
      final shouldKeepData = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Verilerini Koru'),
          content: const Text(
            'Mevcut misafir verilerini yeni hesabına taşımak ister misin?\n\n'
            'Evet dersen, şu ana kadar girdiğin tüm kayıtlar ve analizler korunacak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hayır, Sıfırdan Başla'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Evet, Verilerimi Koru'),
            ),
          ],
        ),
      );

      if (shouldKeepData == null) return; // Dismissed

      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        if (shouldKeepData) {
          // PROMOTE ACCOUNT (MERGE)
          await authNotifier.promoteAccount(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );
        } else {
          // FRESH START (LOGOUT + REGISTER)
          await authNotifier.logout();
          // Small delay to ensure logout completes
          await Future.delayed(const Duration(milliseconds: 500));

          await authNotifier.register(
            _emailController.text.trim(),
            _passwordController.text,
            displayName: _nameController.text.trim(),
            age: int.tryParse(_ageController.text.trim()),
            gender: gender,
          );
        }

        await _handleAuthResult();
      } catch (e) {
        _handleError(e);
      }
    } else {
      // NORMAL REGISTRATION
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        await authNotifier.register(
          _emailController.text.trim(),
          _passwordController.text,
          displayName: _nameController.text.trim(),
          age: int.tryParse(_ageController.text.trim()),
          gender: gender,
        );

        await _handleAuthResult();
      } catch (e) {
        _handleError(e);
      }
    }
  }

  Future<void> _handleAuthResult() async {
    if (!mounted) return;

    final authState = ref.read(authStateProvider);

    if (authState.hasError) {
      setState(() {
        _error = authState.error.toString();
        _isLoading = false;
      });
      return;
    }

    if (authState.valueOrNull?.isAuthenticated == true) {
      // Onboarding or Home based on need
      context.go('/home');
    } else {
      setState(() {
        _error = 'Kayıt başarısız.';
        _isLoading = false;
      });
    }
  }

  void _handleError(Object e) {
    if (mounted) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EnteraShapes.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Hesap Oluştur',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const Gap(8),
                Text(
                  'Bağırsak sağlığı yolculuğuna başla',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: EnteraColors.textSecondary,
                      ),
                ),

                const Gap(40),

                // Name Field
                Text(
                  'AD SOYAD',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                      ),
                ),
                const Gap(8),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Adınızı girin',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Adınızı girin';
                    }
                    if (value.length < 2) {
                      return 'Ad en az 2 karakter olmalı';
                    }
                    return null;
                  },
                ),

                const Gap(24),

                // Age and Gender Row
                Row(
                  children: [
                    // Age Field
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YAŞ',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  letterSpacing: 1.5,
                                ),
                          ),
                          const Gap(8),
                          TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: '25',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Yaş gerekli';
                              }
                              final age = int.tryParse(value);
                              if (age == null || age < 13 || age > 120) {
                                return 'Geçerli yaş girin';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),
                    // Gender Field
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CİNSİYET',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  letterSpacing: 1.5,
                                ),
                          ),
                          const Gap(8),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: const InputDecoration(
                              hintText: 'Seçiniz',
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Erkek', child: Text('Erkek')),
                              DropdownMenuItem(
                                  value: 'Kadın', child: Text('Kadın')),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedGender = value);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Cinsiyet seçin';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const Gap(24),

                // Email
                Text(
                  'E-POSTA',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                      ),
                ),
                const Gap(8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'ornek@email.com',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'E-posta gerekli';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli bir e-posta girin';
                    }
                    return null;
                  },
                ),

                const Gap(24),

                // Password
                Text(
                  'ŞİFRE',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                      ),
                ),
                const Gap(8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre gerekli';
                    }
                    if (value.length < 6) {
                      return 'En az 6 karakter';
                    }
                    return null;
                  },
                ),

                const Gap(24),

                // Confirm Password
                Text(
                  'ŞİFRE TEKRAR',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.5,
                      ),
                ),
                const Gap(8),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Şifreler eşleşmiyor';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _register(),
                ),

                const Gap(32),

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

                // Register Button
                EnteraPrimaryButton(
                  label: 'Hesap Oluştur',
                  onPressed: _register,
                  isLoading: _isLoading,
                ),

                const Gap(24),

                // Terms
                Text(
                  'Hesap oluşturarak Kullanım Koşullarını ve Gizlilik Politikasını kabul etmiş olursunuz.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
