import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../authentication/domain/entities/user_entity.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

/// Flutter counterpart of Django `accounts/templates/profile.html`.
/// Displays the same identity block and phone/email/address cards from the
/// authenticated user payload returned by `/api/login/`.
///
/// Profile edit / password change require Django form POST endpoints that are
/// not yet exposed as mobile JSON APIs — those actions are deferred until an
/// API exists (no invented endpoints).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Non connecté')));
    }

    final user = authState.user;

    return AppShell(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Mon Profil',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Informations du compte connecté',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          if (user.firstLogin) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: const Text(
                'Première connexion : veuillez mettre à jour votre mot de passe '
                'depuis le profil web Django (API mobile de modification non '
                'disponible pour le moment).',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _IdentityCard(user: user),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.phone_outlined,
            label: 'Téléphone',
            value: _display(user.phone),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.mail_outline,
            label: 'Email',
            value: _display(user.email, empty: 'Non renseignée'),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.location_on_outlined,
            label: 'Adresse',
            value: _display(user.address, empty: 'Non renseignée'),
          ),
          if (user.specialite != null && user.specialite!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.medical_services_outlined,
              label: 'Spécialité',
              value: user.specialite!,
            ),
          ],
          const SizedBox(height: 24),
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
    );
  }

  static String _display(String? value, {String empty = 'Non renseigné'}) {
    if (value == null || value.trim().isEmpty) return empty;
    return value;
  }
}

class _IdentityCard extends StatelessWidget {
  final UserEntity user;

  const _IdentityCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 40,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    user.role,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF),
                    ),
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF2563EB)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
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
