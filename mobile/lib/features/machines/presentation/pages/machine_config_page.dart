import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../devices/domain/entities/device_entity.dart';
import '../../../devices/presentation/providers/devices_provider.dart';
import '../../domain/entities/machine_detail_entity.dart';
import '../providers/machines_provider.dart';
import '../widgets/machine_status_badge.dart';

/// Mobile counterpart of Django `configurer_machine.html`.
///
/// Lets an Admin/Infirmier/Docteur change the machine status (radio group
/// matching `Machine.enumerated_status`) and assign/unassign a Raspberry Pi
/// device (dropdown of unassigned devices), persisted via
/// PUT /api/machines/<id>/.
class MachineConfigPage extends ConsumerStatefulWidget {
  final int machineId;

  const MachineConfigPage({super.key, required this.machineId});

  @override
  ConsumerState<MachineConfigPage> createState() => _MachineConfigPageState();
}

class _MachineConfigPageState extends ConsumerState<MachineConfigPage> {
  static const _statuses = [
    'Prete',
    'Reserve',
    'Maintenance',
    'Hors Service',
  ];

  String? _status;
  String? _selectedRaspi;
  bool _saving = false;

  static String _statusHint(String status) {
    switch (status) {
      case 'Prete':
        return 'Machine prête';
      case 'Maintenance':
        return 'Maintenance en cours';
      case 'Hors Service':
        return 'Erreur détectée';
      case 'Reserve':
        return 'Machine réservée';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(machineDetailProvider(widget.machineId));
    final devicesAsync = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuration Machine')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is ApiException ? error.message : error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Réessayer',
                  backgroundColor: const Color(0xFF2563EB),
                  onPressed: () =>
                      ref.invalidate(machineDetailProvider(widget.machineId)),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          _status ??= detail.machine.status;

          final available = devicesAsync is AsyncData<DevicesResult>
              ? devicesAsync.value.devices
              : const <DeviceEntity>[];
          // Devices already assigned to another machine are disabled
          // (mirrors the web template).
          final machineId = detail.machine.id;
          final currentRaspi = detail.machine.raspi;

          // The PUT /api/machines/<id>/ contract expects the RaspiDevice
          // UUID (`device.id`), but the machine payload only exposes the
          // `raspi_id` label — match it against the devices list.
          if (_selectedRaspi == null && currentRaspi != null) {
            for (final device in available) {
              if (device.raspiId == currentRaspi.raspiId) {
                _selectedRaspi = device.id;
                break;
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MachineHeader(machineId: detail.machine.id),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'État actuel de la machine',
                icon: Icons.monitor_heart_outlined,
                child: Row(
                  children: [
                    Expanded(
                      child: _label('Statut'),
                    ),
                    MachineStatusBadge(status: detail.machine.status),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Changer l\'état',
                icon: Icons.tune_rounded,
                child: Column(
                  children: [
                    for (final status in _statuses) ...[
                      _StatusOption(
                        value: status,
                        hint: _statusHint(status),
                        selected: _status == status,
                        onChanged: (v) => setState(() => _status = v),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Assigner un appareil connecté',
                icon: Icons.videocam_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Les appareils déjà utilisés sont désactivés.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedRaspi),
                      initialValue: _selectedRaspi,
                      decoration: const InputDecoration(
                        labelText: 'Appareil (Raspberry Pi)',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('— Aucun appareil —'),
                        ),
                        for (final device in available)
                          DropdownMenuItem(
                            value: device.id,
                            enabled:
                                device.machine == null ||
                                device.machine!.id == machineId,
                            child: Text(
                              device.machine != null &&
                                  device.machine!.id != machineId
                                  ? '${device.raspiId} (déjà assigné)'
                                  : device.raspiId,
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _selectedRaspi = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _saving ? 'Enregistrement...' : 'Valider configuration',
                icon: Icons.save_outlined,
                backgroundColor: const Color(0xFF2563EB),
                onPressed: _saving ? null : () => _save(detail),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
    );
  }

  Future<void> _save(MachineDetailEntity detail) async {
    setState(() => _saving = true);
    try {
      await ref.read(machineRepositoryProvider).configureMachine(
        widget.machineId,
        status: _status ?? detail.machine.status,
        raspiId: _selectedRaspi,
      );
      ref.invalidate(machineDetailProvider(widget.machineId));
      ref.invalidate(devicesProvider);
      ref.invalidate(machinesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration de la machine mise à jour avec succès'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MachineHeader extends StatelessWidget {
  final int machineId;

  const _MachineHeader({required this.machineId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2563EB),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF2563EB),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configuration – Machine $machineId',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Réglages techniques',
                  style: TextStyle(fontSize: 13, color: Color(0xFFDBEAFE)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String value;
  final String hint;
  final bool selected;
  final ValueChanged<String?> onChanged;

  const _StatusOption({
    required this.value,
    required this.hint,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDBEAFE) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 22,
              color: selected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    hint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
