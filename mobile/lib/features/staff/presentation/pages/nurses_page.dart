import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/staff_provider.dart';

class NursesPage extends ConsumerStatefulWidget {
  const NursesPage({super.key});

  @override
  ConsumerState<NursesPage> createState() => _NursesPageState();
}

class _NursesPageState extends ConsumerState<NursesPage> {
  final _search = TextEditingController();
  String _status = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _apply() {
    ref.read(nursesProvider.notifier).setFilters(
      search: _search.text,
      status: _status,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(nursesProvider);
    return AppShell(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNurse(context),
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
                    hintText: 'Rechercher un infirmier...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Statut'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Tous')),
                    DropdownMenuItem(value: 'active', child: Text('Actif')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactif')),
                  ],
                  onChanged: (v) {
                    setState(() => _status = v ?? '');
                    _apply();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(nursesProvider.notifier).refresh(),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        e is ApiException ? e.message : e.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                data: (result) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    const Text(
                      'Infirmiers',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total ${result.kpis.total} • Actifs ${result.kpis.activeCount}',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    if (result.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Aucun infirmier trouvé.'),
                      )
                    else
                      for (final n in result.items)
                        Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () => context.push(
                              AppRouter.nurseDetailRoute(n.id),
                            ),
                            title: Text(n.username),
                            subtitle: Text(
                              [
                                n.statusLabel,
                                n.email,
                                n.phone,
                                if (n.assignedDoctorsText.isNotEmpty)
                                  'Médecins: ${n.assignedDoctorsText}',
                              ].where((e) => e.trim().isNotEmpty).join(' • '),
                            ),
                            trailing: const Icon(Icons.chevron_right),
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

  Future<void> _showAddNurse(BuildContext context) async {
    final nom = TextEditingController();
    final email = TextEditingController();
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
                  'Ajouter un infirmier',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                TextFormField(
                  controller: nom,
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
                          .createNurse(
                            nom: nom.text.trim(),
                            email: email.text.trim(),
                            telephone: phone.text.trim(),
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
      ref.invalidate(nursesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created.isEmpty
                ? 'Infirmier ajouté'
                : 'Infirmier ajouté. Mot de passe : $created',
          ),
        ),
      );
    }
  }
}
