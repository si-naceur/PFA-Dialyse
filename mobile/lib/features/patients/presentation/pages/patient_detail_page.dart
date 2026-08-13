import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/patient_session_entity.dart';
import '../providers/patients_provider.dart';
import '../widgets/patient_formatting.dart';
import '../widgets/status_badge.dart';

/// Patient dossier screen.
class PatientDetailPage extends ConsumerWidget {
  final int patientId;

  const PatientDetailPage({
    super.key,
    required this.patientId,
  });

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le patient'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce patient ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(patientRepositoryProvider).deletePatient(patientId);

      ref.invalidate(patientsProvider);
      ref.invalidate(patientDetailProvider(patientId));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient supprimé avec succès'),
        ),
      );

      context.pop();
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de la suppression : $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
      patientDetailProvider(patientId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossier patient'),
        actions: [
          // BOUTON MODIFIER
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier',
            onPressed: () {
              context.push('/patients/$patientId/edit');
            },
          ),

          // BOUTON SUPPRIMER
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
            onPressed: () {
              _confirmDelete(context, ref);
            },
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        error: (error, _) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(
              patientDetailProvider(patientId),
            );

            await ref.read(
              patientDetailProvider(patientId).future,
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: _DetailErrorState(
                  error: error,
                  onRetry: () {
                    ref.invalidate(
                      patientDetailProvider(patientId),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        data: (detail) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(
              patientDetailProvider(patientId),
            );

            await ref.read(
              patientDetailProvider(patientId).future,
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _DossierHeader(
                patientName: detail.patient.fullName,
              ),

              const SizedBox(height: 16),

              const _SectionTitle(
                'Informations générales',
              ),

              const SizedBox(height: 8),

              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      _InfoTile(
                        background: const Color(0xFFEFF6FF),
                        icon: Icons.calendar_today_rounded,
                        iconColor: const Color(0xFF2563EB),
                        label: 'Date de naissance',
                        value: formatDateDdMmAaaa(
                          detail.patient.dateOfBirth,
                        ),
                      ),

                      _InfoTile(
                        background: const Color(0xFFFEF2F2),
                        icon: Icons.water_drop_outlined,
                        iconColor: const Color(0xFFEF4444),
                        label: 'Groupe sanguin',
                        value: detail.patient.groupeSanguin.isEmpty
                            ? '—'
                            : detail.patient.groupeSanguin,
                      ),

                      _InfoTile(
                        background: const Color(0xFFF5F3FF),
                        icon: Icons.person_outline,
                        iconColor: const Color(0xFFA855F7),
                        label: 'Âge',
                        value: '${detail.patient.age} ans',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const _SectionTitle('Contact'),

              const SizedBox(height: 8),

              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      _InfoTile(
                        background: const Color(0xFFEFF6FF),
                        icon: Icons.phone_outlined,
                        iconColor: const Color(0xFF2563EB),
                        label: 'Téléphone',
                        value: detail.patient.hasPhone
                            ? detail.patient.telephone
                            : '—',
                      ),

                      _InfoTile(
                        background: const Color(0xFFECFDF5),
                        icon: Icons.place_outlined,
                        iconColor: const Color(0xFF16A34A),
                        label: 'Adresse',
                        value: detail.patient.adresse.trim().isEmpty
                            ? '—'
                            : detail.patient.adresse,
                      ),

                      _InfoTile(
                        background: const Color(0xFFFFF7ED),
                        icon: Icons.emergency_outlined,
                        iconColor: const Color(0xFFF97316),
                        label: "Contact d'urgence",
                        value: detail.patient.hasContactUrgence
                            ? detail.patient.contactUrgence
                            : '—',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const _SectionTitle(
                'Antécédents médicaux',
              ),

              const SizedBox(height: 8),

              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          detail.patient.hasAntecedents
                              ? detail.patient.antecedentsMedicaux
                              : 'Non renseigné',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF111827),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const _SectionTitle(
                'Historique des séances de dialyse',
              ),

              const SizedBox(height: 8),

              Card(
                margin: EdgeInsets.zero,
                child: detail.recentSessions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucune séance de dialyse enregistrée pour ce patient.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      )
                    : Column(
                        children: detail.recentSessions
                            .map(
                              (session) => _SessionTile(
                                session: session,
                              ),
                            )
                            .toList(),
                      ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _DossierHeader extends StatelessWidget {
  final String patientName;

  const _DossierHeader({
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFDBEAFE),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            patientName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Dossier patient',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final Color background;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoTile({
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
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

class _SessionTile extends StatelessWidget {
  final PatientSessionEntity session;

  const _SessionTile({
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: BorderDirectional(
          bottom: BorderSide(
            color: Color(0xFFF1F5F9),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: Color(0xFF2563EB),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      formatSessionDate(
                        session.sessionDate,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  'Durée: ${session.duration}h00',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Machine: ${session.machineId ?? 'Non assignée'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          StatusBadge(
            status: session.status,
          ),
        ],
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _DetailErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final message = error is ApiException
        ? (error as ApiException).message
        : error.toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          color: Color(0xFFEF4444),
          size: 48,
        ),

        const SizedBox(height: 12),

        const Text(
          'Impossible de charger le dossier du patient',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),

        const SizedBox(height: 16),

        CustomButton(
          text: 'Réessayer',
          icon: Icons.refresh_rounded,
          backgroundColor: const Color(0xFF2563EB),
          onPressed: onRetry,
        ),
      ],
    );
  }
}