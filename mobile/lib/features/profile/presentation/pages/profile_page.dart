import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Non connecté')));
    }

    final user = authState.user;

    Color roleBgColor = AppColors.primaryLight;
    Color roleTextColor = AppColors.primary;
    if (user.isDoctor) {
      roleBgColor = const Color(0xFFE0E7FF);
      roleTextColor = const Color(0xFF4338CA);
    } else if (user.isNurse) {
      roleBgColor = const Color(0xFFDCFCE7);
      roleTextColor = const Color(0xFF15803D);
    } else if (user.isAdmin) {
      roleBgColor = const Color(0xFFFEE2E2);
      roleTextColor = const Color(0xFFB91C1C);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Utilisateur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRouter.login);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // User Avatar & Role Badge
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: roleBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: roleTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Profile Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      icon: Icons.person_outline,
                      label: 'Nom d\'utilisateur',
                      value: user.username,
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email ?? 'Non renseigné',
                    ),
                    const Divider(),
                    _buildInfoRow(
                      context,
                      icon: Icons.badge_outlined,
                      label: 'Rôle System',
                      value: user.role,
                    ),
                    if (user.specialite != null &&
                        user.specialite!.isNotEmpty) ...[
                      const Divider(),
                      _buildInfoRow(
                        context,
                        icon: Icons.medical_services_outlined,
                        label: 'Spécialité',
                        value: user.specialite!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Logout Action Button
            CustomButton(
              text: 'Se déconnecter',
              backgroundColor: AppColors.danger,
              icon: Icons.logout_rounded,
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  context.go(AppRouter.login);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
