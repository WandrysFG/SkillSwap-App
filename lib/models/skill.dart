class Skill {
  final String id;
  final String nombre;
  final String categoria;

  Skill({
    required this.id,
    required this.nombre,
    required this.categoria,
  });

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'],
      nombre: map['nombre'],
      categoria: map['categoria'],
    );
  }
}