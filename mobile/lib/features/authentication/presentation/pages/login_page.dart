import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(authStateProvider.notifier)
          .login(_usernameController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        context.go(AppRouter.dashboard);
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    final authState = ref.watch(authStateProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Header Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.monitor_heart_rounded,
                      size: 44,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PFA Dialyse',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Système de Surveillance d\'Hémodialyse',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Username field
                  CustomTextField(
                    controller: _usernameController,
                    label: 'Nom d\'utilisateur',
                    hint: 'Entrez votre nom d\'utilisateur',
                    prefixIcon: Icons.person_outline,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Veuillez saisir votre nom d\'utilisateur';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    hint: 'Entrez votre mot de passe',
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondaryLight,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Veuillez saisir votre mot de passe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  CustomButton(
                    text: 'Se connecter',
                    isLoading: isLoading,
                    onPressed: _submitLogin,
                    icon: Icons.login_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
