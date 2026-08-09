import 'package:flutter/material.dart';

import '../models/exchange_item.dart';
import '../models/user_skill_item.dart';
import '../services/exchange_service.dart';
import '../services/search_service.dart';
import '../services/skills_service.dart';
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
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black45,
            indicatorColor: AppColors.blue,
            tabs: const [
              Tab(icon: Icon(Icons.outbox_outlined), text: 'Enviadas'),
              Tab(icon: Icon(Icons.inbox_outlined), text: 'Recibidas'),
            ],
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
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
  final SkillsService _skillsService = SkillsService();

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
    List<UserSkillItem> offeredBySender = [];
    try {
      final senderSkills = await _skillsService.fetchUserSkills(item.otroUsuarioId);
      offeredBySender = senderSkills.where((s) => s.tipo == 'ofrece').toList();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar las habilidades del remitente.')),
      );
      return;
    }

    if (offeredBySender.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este usuario ya no tiene habilidades ofrecidas disponibles.')),
      );
      return;
    }

    UserSkillItem? tempSelection = offeredBySender.first;

    final chosen = await showModalBottomSheet<UserSkillItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    Text(
                      '¿Qué quieres aprender de ${item.otroUsuarioNombre}?',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Elige una de sus habilidades ofrecidas a cambio de lo que te solicitó.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 18),
                    ...offeredBySender.map((skill) {
                      final selected = tempSelection?.skillId == skill.skillId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setModalState(() => tempSelection = skill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.successBg : AppColors.bgLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: selected ? AppColors.success : Colors.transparent, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: selected ? AppColors.success : Colors.black38,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(skill.nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () => Navigator.of(context).pop(tempSelection),
                      child: const Text('Confirmar y Aceptar'),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (chosen == null) return;

    await _executeAction(
      item: item,
      action: () => _exchangeService.acceptRequest(exchangeId: item.id, skillOfrecidaId: chosen!.skillId),
      successMessage: 'Solicitud aceptada. Vas a aprender "${chosen.nombre}".',
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

  /// Doble check (Issue #6): marca mi parte como completada.
  /// Si la otra persona ya había confirmado, el intercambio se cierra.
  Future<void> _markCompleted(ExchangeItem item) async {
    final confirmed = await _confirmAction(
      title: 'Marcar como completado',
      message: item.confirmadoPorOtro
          ? '${item.otroUsuarioNombre} ya confirmó que se completó. ¿Confirmas tú también para cerrar el intercambio?'
          : 'Vas a marcar tu parte como completada. El intercambio se cerrará cuando ambos confirmen.',
      confirmText: 'Confirmar',
    );
    if (!confirmed) return;

    await _executeAction(
      item: item,
      action: () => _exchangeService.markMyPartAsCompleted(item.id),
      successMessage: item.confirmadoPorOtro
          ? '¡Intercambio completado! Ya pueden calificarse.'
          : 'Confirmado. Esperando que la otra persona también confirme.',
      errorMessage: 'No se pudo confirmar la finalización.',
    );
  }

  /// Botón "No se presentó" (Issue #7).
  Future<void> _reportNoShow(ExchangeItem item) async {
    final confirmed = await _confirmAction(
      title: '¿La otra persona no se presentó?',
      message: 'Esto cancelará el intercambio y quedará registrado. Úsalo solo si de verdad no hubo sesión.',
      confirmText: 'Reportar ausencia',
    );
    if (!confirmed) return;

    await _executeAction(
      item: item,
      action: () => _exchangeService.reportNoShow(item.id),
      successMessage: 'Ausencia reportada. El intercambio fue cancelado.',
      errorMessage: 'No se pudo reportar la ausencia.',
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
      case 'esperando_confirmacion':
        return ExchangeStatus.esperandoConfirmacion;
      case 'completada':
        return ExchangeStatus.completada;
      case 'rechazada':
        return ExchangeStatus.rechazada;
      default:
        return ExchangeStatus.cancelada;
    }
  }

  Widget _buildActionButtons(ExchangeItem item) {
    final estado = item.estado.toLowerCase();
    final isProcessing = _processingIds.contains(item.id);

    if (isProcessing) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Center(
          child: SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.blue),
          ),
        ),
      );
    }

    // Solicitud pendiente
    if (estado == 'pendiente') {
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

    // Aceptada o esperando confirmación: se puede completar o reportar ausencia
    if (estado == 'aceptada' || estado == 'esperando_confirmacion') {
      final yaConfirmeYo = item.confirmadoPorMi;

      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (item.confirmadoPorOtro && !yaConfirmeYo)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '${item.otroUsuarioNombre} ya confirmó que se completó. ¡Confirma tú para cerrarlo!',
                  style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                    onPressed: () => _reportNoShow(item),
                    icon: const Icon(Icons.person_off_outlined, size: 18),
                    label: const Text('No se presentó'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: yaConfirmeYo ? Colors.black26 : AppColors.success),
                    onPressed: yaConfirmeYo ? null : () => _markCompleted(item),
                    icon: Icon(yaConfirmeYo ? Icons.hourglass_empty : Icons.check_circle_outline, size: 18),
                    label: Text(yaConfirmeYo ? 'Ya confirmaste' : 'Completado'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // completada, rechazada, cancelada → sin acciones
    return const SizedBox.shrink();
  }

  Widget _buildCard(ExchangeItem item) {
    final avatarUrl = item.otroUsuarioAvatarUrl?.trim();
    final isPending = item.estado.toLowerCase() == 'pendiente';

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
                          label: widget.isSent ? 'Ofreces' : 'Te ofrece',
                          skill: item.habilidadOfrecidaNombre ??
                              (isPending ? 'A definir al aceptar' : 'Sin especificar'),
                          pending: item.habilidadOfrecidaNombre == null && isPending,
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

  Widget _buildSkillRow({
    required IconData icon,
    required String label,
    required String skill,
    bool pending = false,
  }) {
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
                TextSpan(
                  text: skill,
                  style: TextStyle(
                    fontSize: 13,
                    color: pending ? Colors.black45 : Colors.black87,
                    fontStyle: pending ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
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
      return const Center(child: CircularProgressIndicator(color: AppColors.blue));
    }

    if (_errorMessage != null) {
      return RefreshIndicator(
        color: AppColors.blue,
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
        color: AppColors.blue,
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
      color: AppColors.blue,
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