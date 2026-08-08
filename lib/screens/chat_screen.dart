import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String exchangeId;
  final String otroUsuarioNombre;
  final String otroUsuarioId;

  const ChatScreen({
    super.key,
    required this.exchangeId,
    required this.otroUsuarioNombre,
    required this.otroUsuarioId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _client = Supabase.instance.client;
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  late final String _myUserId;

  // NUEVO: Variable para mantener el canal abierto
  late final Stream<List<Message>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _myUserId = _client.auth.currentUser!.id;
    // NUEVO: Inicializamos el stream una sola vez aquí
    _messagesStream = _chatService.getMessagesStream(widget.exchangeId);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    try {
      await _chatService.sendMessage(
        exchangeId: widget.exchangeId,
        senderId: _myUserId,
        content: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar el mensaje')),
        );
      }
    }
  }

  // --- LÓGICA DE RESOLUCIÓN (Issue #6 y #7) ---
  
  Future<void> _marcarCompletada() async {
    // Primer paso del Doble Check
    await _client.from('exchanges').update({
      'estado': 'esperando_confirmacion',
    }).eq('id', widget.exchangeId);
  }

  Future<void> _confirmarCompletada() async {
    // Segundo paso del Doble Check (Cierre definitivo)
    await _client.from('exchanges').update({
      'estado': 'completada',
    }).eq('id', widget.exchangeId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Intercambio finalizado con éxito!')),
      );
      // Aquí, en el futuro, abriremos el modal para calificar al usuario
    }
  }

  Future<void> _marcarAusencia() async {
    await _client.from('exchanges').update({
      'estado': 'cancelada',
    }).eq('id', widget.exchangeId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has reportado la ausencia. Intercambio cancelado.')),
      );
      Navigator.pop(context); // Sacamos al usuario del chat
    }
  }

  // Escuchamos el estado del intercambio en tiempo real
  Stream<List<Map<String, dynamic>>> get _exchangeStream =>
      _client.from('exchanges').stream(primaryKey: ['id']).eq('id', widget.exchangeId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _exchangeStream,
      builder: (context, snapshot) {
        // Obtenemos el estado actual del intercambio
        final exchangeData = snapshot.data?.firstOrNull;
        final estado = exchangeData?['estado'] ?? 'aceptada';
        final isCompletada = estado == 'completada';

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(widget.otroUsuarioNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
            actions: [
              // Solo mostramos las opciones si el chat no ha sido completado
              if (!isCompletada)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'completar') {
                      if (estado == 'esperando_confirmacion') {
                        _confirmarCompletada();
                      } else {
                        _marcarCompletada();
                      }
                    }
                    if (value == 'ausencia') _marcarAusencia();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'completar',
                      child: Text(estado == 'esperando_confirmacion' 
                          ? '✅ Confirmar finalización' 
                          : '✅ Marcar como Completada'),
                    ),
                    const PopupMenuItem(
                      value: 'ausencia',
                      child: Text('🚩 Reportar: No se presentó', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                )
            ],
          ),
          body: Column(
            children: [
              // --- BANNERS DE ESTADO ---
              if (estado == 'esperando_confirmacion')
                Container(
                  color: Colors.orange.shade100,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Pendiente de confirmación. Confirma si la clase ya se realizó.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: _confirmarCompletada,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Confirmar'),
                      )
                    ],
                  ),
                ),

              if (isCompletada)
                Container(
                  color: Colors.green.shade100,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Center(
                    child: Text(
                      '✅ Intercambio finalizado con éxito',
                      style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              if (estado == 'aceptada')
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.blue.shade50,
                  width: double.infinity,
                  child: const Text(
                    'Usa este chat para enviar el enlace y coordinar tu clase.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // --- ÁREA DE MENSAJES ---
              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: _messagesStream, // <-- USAMOS LA NUEVA VARIABLE AQUÍ
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('Aún no hay mensajes.\n¡Escribe para saludar!', textAlign: TextAlign.center),
                      );
                    }

                    return ListView.builder(
                      reverse: false,
                      itemCount: messages.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == _myUserId;
                        
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.white,
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                                bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
                              ),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Text(
                              msg.content,
                              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // --- CAJA DE TEXTO (Se oculta si ya se completó) ---
              if (!isCompletada)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.black12)),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 20),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    );
  }
}