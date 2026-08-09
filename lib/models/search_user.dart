class SearchUser {
  final String id;
  final String nombre;
  final String? bio;
  final String? avatarUrl;
  final List<String> habilidadesOfrecidas;
  final List<String> habilidadesDeseadas;

  SearchUser({
    required this.id,
    required this.nombre,
    this.bio,
    this.avatarUrl,
    required this.habilidadesOfrecidas,
    required this.habilidadesDeseadas,
  });
}