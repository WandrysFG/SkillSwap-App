import 'package:flutter/material.dart';
import '../models/skill.dart';
import '../models/user_skill_item.dart';
import '../services/auth_service.dart';
import '../services/skills_service.dart';
import '../utils/app_theme.dart';
import '../widgets/skill_selector_sheet.dart';

class MySkillsScreen extends StatefulWidget {
  const MySkillsScreen({super.key});

  @override
  State<MySkillsScreen> createState() => _MySkillsScreenState();
}

class _MySkillsScreenState extends State<MySkillsScreen> {
  final _authService = AuthService();
  final _skillsService = SkillsService();

  List<Skill> _catalog = [];
  List<UserSkillItem> _userSkills = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final userId = _authService.currentUser!.id;
      final results = await Future.wait([
        _skillsService.fetchCatalog(),
        _skillsService.fetchUserSkills(userId),
      ]);
      setState(() {
        _catalog = results[0] as List<Skill>;
        _userSkills = results[1] as List<UserSkillItem>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudieron cargar tus habilidades.';
        _loading = false;
      });
    }
  }

  List<UserSkillItem> get _ofrece =>
      _userSkills.where((s) => s.tipo == 'ofrece').toList();

  List<UserSkillItem> get _quiere =>
      _userSkills.where((s) => s.tipo == 'quiere').toList();

  Future<void> _handleAdd(String tipo) async {
    final excludeIds = _userSkills
        .where((s) => s.tipo == tipo)
        .map((s) => s.skillId)
        .toSet();

    final chosen = await showSkillSelectorSheet(
      context: context,
      catalog: _catalog,
      excludeIds: excludeIds,
      title: tipo == 'ofrece' ? 'Elige qué ofreces' : 'Elige qué quieres aprender',
    );

    if (chosen == null) return;

    try {
      final userId = _authService.currentUser!.id;
      await _skillsService.addUserSkill(
        userId: userId,
        skillId: chosen.id,
        tipo: tipo,
      );
      await _loadAll();
    } catch (e) {
      print('Error al agregar habilidad: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo agregar la habilidad.')),
        );
      }
    }
  }

  Future<void> _handleRemove(UserSkillItem item) async {
    try {
      await _skillsService.removeUserSkill(item.userSkillId);
      setState(() {
        _userSkills.removeWhere((s) => s.userSkillId == item.userSkillId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo quitar la habilidad.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Habilidades')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : RefreshIndicator(
                    onRefresh: _loadAll,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      children: [
                        _buildSection(
                          title: 'Ofrezco',
                          icon: Icons.volunteer_activism,
                          items: _ofrece,
                          tipo: 'ofrece',
                        ),
                        const SizedBox(height: 28),
                        _buildSection(
                          title: 'Quiero aprender',
                          icon: Icons.school_outlined,
                          items: _quiere,
                          tipo: 'quiere',
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<UserSkillItem> items,
    required String tipo,
  }) {
    return Container(
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
          Row(
            children: [
              Icon(icon, color: AppColors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.deepBlue),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _handleAdd(tipo),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
                style: TextButton.styleFrom(foregroundColor: AppColors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Todavía no has agregado nada aquí.',
                style: TextStyle(color: Colors.black38, fontStyle: FontStyle.italic),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return Chip(
                  label: Text(item.nombre),
                  backgroundColor: AppColors.bgLight,
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _handleRemove(item),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}