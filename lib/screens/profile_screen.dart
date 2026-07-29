import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../utils/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _profileService = ProfileService();

  late Future<AppUser> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<AppUser> _loadProfile() {
    final userId = _authService.currentUser!.id;
    return _profileService.fetchProfile(userId);
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: FutureBuilder<AppUser>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error al cargar el perfil: ${snapshot.error}'));
            }

            final user = snapshot.data!;
            final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: hasAvatar ? null : AppColors.primaryGradient,
                        image: hasAvatar
                            ? DecorationImage(image: NetworkImage(user.avatarUrl!), fit: BoxFit.cover)
                            : null,
                        boxShadow: [
                          BoxShadow(color: AppColors.blue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: hasAvatar ? null : const Icon(Icons.person, color: Colors.white, size: 52),
                    ),
                    const SizedBox(height: 20),
                    Text(user.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(user.email, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Biografía',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.deepBlue)),
                          const SizedBox(height: 8),
                          Text(
                            (user.bio == null || user.bio!.trim().isEmpty)
                                ? 'Aún no has agregado una biografía.'
                                : user.bio!,
                            style: TextStyle(
                              fontSize: 14,
                              color: (user.bio == null || user.bio!.trim().isEmpty) ? Colors.black38 : Colors.black87,
                              fontStyle:
                                  (user.bio == null || user.bio!.trim().isEmpty) ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    GradientButton(
                      label: 'Editar Perfil',
                      loading: false,
                      onPressed: () async {
                        final updated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
                        );
                        if (updated == true) _refresh();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}