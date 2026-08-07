import 'package:flutter/material.dart';

import '../models/exchange_item.dart';
import '../services/exchange_service.dart';
import '../services/search_service.dart';
import '../utils/app_theme.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/status_badge.dart';
import '../widgets/empty_state_view.dart';
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
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppColors.blue,
            unselectedLabelColor: Colors.black45,
            indicatorColor: AppColors.blue,
            tabs: const [
              Tab(icon: Icon(Icons.outbox_outlined), text: 'Enviadas'),
              Tab(icon: Icon(Icons.inbox_outlined), text: 'Recibidas'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: const TabBarView(
            children: [
              _RequestsList(isSent: true),
              _RequestsList(isSent: false),
            ],
          ),
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
      final items = widget.isSent ? await _exchangeService.fetchSent() : await _exchangeService.fetchReceived();
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
      final items = widget.isSent ? await _exchangeService.fetchSent() : await _exchangeService.fetchReceived();
      if (!mounted) return;
      setState(() {
        _items = items;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron actualizar las solicitudes.')),
      );
    }
  }

  Future<void> _openProfile(ExchangeItem item) async {
    if (item.otroUsuarioId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el perfil del usuario.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final profile = await _searchService.fetchUserProfile(item.otroUsuarioId);
      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PublicProfileScreen(user: profile)),
      );
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar el perfil.')),
      );
    }
  }

  Future<bool> _confirmAction({required String title, required String message, required String confirmText}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Volver')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
              onPressed: () => Navigator.of(dialogContext).pop(true),
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
      message: '¿Deseas aceptar la solicitud de ${item.otroUsuarioNombre}?',
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
      message: '¿Deseas rechazar la solicitud de ${item.otroUsuarioNombre}?',
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
      message: '¿Deseas cancelar la solicitud enviada a ${item.otroUsuarioNombre}?',
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
    setState(() => _processingIds.add(item.id));
    try {
      await action();
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      if (mounted) setState(() => _processingIds.remove(item.id));
    }
  }

  ExchangeStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return ExchangeStatus.pendiente;
      case 'aceptada':
        return ExchangeStatus.aceptada;
      case 'rechazada':
        return ExchangeStatus.rechazada;
      default:
        return ExchangeStatus.cancelada;
    }
  }

  Widget _buildActionButtons(ExchangeItem item) {
    if (item.estado.toLowerCase() != 'pendiente') return const SizedBox.shrink();

    final isProcessing = _processingIds.contains(item.id);
    if (isProcessing) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Center(child: SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 2.5))),
      );
    }

    if (widget.isSent) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
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
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
              onPressed: () => _rejectRequest(item),
              icon: const Icon(Icons.close),
              label: const Text('Rechazar'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openProfile(item),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AvatarCircle(nombre: item.otroUsuarioNombre, avatarUrl: avatarUrl, size: 50),
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
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(status: _parseStatus(item.estado)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSkillRow(
                          icon: Icons.school_outlined,
                          label: widget.isSent ? 'Solicitaste' : 'Te solicita',
                          skill: item.habilidadSolicitadaNombre,
                        ),
                        const SizedBox(height: 6),
                        _buildSkillRow(
                          icon: Icons.swap_horiz,
                          label: widget.isSent ? 'Ofreciste' : 'Te ofrece',
                          skill: item.habilidadOfrecidaNombre,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.chevron_right, color: Colors.black26),
                ],
              ),
            ),
            _buildActionButtons(item),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillRow({required IconData icon, required String label, required String skill}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.blue),
        const SizedBox(width: 7),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                TextSpan(text: skill, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 60),
          children: [
            EmptyStateView(
              icon: Icons.error_outline,
              title: 'No se pudieron cargar',
              subtitle: _errorMessage!,
              actionLabel: 'Reintentar',
              onAction: _load,
              outlinedAction: true,
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 60),
          children: [
            EmptyStateView(
              icon: widget.isSent ? Icons.outbox_outlined : Icons.inbox_outlined,
              title: widget.isSent ? 'Sin solicitudes enviadas' : 'Sin solicitudes recibidas',
              subtitle: 'Desliza hacia abajo para actualizar.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: _items.length,
        itemBuilder: (context, index) => _buildCard(_items[index]),
      ),
    );
  }
}