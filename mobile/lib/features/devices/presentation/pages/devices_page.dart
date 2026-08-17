import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/device_entity.dart';
import '../providers/devices_provider.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(devicesProvider);
    return AppShell(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDevice(context, ref),
        backgroundColor: const Color(0xFF15803D),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(devicesProvider.notifier).refresh(),
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
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Gestion des appareils',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _stat('Total', result.stats.total),
                  _stat('Assignés', result.stats.assigned),
                  _stat('Libres', result.stats.free),
                  _stat('Inactifs', result.stats.inactive),
                ],
              ),
              const SizedBox(height: 16),
              if (result.devices.isEmpty)
                const Text('Aucun appareil enregistré.')
              else
                for (final d in result.devices)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(d.raspiId),
                      subtitle: Text(
                        [
                          if (d.description.isNotEmpty) d.description,
                          d.machine == null
                              ? 'Non assigné'
                              : 'Machine ${d.machine!.machineId}',
                          d.isActive ? 'Actif' : 'Inactif',
                        ].join(' • '),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.link),
                        tooltip: 'Assigner une machine',
                        onPressed: () => _assign(context, ref, result, d),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, int value) {
    return Container(
      width: 150,
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
          Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _addDevice(BuildContext context, WidgetRef ref) async {
    final idCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showModalBottomSheet<bool>(
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
                  'Ajouter un Raspi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                TextFormField(
                  controller: idCtrl,
                  decoration: const InputDecoration(labelText: 'raspi_id *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                ),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Enregistrer',
                  backgroundColor: const Color(0xFF15803D),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await ref.read(devicesRepositoryProvider).addDevice(
                        raspiId: idCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (e) {
                      if (!ctx.mounted) return;
                      final msg = e is ApiException ? e.message : e.toString();
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
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
    if (ok == true && context.mounted) {
      ref.invalidate(devicesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appareil ajouté avec succès')),
      );
    }
  }

  Future<void> _assign(
    BuildContext context,
    WidgetRef ref,
    DevicesResult result,
    DeviceEntity device,
  ) async {
    int? selected = device.machine?.id;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Assigner ${device.raspiId}'),
                  DropdownButtonFormField<int?>(
                    initialValue: selected,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Désassigner'),
                      ),
                      for (final m in result.machines)
                        DropdownMenuItem(
                          value: m.id,
                          child: Text(m.machineId),
                        ),
                    ],
                    onChanged: (v) => setState(() => selected = v),
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Valider',
                    backgroundColor: const Color(0xFF2563EB),
                    onPressed: () async {
                      try {
                        await ref.read(devicesRepositoryProvider).assignMachine(
                          deviceId: device.id,
                          machineId: selected,
                        );
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (!ctx.mounted) return;
                        final msg = e is ApiException ? e.message : e.toString();
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(msg)),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (ok == true && context.mounted) {
      ref.invalidate(devicesProvider);
    }
  }
}
