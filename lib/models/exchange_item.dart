class ExchangeItem {
  final String id;
  final String otroUsuarioId;
  final String otroUsuarioNombre;
  final String? otroUsuarioAvatarUrl;
  final String? otroUsuarioBio;
  final String? habilidadOfrecidaNombre;
  final String habilidadSolicitadaNombre;
  final String estado;
  final bool confirmadoPorMi;
  final bool confirmadoPorOtro;
  final bool noShowReportado;

  ExchangeItem({
    required this.id,
    required this.otroUsuarioId,
    required this.otroUsuarioNombre,
    this.otroUsuarioAvatarUrl,
    this.otroUsuarioBio,
    this.habilidadOfrecidaNombre,
    required this.habilidadSolicitadaNombre,
    required this.estado,
    this.confirmadoPorMi = false,
    this.confirmadoPorOtro = false,
    this.noShowReportado = false,
  });
}