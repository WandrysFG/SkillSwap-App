class ExchangeItem {
  final String id;
  final String otroUsuarioId;
  final String otroUsuarioNombre;
  final String? otroUsuarioAvatarUrl;
  final String? otroUsuarioBio;
  final String habilidadOfrecidaNombre;
  final String habilidadSolicitadaNombre;
  final String estado;

  ExchangeItem({
    required this.id,
    required this.otroUsuarioId,
    required this.otroUsuarioNombre,
    this.otroUsuarioAvatarUrl,
    this.otroUsuarioBio,
    required this.habilidadOfrecidaNombre,
    required this.habilidadSolicitadaNombre,
    required this.estado,
  });
}