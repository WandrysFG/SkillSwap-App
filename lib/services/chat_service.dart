import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  // Enviar un mensaje a la base de datos
  Future<void> sendMessage({
    required String exchangeId,
    required String senderId,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'exchange_id': exchangeId,
      'sender_id': senderId,
      'content': content,
    });
  }

  // Escuchar mensajes en tiempo real para un intercambio específico
  Stream<List<Message>> getMessagesStream(String exchangeId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('exchange_id', exchangeId)
        .order('created_at', ascending: true)
        .map((maps) => maps.map((map) => Message.fromMap(map)).toList());
  }
}