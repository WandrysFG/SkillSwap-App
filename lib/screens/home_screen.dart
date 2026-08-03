import 'package:flutter/material.dart';

import '../models/search_user.dart';
import '../models/skill.dart';
import '../services/auth_service.dart';
import '../services/search_service.dart';
import '../services/skills_service.dart';
import 'my_skills_screen.dart';
import 'profile_screen.dart';
import 'public_profile_screen.dart';
import 'requests_screen.dart';
import '../services/exchange_service.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final SkillsService _skillsService = SkillsService();
  final SearchService _searchService = SearchService();
  final ExchangeService _exchangeService = ExchangeService();

  List<Skill> _skills = [];
  List<SearchUser> _searchResults = [];

  Skill? _selectedSkill;

  bool _isLoadingSkills = true;
  bool _isSearching = false;
  bool _hasSearched = false;
  int _pendingCount = 0;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSkills();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final count = await _exchangeService.countPendingReceived();
      if (!mounted) return;
      setState(() => _pendingCount = count);
    } catch (_) {
      // Si falla el conteo, simplemente no mostramos el badge; no es crítico.
    }
  }

  Future<void> _loadSkills() async {
    setState(() {
      _isLoadingSkills = true;
      _errorMessage = null;
    });

    try {
      final skills = await _skillsService.fetchCatalog();

      if (!mounted) return;

      setState(() {
        _skills = skills;
        _isLoadingSkills = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingSkills = false;
        _errorMessage =
            'No se pudieron cargar las habilidades. Intenta nuevamente.';
      });
    }
  }

  Future<void> _searchUsers() async {
    final selectedSkill = _selectedSkill;

    if (selectedSkill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una habilidad antes de buscar.'),
        ),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchResults = [];
      _errorMessage = null;
    });

    try {
      final results = await _searchService.searchUsersBySkill(
        selectedSkill.id,
      );

      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSearching = false;
        _errorMessage =
            'Ocurrió un error al realizar la búsqueda. Intenta nuevamente.';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar la sesión.'),
        ),
      );
    }
  }

  void _openPublicProfile(SearchUser user) {
  final skill = _selectedSkill;
  if (skill == null) return;

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PublicProfileScreen(
        user: user,
        requestedSkillId: skill.id,
        requestedSkillName: skill.nombre,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkillSwap'),
        centerTitle: true,
        actions: [
          Badge(
            isLabelVisible: _pendingCount > 0,
            label: Text('$_pendingCount'),
            child: IconButton(
              tooltip: 'Solicitudes',
              icon: const Icon(Icons.swap_horiz),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RequestsScreen()),
                );
                _loadPendingCount(); // refresca el número al volver
              },
            ),
          ),
          IconButton(
            tooltip: 'Mis habilidades',
            icon: const Icon(Icons.stars_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MySkillsScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSkills,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Bienvenido',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'Usuario de SkillSwap',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.search),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Buscar personas por habilidad',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecciona una habilidad para encontrar usuarios que puedan enseñarla.',
                      ),
                      const SizedBox(height: 20),
                      _buildSkillSelector(),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isLoadingSkills || _isSearching
                            ? null
                            : _searchUsers,
                        icon: _isSearching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.manage_search),
                        label: Text(
                          _isSearching
                              ? 'Buscando usuarios...'
                              : 'Buscar usuarios',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSearchContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillSelector() {
    if (_isLoadingSkills) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_skills.isEmpty) {
      return Column(
        children: [
          const Text(
            'No hay habilidades disponibles en el catálogo.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _loadSkills,
            icon: const Icon(Icons.refresh),
            label: const Text('Recargar'),
          ),
        ],
      );
    }

    return DropdownButtonFormField<Skill>(
      initialValue: _selectedSkill,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Habilidad',
        hintText: 'Selecciona una habilidad',
        prefixIcon: Icon(Icons.school_outlined),
        border: OutlineInputBorder(),
      ),
      items: _skills.map((skill) {
        return DropdownMenuItem<Skill>(
          value: skill,
          child: Text(
            '${skill.nombre} · ${skill.categoria}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (skill) {
        setState(() {
          _selectedSkill = skill;
          _hasSearched = false;
          _searchResults = [];
          _errorMessage = null;
        });
      },
    );
  }

  Widget _buildSearchContent() {
    if (_errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                size: 45,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _hasSearched ? _searchUsers : _loadSkills,
                icon: const Icon(Icons.refresh),
                label: const Text('Intentar nuevamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 35),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Buscando usuarios...'),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 50,
              ),
              SizedBox(height: 12),
              Text(
                'Los usuarios encontrados aparecerán aquí.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.search_off,
                size: 52,
              ),
              const SizedBox(height: 12),
              Text(
                _selectedSkill == null
                    ? 'No se encontraron resultados.'
                    : 'No se encontraron usuarios que ofrezcan '
                        '${_selectedSkill!.nombre}.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona otra habilidad e intenta nuevamente.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultados encontrados: ${_searchResults.length}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ..._searchResults.map(_buildUserCard),
      ],
    );
  }

  Widget _buildUserCard(SearchUser user) {
    final hasAvatar =
        user.avatarUrl != null && user.avatarUrl!.trim().isNotEmpty;

    final biography = user.bio?.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openPublicProfile(user),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    hasAvatar ? NetworkImage(user.avatarUrl!) : null,
                child: !hasAvatar
                    ? const Icon(
                        Icons.person,
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nombre.trim().isNotEmpty
                          ? user.nombre
                          : 'Usuario',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      biography == null || biography.isEmpty
                          ? 'Sin biografía disponible.'
                          : biography,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    if (user.habilidadesOfrecidas.isEmpty)
                      const Text('Sin habilidades ofrecidas.')
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: user.habilidadesOfrecidas
                            .take(3)
                            .map(
                              (skill) => Chip(
                                visualDensity: VisualDensity.compact,
                                avatar: const Icon(
                                  Icons.star_outline,
                                  size: 16,
                                ),
                                label: Text(skill),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}