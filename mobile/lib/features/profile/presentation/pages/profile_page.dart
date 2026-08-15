import 'dart:convert' show base64Encode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../domain/entities/profile_entity.dart';
import '../providers/profile_provider.dart';

/// Flutter counterpart of Django `accounts/templates/profile.html`.
///
/// Loads the profile from GET /api/profile/ (same payload as
/// `accounts.views.profile`) and offers the same edit form: email,
/// phone, address, bio, formation, experience and password change
/// (mandatory when `first_login` is true — mirrors the Django web form).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error is ApiException ? error.message : error.toString()),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Réessayer',
                  backgroundColor: const Color(0xFF2563EB),
                  onPressed: () => ref.invalidate(profileProvider),
                ),
              ],
            ),
          ),
        ),
        data: (profile) => _ProfileForm(profile: profile),
      ),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  final ProfileEntity profile;

  const _ProfileForm({required this.profile});

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _bioController;
  late final TextEditingController _formationController;
  late final TextEditingController _experienceController;
  late final TextEditingController _oldPasswordController;
  late final TextEditingController _newPasswordController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _selectedPhotoDataUrl;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _addressController = TextEditingController(text: widget.profile.address);
    _bioController = TextEditingController(text: widget.profile.bio);
    _formationController = TextEditingController(text: widget.profile.formation);
    _experienceController = TextEditingController(text: widget.profile.experience);
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _formationController.dispose();
    _experienceController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _IdentityCard(
            profile: profile,
            photoUrl: _fullPhotoUrl(_selectedPhotoDataUrl ?? profile.photoUrl),
            onPickPhoto: _pickPhoto,
          ),
          const SizedBox(height: 12),
          if (profile.seniorityLabel.isNotEmpty)
            _InfoCard(
              icon: Icons.work_outline,
              label: 'Ancienneté',
              value: profile.seniorityLabel,
            ),
          if (profile.memberSince != null && profile.memberSince!.isNotEmpty)
            _InfoCard(
              icon: Icons.event_outlined,
              label: 'Membre depuis',
              value: profile.memberSince!,
            ),
          const SizedBox(height: 12),
          if (profile.firstLogin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: const Text(
                'Vous devez changer votre mot de passe pour continuer.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (profile.firstLogin) const SizedBox(height: 12),
          const _SectionTitle('Modifier le profil'),
          const SizedBox(height: 12),
          _field(_emailController, 'Email'),
          const SizedBox(height: 12),
          _field(_phoneController, 'Téléphone'),
          const SizedBox(height: 12),
          _field(_addressController, 'Adresse'),
          const SizedBox(height: 12),
          _multiline(_bioController, 'Bio'),
          const SizedBox(height: 12),
          _multiline(_formationController, 'Formation'),
          const SizedBox(height: 12),
          _field(_experienceController, 'Expérience'),
          const SizedBox(height: 24),
          const _SectionTitle('Changer mot de passe'),
          const SizedBox(height: 4),
          Text(
            widget.profile.firstLogin
                ? 'Mot de passe obligatoire'
                : 'Laissez vide si vous ne voulez pas changer le mot de passe.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          _field(
            _oldPasswordController,
            'Ancien mot de passe',
            obscure: true,
            requiredField: profile.firstLogin,
          ),
          const SizedBox(height: 12),
          _field(
            _newPasswordController,
            'Nouveau mot de passe',
            obscure: true,
            requiredField: profile.firstLogin,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: _saving ? 'Enregistrement...' : 'Enregistrer',
            icon: Icons.save_outlined,
            backgroundColor: const Color(0xFF2563EB),
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(labelText: label, isDense: true),
      validator: requiredField
          ? (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null
          : null,
    );
  }

  Widget _multiline(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64 = base64Encode(bytes);
      final mime = picked.mimeType ?? 'image/jpeg';
      if (!mounted) return;
      setState(() => _selectedPhotoDataUrl = 'data:$mime;base64,$base64');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image : $e')),
      );
    }
  }

  /// The API returns a relative `/media/...` URL; local data-URLs (picked
  /// image preview) pass through unchanged.
  String _fullPhotoUrl(String url) {
    if (url.startsWith('data:') || url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '${ApiEndpoints.baseUrl}$url';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'adress': _addressController.text.trim(),
        'bio': _bioController.text.trim(),
        'formation': _formationController.text.trim(),
        'experience': _experienceController.text.trim(),
      };
      if (_oldPasswordController.text.isNotEmpty ||
          _newPasswordController.text.isNotEmpty) {
        data['old_password'] = _oldPasswordController.text;
        data['password'] = _newPasswordController.text;
      }
      if (_selectedPhotoDataUrl != null) {
        data['cropped_image'] = _selectedPhotoDataUrl;
      }

      final updated = await ref.read(profileRepositoryProvider).updateProfile(data);
      ref.invalidate(profileProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès')),
      );
      if (updated.firstLogin != true && widget.profile.firstLogin) {
        // Password updated — clear the stored first_login flag so the
        // router redirect does not force the profile screen on login.
        await ref.read(authStateProvider.notifier).completeFirstLogin();
      }
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final ProfileEntity profile;
  final String photoUrl;
  final VoidCallback onPickPhoto;

  const _IdentityCard({
    required this.profile,
    required this.photoUrl,
    required this.onPickPhoto,
  });

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
          Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person_outline,
                          size: 40,
                          color: Color(0xFF6B7280),
                        ),
                      )
                    : const Icon(
                        Icons.person_outline,
                        size: 40,
                        color: Color(0xFF6B7280),
                      ),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: onPickPhoto,
                icon: const Icon(Icons.photo_camera_outlined, size: 16),
                label: const Text('Changer la photo'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.username,
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
                    profile.role,
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
