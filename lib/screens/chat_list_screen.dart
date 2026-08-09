import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_theme.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Mensajes',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Activos'),
              Tab(icon: Icon(Icons.history_rounded), text: 'Historial'),
            ],
          ),
        ),
        body: Container(
          color: Colors.white,
          child: const TabBarView(
            children: [
              _ChatListTab(isHistory: false),
              _ChatListTab(isHistory: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatListTab extends StatefulWidget {
  final bool isHistory;
  const _ChatListTab({required this.isHistory});

  @override
  State<_ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends State<_ChatListTab> {
  final _client = Supabase.instance.client;
  late final String _myUserId;

  @override
  void initState() {
    super.initState();
    _myUserId = _client.auth.currentUser!.id;
  }

  Future<List<dynamic>> _fetchChats() async {
    // Si es historial consulta 'completada', de lo contrario consulta 'aceptada' y 'esperando_confirmacion'
    final estados = widget.isHistory
        ? ['completada']
        : ['aceptada', 'esperando_confirmacion'];

    final response = await _client
        .from('exchanges')
        .select('''
          id,
          estado,
          usuario_origen_id,
          usuario_destino_id,
          origen:users!exchanges_usuario_origen_id_fkey(id, nombre, avatar_url),
          destino:users!exchanges_usuario_destino_id_fkey(id, nombre, avatar_url),
          skill_ofrecida:skill_ofrecida_id(nombre),
          skill_solicitada:skill_solicitada_id(nombre)
        ''')
        .inFilter('estado', estados)
        .or('usuario_origen_id.eq.$_myUserId,usuario_destino_id.eq.$_myUserId')
        .order(
          'updated_at',
          ascending: false,
        ); // <-- CAMBIO APLICADO: Ordena por el chat con actividad más reciente

    return response as List<dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.blue),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar chats: ${snapshot.error}'),
          );
        }

        final chats = snapshot.data ?? [];

        if (chats.isEmpty) {
          return Center(
            child: Text(
              widget.isHistory
                  ? 'Aún no tienes intercambios completados.'
                  : 'Aún no tienes chats activos.\n¡Acepta una solicitud para empezar!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black45, fontSize: 14),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          color: AppColors.blue,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final bool soyOrigen = chat['usuario_origen_id'] == _myUserId;
              final Map<String, dynamic> otroUsuario = soyOrigen
                  ? chat['destino']
                  : chat['origen'];

              final String exchangeId = chat['id'];
              final String nombre = otroUsuario['nombre'] ?? 'Usuario';
              final String? avatarUrl = otroUsuario['avatar_url'];

              final String skillOfrecida =
                  chat['skill_ofrecida']?['nombre'] ?? '???';
              final String skillSolicitada =
                  chat['skill_solicitada']?['nombre'] ?? '???';

              final String miAprendizaje = soyOrigen
                  ? skillSolicitada
                  : skillOfrecida;
              final String miEnsenanza = soyOrigen
                  ? skillOfrecida
                  : skillSolicitada;
              final String temaChat =
                  'Aprendes $miAprendizaje • Enseñas $miEnsenanza';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                color: widget.isHistory
                    ? Colors.white.withOpacity(0.9)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.bgLight,
                        backgroundImage:
                            avatarUrl != null && avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null || avatarUrl.isEmpty
                            ? Text(
                                nombre.isNotEmpty
                                    ? nombre[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepBlue,
                                ),
                              )
                            : null,
                      ),
                      if (widget.isHistory)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        temaChat,
                        style: TextStyle(
                          color: widget.isHistory
                              ? Colors.black54
                              : AppColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isHistory
                            ? 'Intercambio completado'
                            : 'Toca para coordinar la clase...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          exchangeId: exchangeId,
                          otroUsuarioNombre: nombre,
                          otroUsuarioId: otroUsuario['id'],
                          temaIntercambio: temaChat,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
