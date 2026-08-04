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
              Tab(
                icon: Icon(Icons.outbox_outlined),
                text: 'Enviadas',
              ),
              Tab(
                icon: Icon(Icons.inbox_outlined),
                text: 'Recibidas',
              ),
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

  const _RequestsList({
    required this.isSent,
  });

  @override
  State<_RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<_RequestsList> {
  final ExchangeService _exchangeService = ExchangeService();
  final SearchService _searchService = SearchService();

  final Set<String> _processingIds = {};

  List<ExchangeItem> _items = [];

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final items = widget.isSent
          ? await _exchangeService.fetchSent()
          : await _exchangeService.fetchReceived();

      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = 'No se pudieron cargar las solicitudes.';
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final items = widget.isSent
          ? await _exchangeService.fetchSent()
          : await _exchangeService.fetchReceived();

      if (!mounted) return;

      setState(() {
        _items = items;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron actualizar las solicitudes.'),
        ),
      );
    }
  }

  Future<void> _openProfile(ExchangeItem item) async {
    if (item.otroUsuarioId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el perfil del usuario.'),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final profile = await _searchService.fetchUserProfile(
        item.otroUsuarioId,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(user: profile),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el perfil.'),
        ),
      );
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _acceptRequest(ExchangeItem item) async {
    final confirmed = await _confirmAction(
      title: 'Aceptar solicitud',
      message:
          '¿Deseas aceptar la solicitud de ${item.otroUsuarioNombre}?',
      confirmText: 'Aceptar',
    );

    if (!confirmed) return;

    await _executeAction(
      item: item,
      action: () => _exchangeService.acceptRequest(item.id),
      successMessage: 'Solicitud aceptada correctamente.',
      errorMessage: 'No se pudo aceptar la solicitud.',
    );
  }

  Future<void> _rejectRequest(ExchangeItem item) async {
    final confirmed = await _confirmAction(
      title: 'Rechazar solicitud',
      message:
          '¿Deseas rechazar la solicitud de ${item.otroUsuarioNombre}?',
      confirmText: 'Rechazar',
    );

    if (!confirmed) return;

    await _executeAction(
      item: item,
      action: () => _exchangeService.rejectRequest(item.id),
      successMessage: 'Solicitud rechazada.',
      errorMessage: 'No se pudo rechazar la solicitud.',
    );
  }

  Future<void> _cancelRequest(ExchangeItem item) async {
    final confirmed = await _confirmAction(
      title: 'Cancelar solicitud',
      message:
          '¿Deseas cancelar la solicitud enviada a ${item.otroUsuarioNombre}?',
      confirmText: 'Cancelar solicitud',
    );

    if (!confirmed) return;

    await _executeAction(
      item: item,
      action: () => _exchangeService.cancelRequest(item.id),
      successMessage: 'Solicitud cancelada.',
      errorMessage: 'No se pudo cancelar la solicitud.',
    );
  }

  Future<void> _executeAction({
    required ExchangeItem item,
    required Future<void> Function() action,
    required String successMessage,
    required String errorMessage,
  }) async {
    setState(() {
      _processingIds.add(item.id);
    });

    try {
      await action();
      await _refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(item.id);
        });
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    late Color backgroundColor;
    late Color foregroundColor;
    late IconData icon;
    late String label;

    switch (status.toLowerCase()) {
      case 'pendiente':
        backgroundColor = Colors.amber.shade100;
        foregroundColor = Colors.amber.shade900;
        icon = Icons.schedule;
        label = 'Pendiente';
        break;

      case 'aceptada':
        backgroundColor = Colors.green.shade100;
        foregroundColor = Colors.green.shade900;
        icon = Icons.check_circle_outline;
        label = 'Aceptada';
        break;

      case 'rechazada':
        backgroundColor = Colors.red.shade100;
        foregroundColor = Colors.red.shade900;
        icon = Icons.cancel_outlined;
        label = 'Rechazada';
        break;

      case 'cancelada':
        backgroundColor = Colors.grey.shade300;
        foregroundColor = Colors.grey.shade800;
        icon = Icons.block_outlined;
        label = 'Cancelada';
        break;

      default:
        backgroundColor = Colors.blueGrey.shade100;
        foregroundColor = Colors.blueGrey.shade900;
        icon = Icons.info_outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: foregroundColor,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ExchangeItem item) {
    if (item.estado.toLowerCase() != 'pendiente') {
      return const SizedBox.shrink();
    }

    final isProcessing = _processingIds.contains(item.id);

    if (isProcessing) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Center(
          child: SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    if (widget.isSent) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _cancelRequest(item),
            icon: const Icon(Icons.close),
            label: const Text('Cancelar solicitud'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _rejectRequest(item),
              icon: const Icon(Icons.close),
              label: const Text('Rechazar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _acceptRequest(item),
              icon: const Icon(Icons.check),
              label: const Text('Aceptar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ExchangeItem item) {
    final avatarUrl = item.otroUsuarioAvatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openProfile(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundImage:
                          hasAvatar ? NetworkImage(avatarUrl) : null,
                      child: !hasAvatar
                          ? const Icon(
                              Icons.person,
                              size: 28,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.otroUsuarioNombre,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(item.estado),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSkillRow(
                            icon: Icons.school_outlined,
                            label: widget.isSent
                                ? 'Solicitaste'
                                : 'Te solicita',
                            skill: item.habilidadSolicitadaNombre,
                          ),
                          const SizedBox(height: 7),
                          _buildSkillRow(
                            icon: Icons.swap_horiz,
                            label: widget.isSent
                                ? 'Ofreciste'
                                : 'Te ofrece',
                            skill: item.habilidadOfrecidaNombre,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            _buildActionButtons(item),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillRow({
    required IconData icon,
    required String label,
    required String skill,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: skill),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            widget.isSent
                ? Icons.outbox_outlined
                : Icons.inbox_outlined,
            size: 58,
            color: Colors.grey,
          ),
          const SizedBox(height: 14),
          Text(
            widget.isSent
                ? 'No has enviado solicitudes todavía.'
                : 'No has recibido solicitudes todavía.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Desliza hacia abajo para actualizar.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 80),
            const Icon(
              Icons.error_outline,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Center(
              child: OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          return _buildCard(_items[index]);
        },
      ),
    );
  }
}