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
}