import 'package:flutter/material.dart';

import '../models/search_user.dart';
import '../models/user_skill_item.dart';
import '../services/auth_service.dart';
import '../services/exchange_service.dart';
import '../services/skills_service.dart';
import 'my_skills_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final SearchUser user;
  final String? requestedSkillId;
  final String? requestedSkillName;

  const PublicProfileScreen({
    super.key,
    required this.user,
    this.requestedSkillId,
    this.requestedSkillName,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _authService = AuthService();
  final _skillsService = SkillsService();
  final _exchangeService = ExchangeService();

  List<UserSkillItem> _myOfferedSkills = [];
  bool _loadingMySkills = true;
  bool _sending = false;
  bool _requestSent = false;

 @override
  void initState() {
    super.initState();
    if (widget.requestedSkillId != null) {
      _loadMyOfferedSkills();
    } else {
      _loadingMySkills = false;
    }
  }

  Future<void> _loadMyOfferedSkills() async {
    try {
      final myId = _authService.currentUser!.id;
      final mySkills = await _skillsService.fetchUserSkills(myId);

      if (!mounted) return;

      setState(() {
        _myOfferedSkills = mySkills.where((s) => s.tipo == 'ofrece').toList();
        _loadingMySkills = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMySkills = false);
    }
  }

  Future<void> _handleSendRequest() async {
    final chosen = await showModalBottomSheet<UserSkillItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Qué habilidad ofreces a cambio de "${widget.requestedSkillName!}"?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _myOfferedSkills.map((skill) {
                    return ActionChip(
                      avatar: const Icon(Icons.star_outline, size: 18),
                      label: Text(skill.nombre),
                      onPressed: () => Navigator.of(context).pop(skill),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (chosen == null) return;

    setState(() => _sending = true);

    try {
      await _exchangeService.sendRequest(
        usuarioDestinoId: widget.user.id,
        skillOfrecidaId: chosen.skillId,
        skillSolicitadaId: widget.requestedSkillId!,
      );

      if (!mounted) return;

      setState(() {
        _sending = false;
        _requestSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solicitud enviada: ofreces "${chosen.nombre}" a cambio de '
            '"${widget.requestedSkillName!}".',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _sending = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar la solicitud. Intenta de nuevo.'),
        ),
      );
    }
  }

  bool get _hasAvatar {
    return widget.user.avatarUrl != null &&
        widget.user.avatarUrl!.trim().isNotEmpty;
  }

  String get _biografia {
    final bio = widget.user.bio?.trim();

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
              skills: widget.user.habilidadesOfrecidas,
            ),
            const SizedBox(height: 28),
            _buildSkillsSection(
              context: context,
              title: 'Habilidades que desea aprender',
              emptyMessage:
                  'Este usuario todavía no ha agregado habilidades deseadas.',
              icon: Icons.school_outlined,
              skills: widget.user.habilidadesDeseadas,
            ),
            if (widget.requestedSkillId != null) ...[
              const SizedBox(height: 28),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Estás por solicitar: ${widget.requestedSkillName}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
               const SizedBox(height: 20),
              _buildSendRequestButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSendRequestButton() {
    if (_requestSent) {
      return FilledButton.tonalIcon(
        onPressed: null,
        icon: Icon(Icons.check_circle_outline),
        label: Text('Solicitud enviada'),
      );
    }

    if (_loadingMySkills) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_myOfferedSkills.isEmpty) {
      return Column(
        children: [
          const Text(
            'Agrega al menos una habilidad que ofrezcas para poder enviar solicitudes.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MySkillsScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar habilidades'),
          ),
        ],
      );
    }

    return FilledButton.icon(
      onPressed: _sending ? null : _handleSendRequest,
      icon: _sending
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.send_outlined),
      label: Text(_sending ? 'Enviando...' : 'Enviar solicitud'),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundImage: _hasAvatar ? NetworkImage(widget.user.avatarUrl!) : null,
          child: !_hasAvatar
              ? const Icon(
                  Icons.person,
                  size: 55,
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          widget.user.nombre.trim().isNotEmpty ? widget.user.nombre : 'Usuario',
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