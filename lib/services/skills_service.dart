import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/skill.dart';
import '../models/user_skill_item.dart';

class SkillsService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Trae el catálogo completo de habilidades (para el selector).
  Future<List<Skill>> fetchCatalog() async {
    final data = await _client.from('skills').select().order('categoria');
    return (data as List).map((e) => Skill.fromMap(e)).toList();
  }

  /// Trae las habilidades que el usuario ya agregó (ofrece + quiere),
  /// combinadas con el nombre/categoría de cada habilidad.
  Future<List<UserSkillItem>> fetchUserSkills(String userId) async {
    final data = await _client
        .from('user_skills')
        .select('id, tipo, skill_id, skills(nombre, categoria)')
        .eq('usuario_id', userId);
    return (data as List).map((e) => UserSkillItem.fromMap(e)).toList();
  }

  /// Agrega una habilidad a la lista del usuario ('ofrece' o 'quiere').
  Future<void> addUserSkill({
    required String userId,
    required String skillId,
    required String tipo,
  }) async {
    await _client.from('user_skills').insert({
      'usuario_id': userId,
      'skill_id': skillId,
      'tipo': tipo,
    });
  }

  /// Quita una habilidad ya agregada, por el id de la fila en user_skills.
  Future<void> removeUserSkill(String userSkillId) async {
    await _client.from('user_skills').delete().eq('id', userSkillId);
  }
}