import 'package:flutter/material.dart';

import '../models/exchange_item.dart';
import '../services/exchange_service.dart';
import '../services/search_service.dart';
import 'public_profile_screen.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Solicitudes'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Enviadas'),
              Tab(text: 'Recibidas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RequestsList(isSent: true),
            _RequestsList(isSent: false),
          ],
        ),
      ),
    );
  }
}

class _RequestsList extends StatefulWidget {
  final bool isSent;

  const _RequestsList({required this.isSent});

  @override
  State<_RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<_RequestsList> {
  final _exchangeService = ExchangeService();
  final _searchService = SearchService();

  List<ExchangeItem> _items = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final items = widget.isSent
          ? await _exchangeService.fetchSent()
          : await _exchangeService.fetchReceived();

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudieron cargar las solicitudes.';
        _loading = false;
      });
    }
  }

  Future<void> _openProfile(ExchangeItem item) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final profile = await _searchService.fetchUserProfile(item.otroUsuarioId);
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PublicProfileScreen(user: profile)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar el perfil.')),
      );
    }
  }

  Widget _buildEstadoBadge(String estado) {
    late Color background;
    late Color textColor;
    late String label;

    switch (estado) {
      case 'pendiente':
        background = Colors.amber.shade100;
        textColor = Colors.amber.shade900;
        label = 'Pendiente';
        break;
      case 'aceptada':
        background = Colors.green.shade100;
        textColor = Colors.green.shade900;
        label = 'Aceptada';
        break;
      case 'rechazada':
        background = Colors.red.shade100;
        textColor = Colors.red.shade900;
        label = 'Rechazada';
        break;
      case 'cancelada':
        background = Colors.grey.shade300;
        textColor = Colors.grey.shade800;
        label = 'Cancelada';
        break;
      default:
        background = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        label = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildCard(ExchangeItem item) {
    final hasAvatar =
        item.otroUsuarioAvatarUrl != null && item.otroUsuarioAvatarUrl!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openProfile(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: hasAvatar ? NetworkImage(item.otroUsuarioAvatarUrl!) : null,
                child: !hasAvatar ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.otroUsuarioNombre,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        _buildEstadoBadge(item.estado),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isSent
                          ? 'Le pediste: ${item.habilidadSolicitadaNombre}'
                          : 'Te pide: ${item.habilidadSolicitadaNombre}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isSent
                          ? 'Ofreciste: ${item.habilidadOfrecidaNombre}'
                          : 'Te ofrece: ${item.habilidadOfrecidaNombre}',
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              widget.isSent ? Icons.outbox_outlined : Icons.inbox_outlined,
              size: 52,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              widget.isSent
                  ? 'No has enviado solicitudes todavía.'
                  : 'No has recibido solicitudes todavía.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: _items.map(_buildCard).toList(),
      ),
    );
  }
}