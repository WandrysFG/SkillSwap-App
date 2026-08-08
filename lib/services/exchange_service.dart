import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exchange_item.dart';

class ExchangeService {
  final SupabaseClient _client = Supabase.instance.client;

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('No hay un usuario autenticado.');
    }
    return userId;
  }

  Future<void> sendRequest({
    required String usuarioDestinoId,
    required String skillSolicitadaId,
  }) async {
    final usuarioOrigenId = _requireUserId();

    if (usuarioOrigenId == usuarioDestinoId) {
      throw Exception('No puedes enviarte una solicitud a ti mismo.');
    }

    await _client.from('exchanges').insert({
      'usuario_origen_id': usuarioOrigenId,
      'usuario_destino_id': usuarioDestinoId,
      'skill_ofrecida_id': null,
      'skill_solicitada_id': skillSolicitadaId,
      'estado': 'pendiente',
    });
  }

  Future<List<ExchangeItem>> fetchSent() async {
    final userId = _requireUserId();

    final data = await _client
        .from('exchanges')
        .select('''
          id,
          estado,
          confirmado_origen,
          confirmado_destino,
          no_show_reportado_por,
          skill_ofrecida:skill_ofrecida_id(nombre),
          skill_solicitada:skill_solicitada_id(nombre),
          usuario_destino:usuario_destino_id(
            id, nombre, bio, avatar_url
          )
        ''')
        .eq('usuario_origen_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => _mapRow(Map<String, dynamic>.from(row as Map), 'usuario_destino', isOrigen: true))
        .toList();
  }

  Future<List<ExchangeItem>> fetchReceived() async {
    final userId = _requireUserId();

    final data = await _client
        .from('exchanges')
        .select('''
          id,
          estado,
          confirmado_origen,
          confirmado_destino,
          no_show_reportado_por,
          skill_ofrecida:skill_ofrecida_id(nombre),
          skill_solicitada:skill_solicitada_id(nombre),
          usuario_origen:usuario_origen_id(
            id, nombre, bio, avatar_url
          )
        ''')
        .eq('usuario_destino_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => _mapRow(Map<String, dynamic>.from(row as Map), 'usuario_origen', isOrigen: false))
        .toList();
  }

  Future<int> countPendingReceived() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final data = await _client
        .from('exchanges')
        .select('id')
        .eq('usuario_destino_id', userId)
        .eq('estado', 'pendiente');

    return (data as List).length;
  }

  Future<void> acceptRequest({
    required String exchangeId,
    required String skillOfrecidaId,
  }) async {
    final userId = _requireUserId();

    await _client
        .from('exchanges')
        .update({
          'estado': 'aceptada',
          'skill_ofrecida_id': skillOfrecidaId,
        })
        .eq('id', exchangeId)
        .eq('usuario_destino_id', userId)
        .eq('estado', 'pendiente');
  }

  Future<void> rejectRequest(String exchangeId) async {
    final userId = _requireUserId();

    await _client
        .from('exchanges')
        .update({'estado': 'rechazada'})
        .eq('id', exchangeId)
        .eq('usuario_destino_id', userId)
        .eq('estado', 'pendiente');
  }

  Future<void> cancelRequest(String exchangeId) async {
    final userId = _requireUserId();

    await _client
        .from('exchanges')
        .update({'estado': 'cancelada'})
        .eq('id', exchangeId)
        .eq('usuario_origen_id', userId)
        .eq('estado', 'pendiente');
  }

  /// Doble check (Issue #6): cualquiera de los dos puede marcar su lado
  /// como completado. Cuando AMBOS lo hicieron, el estado pasa a 'completada'.
  Future<void> markMyPartAsCompleted(String exchangeId) async {
    final userId = _requireUserId();

    final row = await _client
        .from('exchanges')
        .select('usuario_origen_id, usuario_destino_id, confirmado_origen, confirmado_destino, estado')
        .eq('id', exchangeId)
        .single();

    final estado = row['estado']?.toString();
    if (estado != 'aceptada' && estado != 'esperando_confirmacion') {
      throw Exception('Este intercambio no está en un estado válido para completarse.');
    }

    final isOrigen = row['usuario_origen_id']?.toString() == userId;
    final isDestino = row['usuario_destino_id']?.toString() == userId;
    if (!isOrigen && !isDestino) {
      throw Exception('No participas en este intercambio.');
    }

    final yaConfirmadoOrigen = row['confirmado_origen'] == true || isOrigen;
    final yaConfirmadoDestino = row['confirmado_destino'] == true || isDestino;
    final ambosConfirmaron = yaConfirmadoOrigen && yaConfirmadoDestino;

    await _client.from('exchanges').update({
      if (isOrigen) 'confirmado_origen': true,
      if (isDestino) 'confirmado_destino': true,
      'estado': ambosConfirmaron ? 'completada' : 'esperando_confirmacion',
      if (ambosConfirmaron) 'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', exchangeId);
  }

  /// Botón "No se presentó" (Issue #7): cancela el intercambio y
  /// deja registro de quién reportó la ausencia.
  Future<void> reportNoShow(String exchangeId) async {
    final userId = _requireUserId();

    final row = await _client
        .from('exchanges')
        .select('usuario_origen_id, usuario_destino_id, estado')
        .eq('id', exchangeId)
        .single();

    final estado = row['estado']?.toString();
    if (estado != 'aceptada' && estado != 'esperando_confirmacion') {
      throw Exception('Este intercambio no está en un estado válido para reportar ausencia.');
    }

    final participa = row['usuario_origen_id']?.toString() == userId ||
        row['usuario_destino_id']?.toString() == userId;
    if (!participa) {
      throw Exception('No participas en este intercambio.');
    }

    await _client.from('exchanges').update({
      'estado': 'cancelada',
      'no_show_reportado_por': userId,
      'no_show_at': DateTime.now().toIso8601String(),
    }).eq('id', exchangeId);
  }

  Future<int> countAcceptedExchanges(String userId) async {
    final response = await _client
        .from('exchanges')
        .select('id')
        .or('usuario_origen_id.eq.$userId,usuario_destino_id.eq.$userId')
        .inFilter('estado', ['aceptada', 'esperando_confirmacion', 'completada']);

    return (response as List).length;
  }

  ExchangeItem _mapRow(Map<String, dynamic> row, String otherUserKey, {required bool isOrigen}) {
    final otherUser = row[otherUserKey] as Map<String, dynamic>? ?? <String, dynamic>{};
    final offeredSkill = row['skill_ofrecida'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final requestedSkill = row['skill_solicitada'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final confirmadoOrigen = row['confirmado_origen'] == true;
    final confirmadoDestino = row['confirmado_destino'] == true;

    return ExchangeItem(
      id: row['id']?.toString() ?? '',
      otroUsuarioId: otherUser['id']?.toString() ?? '',
      otroUsuarioNombre: otherUser['nombre']?.toString().trim().isNotEmpty == true
          ? otherUser['nombre'].toString()
          : 'Usuario',
      otroUsuarioAvatarUrl: otherUser['avatar_url']?.toString(),
      otroUsuarioBio: otherUser['bio']?.toString(),
      habilidadOfrecidaNombre: offeredSkill['nombre']?.toString(),
      habilidadSolicitadaNombre: requestedSkill['nombre']?.toString() ?? 'Sin especificar',
      estado: row['estado']?.toString() ?? 'pendiente',
      confirmadoPorMi: isOrigen ? confirmadoOrigen : confirmadoDestino,
      confirmadoPorOtro: isOrigen ? confirmadoDestino : confirmadoOrigen,
      noShowReportado: row['no_show_reportado_por'] != null,
    );
  }
}