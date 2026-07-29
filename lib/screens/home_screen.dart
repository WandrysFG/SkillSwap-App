import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import 'my_skills_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillSwap'),
        actions: [
          IconButton(
            tooltip: 'Mis Habilidades',
            icon: const Icon(Icons.stars_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MySkillsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Mi Perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Bienvenido, sesión activa: ${user?.email ?? "sin email"}'),
      ),
    );
  }
}