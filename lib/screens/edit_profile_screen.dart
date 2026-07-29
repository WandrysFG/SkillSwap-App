import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../utils/app_theme.dart';
import '../widgets/gradient_button.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _profileService = ProfileService();

  late final TextEditingController _nombreController;
  late final TextEditingController _bioController;
  late final TextEditingController _avatarUrlController;

  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.user.nombre);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _avatarUrlController =
        TextEditingController(text: widget.user.avatarUrl ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser!.id;

      await _profileService.updateProfile(
        userId: userId,
        nombre: _nombreController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: _avatarUrlController.text.trim().isEmpty
            ? null
            : _avatarUrlController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'No se pudo guardar el perfil. Intenta de nuevo.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _avatarUrlController.text.trim().isEmpty
                            ? AppColors.primaryGradient
                            : null,
                        image: _avatarUrlController.text.trim().isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(
                                  _avatarUrlController.text.trim(),
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _avatarUrlController.text.trim().isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 52,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'URL del avatar (opcional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _avatarUrlController,
                    decoration: AppInputStyle.decoration(
                      hint: 'https://ejemplo.com/mi-foto.jpg',
                      icon: Icons.image_outlined,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Nombre',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _nombreController,
                    decoration: AppInputStyle.decoration(
                      hint: 'Tu nombre',
                      icon: Icons.person_outline,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'El nombre es obligatorio'
                            : null,
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Biografía',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 200,
                    decoration: AppInputStyle.decoration(
                      hint: 'Cuéntanos sobre ti y tus habilidades',
                      icon: Icons.info_outline,
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  GradientButton(
                    label: 'Guardar Cambios',
                    loading: _loading,
                    onPressed: _handleSave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}