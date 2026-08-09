import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  // Enviar un mensaje y actualizar la fecha de actividad del intercambio
  Future<void> sendMessage({
    required String exchangeId,
    required String senderId,
    required String content,
  }) async {
    // 1. Insertar el mensaje
    await _client.from('messages').insert({
      'exchange_id': exchangeId,
      'sender_id': senderId,
      'content': content,
    });

    // 2. Actualizar 'updated_at' del intercambio para que suba en la lista de chats
    await _client.from('exchanges').update({
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', exchangeId);
  }

  // Escuchar mensajes en tiempo real (ordenados del más reciente al más antiguo)
  Stream<List<Message>> getMessagesStream(String exchangeId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('exchange_id', exchangeId)
        .order('created_at', ascending: false) // <-- CAMBIO: De más reciente a más antiguo
        .map((maps) => maps.map((map) => Message.fromMap(map)).toList());
  }

  // Eliminar un mensaje
  Future<void> deleteMessage(String messageId) async {
    await _client.from('messages').delete().eq('id', messageId);
  }
}