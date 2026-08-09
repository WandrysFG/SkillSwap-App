import 'dart:async';
import 'package:flutter/material.dart';

import '../models/search_user.dart';
import '../models/skill.dart';
import '../services/auth_service.dart';
import '../services/search_service.dart';
import '../services/skills_service.dart';
import '../services/exchange_service.dart';
import '../utils/app_theme.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/skill_chip.dart';
import '../widgets/empty_state_view.dart';
import 'my_skills_screen.dart';
import 'public_profile_screen.dart';
import 'requests_screen.dart';

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

  List<Skill> _catalog = [];

  List<SearchUser> _browseResults = [];
  String? _selectedCategory;
  Skill? _selectedSkill;

  List<SearchUser> _searchResults = [];
  String _searchText = '';
  bool _isSearchingText = false;
  Timer? _debounce;

  bool _isLoadingCatalog = true;
  bool _isBrowsing = false;
  String? _errorMessage;
  int _pendingCount = 0;
  bool? _hasOwnSkills;

  bool get _isTextSearchActive => _searchText.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _loadPendingCount();
    _loadOwnSkillsStatus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPendingCount() async {
    try {
      final count = await _exchangeService.countPendingReceived();
      if (!mounted) return;
      setState(() => _pendingCount = count);
    } catch (_) {}
  }

  Future<void> _loadOwnSkillsStatus() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;
      final skills = await _skillsService.fetchUserSkills(userId);
      if (!mounted) return;
      setState(() {
        _hasOwnSkills = skills.any((s) => s.tipo == 'ofrece');
      });
    } catch (_) {}
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _isLoadingCatalog = true;
      _errorMessage = null;
    });
    try {
      final skills = await _skillsService.fetchCatalog();
      if (!mounted) return;
      setState(() {
        _catalog = skills;
        _isLoadingCatalog = false;
      });
      if (_categories.isNotEmpty) {
        _selectCategory(_categories.first);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCatalog = false;
        _errorMessage =
            'No se pudieron cargar las habilidades. Intenta nuevamente.';
      });
    }
  }

  List<String> get _categories {
    final set = _catalog.map((s) => s.categoria).toSet().toList();
    set.sort();
    return set;
  }

  List<Skill> get _skillsInSelectedCategory {
    if (_selectedCategory == null) return [];
    return _catalog.where((s) => s.categoria == _selectedCategory).toList();
  }

  Future<void> _selectCategory(String categoria) async {
    setState(() {
      _selectedCategory = categoria;
      _selectedSkill = null;
      _isBrowsing = true;
      _errorMessage = null;
    });

    try {
      final results = await _searchService.searchUsersByCategory(categoria);
      if (!mounted) return;
      setState(() {
        _browseResults = results;
        _isBrowsing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBrowsing = false;
        _errorMessage =
            'No se pudo buscar en esta categoría. Intenta nuevamente.';
      });
    }
  }

  Future<void> _selectSkill(Skill skill) async {
    final alreadySelected = _selectedSkill?.id == skill.id;

    if (alreadySelected) {
      if (_selectedCategory != null) {
        await _selectCategory(_selectedCategory!);
      }
      return;
    }

    setState(() {
      _selectedSkill = skill;
      _isBrowsing = true;
      _errorMessage = null;
    });

    try {
      final results = await _searchService.searchUsersBySkill(skill.id);
      if (!mounted) return;
      setState(() {
        _browseResults = results;
        _isBrowsing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isBrowsing = false;
        _errorMessage = 'No se pudo buscar esa habilidad. Intenta nuevamente.';
      });
    }
  }

  void _onSearchTextChanged(String value) {
    setState(() => _searchText = value);
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _isSearchingText = false;
        _searchResults = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performTextSearch(value);
    });
  }

  Future<void> _performTextSearch(String query) async {
    setState(() {
      _isSearchingText = true;
      _errorMessage = null;
    });

    try {
      final results = await _searchService.searchUsersByText(query);
      if (!mounted) return;
      if (_searchText.trim() != query.trim()) return;
      setState(() {
        _searchResults = results;
        _isSearchingText = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearchingText = false;
        _errorMessage = 'No se pudo realizar la búsqueda. Intenta nuevamente.';
      });
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    setState(() {
      _searchText = '';
      _searchResults = [];
      _isSearchingText = false;
    });
  }

  void _openPublicProfile(SearchUser user) {
    final skillId = _selectedSkill?.id;
    final skillName = _selectedSkill?.nombre;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          user: user,
          requestedSkillId: _isTextSearchActive ? null : skillId,
          requestedSkillName: _isTextSearchActive ? null : skillName,
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cerrar la sesión.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SkillSwap',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Badge(
            isLabelVisible: _pendingCount > 0,
            label: Text('$_pendingCount'),
            backgroundColor: AppColors.danger,
            child: IconButton(
              tooltip: 'Solicitudes',
              icon: const Icon(Icons.notifications_none_rounded),
              color: Colors.white,
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RequestsScreen()),
                );
                _loadPendingCount();
              },
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: _signOut,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.blue,
            onRefresh: () async {
              await _loadCatalog();
              await _loadOwnSkillsStatus();
              await _loadPendingCount();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                _buildQuickAccessRow(),
                const SizedBox(height: 20),
                if (_hasOwnSkills == false) ...[
                  _buildAddSkillsBanner(),
                  const SizedBox(height: 20),
                ],
                _buildSearchBar(),
                const SizedBox(height: 14),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessRow() {
    return Row(
      children: [
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.swap_horiz,
            label: 'Solicitudes',
            badgeCount: _pendingCount,
            onTap: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const RequestsScreen()));
              _loadPendingCount();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAccessCard(
            icon: Icons.stars_outlined,
            label: 'Mis Habilidades',
            onTap: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MySkillsScreen()));
              _loadOwnSkillsStatus();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddSkillsBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agrega tus habilidades',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.deepBlue,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Necesitas al menos una habilidad ofrecida para poder enviar solicitudes.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MySkillsScreen()));
              _loadOwnSkillsStatus();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.deepBlue),
            child: const Text(
              'Agregar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: _onSearchTextChanged,
        decoration: InputDecoration(
          hintText: 'Buscar una habilidad o persona...',
          prefixIcon: const Icon(Icons.search, color: AppColors.blue),
          suffixIcon: _isTextSearchActive
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.black38,
                    size: 20,
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingCatalog) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    if (_isTextSearchActive) {
      return _buildTextSearchResults();
    }

    if (_catalog.isEmpty) {
      return EmptyStateView(
        icon: Icons.error_outline,
        title: 'No hay habilidades disponibles',
        subtitle: 'Intenta recargar en unos momentos.',
        actionLabel: 'Recargar',
        onAction: _loadCatalog,
        outlinedAction: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final categoria = _categories[index];
              return SkillChip(
                label: categoria,
                selected: _selectedCategory == categoria,
                onTap: () => _selectCategory(categoria),
              );
            },
          ),
        ),
        if (_selectedCategory != null &&
            _skillsInSelectedCategory.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _skillsInSelectedCategory.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final skill = _skillsInSelectedCategory[index];
                final selected = _selectedSkill?.id == skill.id;
                return GestureDetector(
                  onTap: () => _selectSkill(skill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.deepBlue.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? AppColors.deepBlue : Colors.black12,
                      ),
                    ),
                    child: Text(
                      skill.nombre,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.deepBlue : Colors.black54,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 18),
        const Text(
          'Habilidades sugeridas',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildBrowseResultsList(),
      ],
    );
  }

  Widget _buildTextSearchResults() {
    if (_errorMessage != null) {
      return EmptyStateView(
        icon: Icons.error_outline,
        title: 'Algo salió mal',
        subtitle: _errorMessage!,
        actionLabel: 'Intentar nuevamente',
        onAction: () => _performTextSearch(_searchText),
        outlinedAction: true,
      );
    }

    if (_isSearchingText) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    if (_searchResults.isEmpty) {
      return EmptyStateView(
        icon: Icons.search_off,
        title: 'No encontramos resultados',
        subtitle: 'Prueba con otro nombre de persona o habilidad.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resultados para "${_searchText.trim()}"',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ..._searchResults.map(_buildUserCard),
      ],
    );
  }

  Widget _buildBrowseResultsList() {
    if (_errorMessage != null) {
      return EmptyStateView(
        icon: Icons.error_outline,
        title: 'Algo salió mal',
        subtitle: _errorMessage!,
        actionLabel: 'Intentar nuevamente',
        onAction: () => _selectedCategory != null
            ? _selectCategory(_selectedCategory!)
            : _loadCatalog(),
        outlinedAction: true,
      );
    }

    if (_isBrowsing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    if (_browseResults.isEmpty) {
      return const EmptyStateView(
        icon: Icons.search_off,
        title: 'No encontramos resultados',
        subtitle: 'Prueba con otra categoría o habilidad.',
      );
    }

    return Column(children: _browseResults.map(_buildUserCard).toList());
  }

  Widget _buildUserCard(SearchUser user) {
    final biography = user.bio?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPublicProfile(user),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AvatarCircle(
                nombre: user.nombre,
                avatarUrl: user.avatarUrl,
                size: 46,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nombre.trim().isNotEmpty ? user.nombre : 'Usuario',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.habilidadesOfrecidas.isEmpty
                          ? (biography == null || biography.isEmpty
                                ? 'Sin biografía disponible.'
                                : biography)
                          : 'Ofrece: ${user.habilidadesOfrecidas.take(3).join(", ")}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? badgeCount;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Badge(
                isLabelVisible: (badgeCount ?? 0) > 0,
                label: Text('$badgeCount'),
                backgroundColor: AppColors.danger,
                child: Icon(icon, color: AppColors.blue, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
