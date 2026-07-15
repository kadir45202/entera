import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/theme.dart';
import '../../../data/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authStateProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (!mounted) return;

      // Check if login was successful by checking the auth state
      final authState = ref.read(authStateProvider);

      if (authState.hasError) {
        if (mounted) {
          setState(() {
            _error = authState.error.toString();
            _isLoading = false;
          });
        }
        return;
      }

      if (authState.valueOrNull?.isAuthenticated == true) {
        if (mounted) {
          context.go('/home');
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Giriş başarısız. Lütfen bilgilerinizi kontrol edin.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(48),

                // Logo / Title
                Text(
                  'Entera',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: EnteraColors.primary,
                      ),
                ),
                const Gap(8),
                Text(
                  'Verilerini senkronize etmek için giriş yap',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: EnteraColors.textSecondary,
                      ),
                ),

                const Gap(48),

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
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: '••••••••',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre gerekli';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _login(),
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

                // Sign In Button
                EnteraPrimaryButton(
                  label: 'Giriş Yap',
                  onPressed: _login,
                  isLoading: _isLoading,
                ),

                const Gap(16),

                // Register link
                OutlinedButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Hesap Oluştur'),
                ),

                const Gap(24),

                // Guest option (Server-Based)
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).guestLogin();
                      if (mounted) {
                        context.go('/home');
                      }
                    },
                    child: const Text('Misafir Olarak Devam Et'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
