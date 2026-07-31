import 'package:flutter/material.dart';

import '../models/search_user.dart';

class PublicProfileScreen extends StatelessWidget {
  final SearchUser user;

  const PublicProfileScreen({
    super.key,
    required this.user,
  });

  bool get _hasAvatar {
    return user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty;
  }

  String get _biografia {
    final bio = user.bio?.trim();

    if (bio == null || bio.isEmpty) {
      return 'Este usuario todavía no ha agregado una biografía.';
    }

    return bio;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil público'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 28),
            _buildSkillsSection(
              context: context,
              title: 'Habilidades que ofrece',
              emptyMessage:
                  'Este usuario todavía no ha agregado habilidades ofrecidas.',
              icon: Icons.star_outline,
              skills: user.habilidadesOfrecidas,
            ),
            const SizedBox(height: 28),
            _buildSkillsSection(
              context: context,
              title: 'Habilidades que desea aprender',
              emptyMessage:
                  'Este usuario todavía no ha agregado habilidades deseadas.',
              icon: Icons.school_outlined,
              skills: user.habilidadesDeseadas,
            ),
            const SizedBox(height: 36),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'La función de enviar solicitud estará disponible en la Fase 4.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.send_outlined),
              label: const Text('Enviar solicitud'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundImage: _hasAvatar ? NetworkImage(user.avatarUrl!) : null,
          child: !_hasAvatar
              ? const Icon(
                  Icons.person,
                  size: 55,
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          user.nombre.trim().isNotEmpty ? user.nombre : 'Usuario',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          _biografia,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildSkillsSection({
    required BuildContext context,
    required String title,
    required String emptyMessage,
    required IconData icon,
    required List<String> skills,
  }) {
    final validSkills = skills
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (validSkills.isEmpty)
          Text(emptyMessage)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: validSkills
                .map(
                  (skill) => Chip(
                    avatar: Icon(
                      icon,
                      size: 18,
                    ),
                    label: Text(skill),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}