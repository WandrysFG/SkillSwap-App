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
    required String skillOfrecidaId,
    required String skillSolicitadaId,
  }) async {
    final usuarioOrigenId = _requireUserId();

    if (usuarioOrigenId == usuarioDestinoId) {
      throw Exception('No puedes enviarte una solicitud a ti mismo.');
    }

    await _client.from('exchanges').insert({
      'usuario_origen_id': usuarioOrigenId,
      'usuario_destino_id': usuarioDestinoId,
      'skill_ofrecida_id': skillOfrecidaId,
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
          skill_ofrecida:skill_ofrecida_id(nombre),
          skill_solicitada:skill_solicitada_id(nombre),
          usuario_destino:usuario_destino_id(
            id,
            nombre,
            bio,
            avatar_url
          )
        ''')
        .eq('usuario_origen_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map(
          (row) => _mapRow(
            Map<String, dynamic>.from(row as Map),
            'usuario_destino',
          ),
        )
        .toList();
  }

  Future<List<ExchangeItem>> fetchReceived() async {
    final userId = _requireUserId();

    final data = await _client
        .from('exchanges')
        .select('''
          id,
          estado,
          skill_ofrecida:skill_ofrecida_id(nombre),
          skill_solicitada:skill_solicitada_id(nombre),
          usuario_origen:usuario_origen_id(
            id,
            nombre,
            bio,
            avatar_url
          )
        ''')
        .eq('usuario_destino_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map(
          (row) => _mapRow(
            Map<String, dynamic>.from(row as Map),
            'usuario_origen',
          ),
        )
        .toList();
  }

  Future<int> countPendingReceived() async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      return 0;
    }

    final data = await _client
        .from('exchanges')
        .select('id')
        .eq('usuario_destino_id', userId)
        .eq('estado', 'pendiente');

    return (data as List).length;
  }

  /// El usuario destinatario acepta una solicitud recibida.
  Future<void> acceptRequest(String exchangeId) async {
    final userId = _requireUserId();

    await _client
        .from('exchanges')
        .update({'estado': 'aceptada'})
        .eq('id', exchangeId)
        .eq('usuario_destino_id', userId)
        .eq('estado', 'pendiente');
  }

  /// El usuario destinatario rechaza una solicitud recibida.
  Future<void> rejectRequest(String exchangeId) async {
    final userId = _requireUserId();

    await _client
        .from('exchanges')
        .update({'estado': 'rechazada'})
        .eq('id', exchangeId)
        .eq('usuario_destino_id', userId)
        .eq('estado', 'pendiente');
  }

  /// El usuario que envió la solicitud puede cancelarla mientras esté pendiente.
  Future<void> cancelRequest(String exchangeId) async {
    final userId = _requireUserId();

    await _client
        .from('exchanges')
        .update({'estado': 'cancelada'})
        .eq('id', exchangeId)
        .eq('usuario_origen_id', userId)
        .eq('estado', 'pendiente');
  }

  ExchangeItem _mapRow(
    Map<String, dynamic> row,
    String otherUserKey,
  ) {
    final otherUser =
        row[otherUserKey] as Map<String, dynamic>? ?? <String, dynamic>{};

    final offeredSkill =
        row['skill_ofrecida'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final requestedSkill =
        row['skill_solicitada'] as Map<String, dynamic>? ??
            <String, dynamic>{};

    return ExchangeItem(
      id: row['id']?.toString() ?? '',
      otroUsuarioId: otherUser['id']?.toString() ?? '',
      otroUsuarioNombre:
          otherUser['nombre']?.toString().trim().isNotEmpty == true
              ? otherUser['nombre'].toString()
              : 'Usuario',
      otroUsuarioAvatarUrl: otherUser['avatar_url']?.toString(),
      otroUsuarioBio: otherUser['bio']?.toString(),
      habilidadOfrecidaNombre:
          offeredSkill['nombre']?.toString() ?? 'Sin especificar',
      habilidadSolicitadaNombre:
          requestedSkill['nombre']?.toString() ?? 'Sin especificar',
      estado: row['estado']?.toString() ?? 'pendiente',
    );
  }
}