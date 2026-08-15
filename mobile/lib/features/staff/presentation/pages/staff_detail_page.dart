import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/staff_provider.dart';

enum StaffKind { doctor, nurse }

class StaffDetailPage extends ConsumerWidget {
  final int staffId;
  final StaffKind kind;

  const StaffDetailPage({
    super.key,
    required this.staffId,
    required this.kind,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = kind == StaffKind.doctor
        ? ref.watch(doctorDetailProvider(staffId))
        : ref.watch(nurseDetailProvider(staffId));

    return Scaffold(
      appBar: AppBar(
        title: Text(kind == StaffKind.doctor ? 'Profil médecin' : 'Profil infirmier'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e is ApiException ? e.message : e.toString()),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Réessayer',
                  backgroundColor: const Color(0xFF2563EB),
                  onPressed: () {
                    if (kind == StaffKind.doctor) {
                      ref.invalidate(doctorDetailProvider(staffId));
                    } else {
                      ref.invalidate(nurseDetailProvider(staffId));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        data: (person) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              person.fullName.isEmpty ? person.username : person.fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(person.role, style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            _tile('Statut', person.statusLabel),
            _tile('Email', person.email.isEmpty ? '—' : person.email),
            _tile('Téléphone', person.phone.isEmpty ? '—' : person.phone),
            _tile('Adresse', person.address.isEmpty ? '—' : person.address),
            if (person.specialite.isNotEmpty) _tile('Spécialité', person.specialite),
            if (person.memberSince.isNotEmpty) _tile('Membre depuis', person.memberSince),
            if (person.seniorityLabel.isNotEmpty) _tile('Ancienneté', person.seniorityLabel),
            if (person.bio.isNotEmpty) _tile('Bio', person.bio),
            if (person.formation.isNotEmpty) _tile('Formation', person.formation),
            if (person.experience.isNotEmpty) _tile('Expérience', person.experience),
            if (person.assignedDoctorsText.isNotEmpty)
              _tile('Médecins assignés', person.assignedDoctorsText),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, color: Color(0xFF111827))),
      ),
    );
  }
}
