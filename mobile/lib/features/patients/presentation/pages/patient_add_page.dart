import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/patients_provider.dart';

/// Mobile counterpart of the "Ajouter Patient" modal in `patient.html`.
class PatientAddPage extends ConsumerStatefulWidget {
  const PatientAddPage({super.key});

  @override
  ConsumerState<PatientAddPage> createState() => _PatientAddPageState();
}

class _PatientAddPageState extends ConsumerState<PatientAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _contactUrgenceController = TextEditingController();
  final _antecedentsController = TextEditingController();
  String _groupeSanguin = 'A+';
  bool _saving = false;

  static const _groupes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _contactUrgenceController.dispose();
    _antecedentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter Patient')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_firstNameController, 'Prénom', requiredField: true),
            _field(_lastNameController, 'Nom', requiredField: true),
            _dateField(),
            _field(
              _telephoneController,
              'Téléphone',
              requiredField: true,
              hint: '+216 XX XXX XXX',
            ),
            DropdownButtonFormField<String>(
              initialValue: _groupeSanguin,
              decoration: const InputDecoration(labelText: 'Groupe sanguin'),
              items: [
                for (final g in _groupes)
                  DropdownMenuItem(value: g, child: Text(g)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _groupeSanguin = v);
              },
            ),
            const SizedBox(height: 12),
            _field(_adresseController, 'Adresse', requiredField: true),
            _field(
              _contactUrgenceController,
              "Contact d'urgence",
              requiredField: true,
            ),
            TextFormField(
              controller: _antecedentsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Antécédents médicaux',
                hintText: 'Maladies, allergies, traitements...',
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: _saving ? 'Enregistrement...' : 'Enregistrer',
              icon: Icons.save_outlined,
              backgroundColor: const Color(0xFF2563EB),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool requiredField = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: requiredField
            ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null
            : null,
      ),
    );
  }

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _dateOfBirthController,
        readOnly: true,
        decoration: const InputDecoration(labelText: 'Date de naissance'),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(1980, 1, 1),
            firstDate: DateTime(1920),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            _dateOfBirthController.text =
                '${picked.year.toString().padLeft(4, '0')}-'
                '${picked.month.toString().padLeft(2, '0')}-'
                '${picked.day.toString().padLeft(2, '0')}';
          }
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(patientRepositoryProvider).createPatient({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'date_of_birth': _dateOfBirthController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'groupe_sanguin': _groupeSanguin,
        'type_de_dialyse': 'Hémodialyse',
        'adresse': _adresseController.text.trim(),
        'contact_urgence': _contactUrgenceController.text.trim(),
        'antecedents_medicaux': _antecedentsController.text.trim(),
      });
      ref.invalidate(patientsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient ajouté avec succès')),
      );
      context.go(AppRouter.patients);
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
