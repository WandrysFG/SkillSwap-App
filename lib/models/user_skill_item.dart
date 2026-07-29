class UserSkillItem {
  final String userSkillId; // id de la fila en user_skills
  final String skillId;
  final String nombre;
  final String categoria;
  final String tipo; // 'ofrece' o 'quiere'

  UserSkillItem({
    required this.userSkillId,
    required this.skillId,
    required this.nombre,
    required this.categoria,
    required this.tipo,
  });

  factory UserSkillItem.fromMap(Map<String, dynamic> map) {
    final skillData = map['skills'] as Map<String, dynamic>?;
    return UserSkillItem(
      userSkillId: map['id'],
      skillId: map['skill_id'],
      tipo: map['tipo'],
      nombre: skillData?['nombre'] ?? '',
      categoria: skillData?['categoria'] ?? '',
    );
  }
}