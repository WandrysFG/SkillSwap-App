import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/search_user.dart';

class SearchService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<SearchUser> fetchUserProfile(String userId) async {
    final data = await _client
        .from('users')
        .select('''
          id, nombre, bio, avatar_url,
          user_skills(tipo, skills(nombre))
        ''')
        .eq('id', userId)
        .single();

    final userSkillsData = data['user_skills'] as List? ?? [];
    final offered = <String>[];
    final desired = <String>[];

    for (final item in userSkillsData) {
      final skillData = item['skills'] as Map<String, dynamic>?;
      final name = skillData?['nombre']?.toString() ?? '';
      final tipo = item['tipo']?.toString() ?? '';
      if (name.isEmpty) continue;
      if (tipo == 'ofrece') {
        offered.add(name);
      } else if (tipo == 'quiere') {
        desired.add(name);
      }
    }

    return SearchUser(
      id: data['id']?.toString() ?? '',
      nombre: data['nombre']?.toString() ?? 'Usuario',
      bio: data['bio']?.toString(),
      avatarUrl: data['avatar_url']?.toString(),
      habilidadesOfrecidas: offered,
      habilidadesDeseadas: desired,
    );
  }

  Future<List<SearchUser>> searchUsersBySkill(String skillId) async {
    final currentUserId = _client.auth.currentUser?.id;

    final data = await _client
        .from('user_skills')
        .select('''
          usuario_id,
          users(
            id,
            nombre,
            bio,
            avatar_url,
            user_skills(
              tipo,
              skills(nombre)
            )
          )
        ''')
        .eq('skill_id', skillId)
        .eq('tipo', 'ofrece');

    final rows = data as List;
    final users = <SearchUser>[];

    for (final row in rows) {
      final userData = row['users'] as Map<String, dynamic>?;

      if (userData == null) {
        continue;
      }

      final userId = userData['id']?.toString() ?? '';

      if (userId.isEmpty || userId == currentUserId) {
        continue;
      }

      final userSkillsData = userData['user_skills'] as List? ?? [];

      final offeredSkills = <String>[];
      final desiredSkills = <String>[];

      for (final item in userSkillsData) {
        final skillData = item['skills'] as Map<String, dynamic>?;
        final skillName = skillData?['nombre']?.toString() ?? '';
        final tipo = item['tipo']?.toString() ?? '';

        if (skillName.isEmpty) {
          continue;
        }

        if (tipo == 'ofrece') {
          offeredSkills.add(skillName);
        } else if (tipo == 'quiere') {
          desiredSkills.add(skillName);
        }
      }

      users.add(
        SearchUser(
          id: userId,
          nombre: userData['nombre']?.toString() ?? 'Usuario',
          bio: userData['bio']?.toString(),
          avatarUrl: userData['avatar_url']?.toString(),
          habilidadesOfrecidas: offeredSkills,
          habilidadesDeseadas: desiredSkills,
        ),
      );
    }

    return users;
  }

  Future<List<SearchUser>> searchUsersByCategory(String categoria) async {
    final currentUserId = _client.auth.currentUser?.id;

    final data = await _client
        .from('user_skills')
        .select('''
          usuario_id,
          skill:skill_id!inner(categoria),
          users(
            id,
            nombre,
            bio,
            avatar_url,
            user_skills(
              tipo,
              skills(nombre)
            )
          )
        ''')
        .eq('tipo', 'ofrece')
        .eq('skill.categoria', categoria);

    final rows = data as List;
    final users = <SearchUser>[];
    final seenIds = <String>{};

    for (final row in rows) {
      final userData = row['users'] as Map<String, dynamic>?;
      if (userData == null) continue;

      final userId = userData['id']?.toString() ?? '';
      if (userId.isEmpty || userId == currentUserId) continue;
      if (seenIds.contains(userId)) continue;
      seenIds.add(userId);

      final userSkillsData = userData['user_skills'] as List? ?? [];
      final offeredSkills = <String>[];
      final desiredSkills = <String>[];

      for (final item in userSkillsData) {
        final skillData = item['skills'] as Map<String, dynamic>?;
        final skillName = skillData?['nombre']?.toString() ?? '';
        final tipo = item['tipo']?.toString() ?? '';
        if (skillName.isEmpty) continue;
        if (tipo == 'ofrece') {
          offeredSkills.add(skillName);
        } else if (tipo == 'quiere') {
          desiredSkills.add(skillName);
        }
      }

      users.add(
        SearchUser(
          id: userId,
          nombre: userData['nombre']?.toString() ?? 'Usuario',
          bio: userData['bio']?.toString(),
          avatarUrl: userData['avatar_url']?.toString(),
          habilidadesOfrecidas: offeredSkills,
          habilidadesDeseadas: desiredSkills,
        ),
      );
    }

    return users;
  }

  Future<List<SearchUser>> searchUsersByText(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final currentUserId = _client.auth.currentUser?.id;

    final bySkillData = await _client
        .from('user_skills')
        .select('''
          usuario_id,
          skill:skill_id!inner(nombre),
          users(
            id, nombre, bio, avatar_url,
            user_skills(tipo, skills(nombre))
          )
        ''')
        .eq('tipo', 'ofrece')
        .ilike('skill.nombre', '%$trimmed%');

    final byNameData = await _client
        .from('users')
        .select('''
          id, nombre, bio, avatar_url,
          user_skills(tipo, skills(nombre))
        ''')
        .ilike('nombre', '%$trimmed%');

    final users = <String, SearchUser>{};

    for (final row in (bySkillData as List)) {
      final userData = row['users'] as Map<String, dynamic>?;
      if (userData == null) continue;
      final mapped = _mapUserMap(userData);
      if (mapped == null || mapped.id == currentUserId) continue;
      users[mapped.id] = mapped;
    }

    for (final row in (byNameData as List)) {
      final mapped = _mapUserMap(Map<String, dynamic>.from(row as Map));
      if (mapped == null || mapped.id == currentUserId) continue;
      users[mapped.id] = mapped;
    }

    return users.values.toList();
  }

  SearchUser? _mapUserMap(Map<String, dynamic> userData) {
    final userId = userData['id']?.toString() ?? '';
    if (userId.isEmpty) return null;

    final userSkillsData = userData['user_skills'] as List? ?? [];
    final offeredSkills = <String>[];
    final desiredSkills = <String>[];

    for (final item in userSkillsData) {
      final skillData = item['skills'] as Map<String, dynamic>?;
      final skillName = skillData?['nombre']?.toString() ?? '';
      final tipo = item['tipo']?.toString() ?? '';
      if (skillName.isEmpty) continue;
      if (tipo == 'ofrece') {
        offeredSkills.add(skillName);
      } else if (tipo == 'quiere') {
        desiredSkills.add(skillName);
      }
    }

    return SearchUser(
      id: userId,
      nombre: userData['nombre']?.toString() ?? 'Usuario',
      bio: userData['bio']?.toString(),
      avatarUrl: userData['avatar_url']?.toString(),
      habilidadesOfrecidas: offeredSkills,
      habilidadesDeseadas: desiredSkills,
    );
  }
}