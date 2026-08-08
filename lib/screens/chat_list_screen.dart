import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart'; // Conectaremos esta pantalla en el siguiente paso

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _client = Supabase.instance.client;
  late final String _myUserId;

  @override
  void initState() {
    super.initState();
    _myUserId = _client.auth.currentUser!.id;
  }

  // Obtenemos los chats abiertos (intercambios aceptados)
  Future<List<dynamic>> _fetchOpenChats() async {
    final response = await _client
        .from('exchanges')
        .select('''
          id,
          estado,
          usuario_origen_id,
          usuario_destino_id,
          origen:users!exchanges_usuario_origen_id_fkey(id, nombre, avatar_url),
          destino:users!exchanges_usuario_destino_id_fkey(id, nombre, avatar_url)
        ''')
        .eq('estado', 'aceptada')
        .or('usuario_origen_id.eq.$_myUserId,usuario_destino_id.eq.$_myUserId');
        
    return response as List<dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchOpenChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar chats: ${snapshot.error}'));
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                'Aún no tienes clases coordinadas.\n¡Acepta una solicitud para empezar a chatear!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              
              // Determinar quién es el "otro" usuario en el intercambio
              final bool soyOrigen = chat['usuario_origen_id'] == _myUserId;
              final Map<String, dynamic> otroUsuario = soyOrigen 
                  ? chat['destino'] 
                  : chat['origen'];

              final String exchangeId = chat['id'];
              final String nombre = otroUsuario['nombre'] ?? 'Usuario';
              final String? avatarUrl = otroUsuario['avatar_url'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null 
                        ? Text(nombre[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))
                        : null,
                  ),
                  title: Text(
                    nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: const Text('Toca para coordinar la clase...'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // Al tocar, vamos al chat privado pasándole los datos necesarios
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          exchangeId: exchangeId,
                          otroUsuarioNombre: nombre,
                          otroUsuarioId: otroUsuario['id'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}