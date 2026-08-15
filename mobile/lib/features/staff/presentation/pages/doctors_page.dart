import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/staff_entity.dart';
import '../providers/staff_provider.dart';

class DoctorsPage extends ConsumerStatefulWidget {
  const DoctorsPage({super.key});

  @override
  ConsumerState<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends ConsumerState<DoctorsPage> {
  final _search = TextEditingController();
  String _role = '';
  String _status = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _apply() {
    ref.read(doctorsProvider.notifier).setFilters(
      search: _search.text,
      role: _role,
      status: _status,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(doctorsProvider);
    return AppShell(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDoctor(context),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (_) => _apply(),
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un docteur...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _role,
                        decoration: const InputDecoration(labelText: 'Rôle'),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tous')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          DropdownMenuItem(
                            value: 'doctor',
                            child: Text('Docteur'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _role = v ?? '');
                          _apply();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Statut'),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tous')),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Actif'),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Inactif'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _status = v ?? '');
                          _apply();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(doctorsProvider.notifier).refresh(),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _Error(error: e, onRetry: () => ref.invalidate(doctorsProvider)),
                data: (result) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    const Text(
                      'Docteurs',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _KpiRow(
                      total: result.kpis.total,
                      active: result.kpis.activeCount,
                      extraLabel: 'Admins',
                      extraValue: result.kpis.adminCount,
                    ),
                    const SizedBox(height: 12),
                    if (result.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Aucun docteur trouvé.'),
                      )
                    else
                      for (final d in result.items)
                        _StaffCard(
                          person: d,
                          onTap: () => context.push(
                            AppRouter.doctorDetailRoute(d.id),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDoctor(BuildContext context) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final speciality = TextEditingController();
    final phone = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final created = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ajouter un docteur',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nom *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                ),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                ),
                TextFormField(
                  controller: speciality,
                  decoration: const InputDecoration(labelText: 'Spécialité'),
                ),
                TextFormField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Enregistrer',
                  backgroundColor: const Color(0xFF2563EB),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      final result = await ref
                          .read(staffRepositoryProvider)
                          .createDoctor(
                            fullName: name.text.trim(),
                            email: email.text.trim(),
                            speciality: speciality.text.trim(),
                            phone: phone.text.trim(),
                          );
                      if (ctx.mounted) {
                        Navigator.pop(ctx, result.generatedPassword ?? '');
                      }
                    } catch (e) {
                      if (!ctx.mounted) return;
                      final msg = e is ApiException ? e.message : e.toString();
                      ScaffoldMessenger.of(
                        ctx,
                      ).showSnackBar(SnackBar(content: Text(msg)));
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
    if (created != null && context.mounted) {
      ref.invalidate(doctorsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created.isEmpty
                ? 'Docteur ajouté avec succès'
                : 'Docteur ajouté. Mot de passe : $created',
          ),
        ),
      );
    }
  }
}

class _KpiRow extends StatelessWidget {
  final int total;
  final int active;
  final String extraLabel;
  final int extraValue;

  const _KpiRow({
    required this.total,
    required this.active,
    required this.extraLabel,
    required this.extraValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _kpi('Total', '$total'),
        _kpi('Actifs', '$active'),
        _kpi(extraLabel, '$extraValue'),
      ],
    );
  }

  Widget _kpi(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffEntity person;
  final VoidCallback onTap;

  const _StaffCard({required this.person, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        title: Text(person.fullName.isEmpty ? person.username : person.fullName),
        subtitle: Text(
          [
            person.role,
            person.specialite,
            person.statusLabel,
            if (person.email.isNotEmpty) person.email,
          ].where((e) => e.trim().isNotEmpty).join(' • '),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _Error({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final message = error is ApiException ? (error as ApiException).message : error.toString();
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              CustomButton(
                text: 'Réessayer',
                backgroundColor: const Color(0xFF2563EB),
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
