import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/patients_provider.dart';

class PatientEditPage extends ConsumerStatefulWidget {
  final String patientId;

  const PatientEditPage({super.key, required this.patientId});

  @override
  ConsumerState<PatientEditPage> createState() => _PatientEditPageState();
}

class _PatientEditPageState extends ConsumerState<PatientEditPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _ageController = TextEditingController();
  final _groupeSanguinController = TextEditingController();
  final _typeDeDialyseController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _contactUrgenceController = TextEditingController();
  final _antecedentsController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    _ageController.dispose();
    _groupeSanguinController.dispose();
    _typeDeDialyseController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _contactUrgenceController.dispose();
    _antecedentsController.dispose();
    super.dispose();
  }

  void _fillForm(detail) {
    if (_initialized) return;

    final patient = detail.patient;

    _firstNameController.text = patient.firstName;
    _lastNameController.text = patient.lastName;
    _dateOfBirthController.text = patient.dateOfBirth ?? '';
    _ageController.text = patient.age.toString();
    _groupeSanguinController.text = patient.groupeSanguin;
    _typeDeDialyseController.text = patient.typeDeDialyse;
    _adresseController.text = patient.adresse;
    _telephoneController.text = patient.telephone;
    _contactUrgenceController.text = patient.contactUrgence;
    _antecedentsController.text = patient.antecedentsMedicaux;

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(patientDetailProvider(widget.patientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le patient')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Impossible de charger le patient',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(patientDetailProvider(widget.patientId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          _fillForm(detail);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle('Informations générales'),
                const SizedBox(height: 10),

                _buildTextField(
                  controller: _firstNameController,
                  label: 'Prénom',
                  icon: Icons.person_outline,
                  requiredField: true,
                ),

                const SizedBox(height: 14),

                _buildTextField(
                  controller: _lastNameController,
                  label: 'Nom',
                  icon: Icons.person_outline,
                  requiredField: true,
                ),

                const SizedBox(height: 14),

                _buildTextField(
                  controller: _dateOfBirthController,
                  label: 'Date de naissance',
                  icon: Icons.calendar_today_outlined,
                  hint: 'YYYY-MM-DD',
                  requiredField: true,
                ),

                const SizedBox(height: 14),

                _buildTextField(
                  controller: _ageController,
                  label: 'Âge',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 14),

                _buildTextField(
                  controller: _groupeSanguinController,
                  label: 'Groupe sanguin',
                  icon: Icons.water_drop_outlined,
                ),

                const SizedBox(height: 14),

                _buildTextField(
                  controller: _typeDeDialyseController,
                  label: 'Type de dialyse',
                  icon: Icons.medical_services_outlined,
                ),

                const SizedBox(height: 24),

                _sectionTitle('Contact'),
                const SizedBox(height: 10),

                _buildTextField(
                  controller: _telephoneController,
                  label: 'Téléphone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 14),

                _buildTextField(
                  controller: _adresseController,
                  label: 'Adresse',
                  icon: Icons.place_outlined,
                  maxLines: 2,
                ),

                const SizedBox(height: 14),

                _buildTextField(
                  controller: _contactUrgenceController,
                  label: "Contact d'urgence",
                  icon: Icons.emergency_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 24),

                _sectionTitle('Antécédents médicaux'),
                const SizedBox(height: 10),

                _buildTextField(
                  controller: _antecedentsController,
                  label: 'Antécédents médicaux',
                  icon: Icons.description_outlined,
                  maxLines: 5,
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving
                          ? 'Enregistrement...'
                          : 'Enregistrer les modifications',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: requiredField
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label est obligatoire';
              }
              return null;
            }
          : null,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(patientRepositoryProvider);

      final data = <String, dynamic>{
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'date_of_birth': _dateOfBirthController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'groupe_sanguin': _groupeSanguinController.text.trim(),
        'type_de_dialyse': _typeDeDialyseController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'contact_urgence': _contactUrgenceController.text.trim(),
        'antecedents_medicaux': _antecedentsController.text.trim(),
      };

      await repository.updatePatient(widget.patientId, data);

      if (!mounted) return;

      // Refresh le détail du patient
      ref.invalidate(patientDetailProvider(widget.patientId));

      // Refresh la liste des patients
      ref.invalidate(patientsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient modifié avec succès')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la modification : $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}
