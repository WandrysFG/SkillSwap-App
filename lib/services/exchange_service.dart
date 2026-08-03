import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exchange_item.dart';

class ExchangeService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> sendRequest({
    required String usuarioDestinoId,
    required String skillOfrecidaId,
    required String skillSolicitadaId,
  }) async {
    final usuarioOrigenId = _client.auth.currentUser?.id;

    if (usuarioOrigenId == null) {
      throw Exception('No hay un usuario autenticado.');
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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay un usuario autenticado.');

    final data = await _client
        .from('exchanges')
        .select('''
          id,
          estado,
          skill_ofrecida:skill_ofrecida_id(nombre),
          skill_solicitada:skill_solicitada_id(nombre),
          usuario_destino:usuario_destino_id(id, nombre, bio, avatar_url)
        ''')
        .eq('usuario_origen_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((row) => _mapRow(row, 'usuario_destino')).toList();
  }

  Future<List<ExchangeItem>> fetchReceived() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay un usuario autenticado.');

    final data = await _client
        .from('exchanges')
        .select('''
          id,
          estado,
          skill_ofrecida:skill_ofrecida_id(nombre),
          skill_solicitada:skill_solicitada_id(nombre),
          usuario_origen:usuario_origen_id(id, nombre, bio, avatar_url)
        ''')
        .eq('usuario_destino_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((row) => _mapRow(row, 'usuario_origen')).toList();
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

  ExchangeItem _mapRow(Map<String, dynamic> row, String otherUserKey) {
    final otro = row[otherUserKey] as Map<String, dynamic>? ?? {};
    return ExchangeItem(
      id: row['id'].toString(),
      otroUsuarioId: otro['id']?.toString() ?? '',
      otroUsuarioNombre: otro['nombre']?.toString() ?? 'Usuario',
      otroUsuarioAvatarUrl: otro['avatar_url']?.toString(),
      otroUsuarioBio: otro['bio']?.toString(),
      habilidadOfrecidaNombre:
          (row['skill_ofrecida'] as Map<String, dynamic>?)?['nombre']?.toString() ?? '',
      habilidadSolicitadaNombre:
          (row['skill_solicitada'] as Map<String, dynamic>?)?['nombre']?.toString() ?? '',
      estado: row['estado']?.toString() ?? 'pendiente',
    );
  }
}