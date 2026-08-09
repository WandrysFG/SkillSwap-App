import 'package:flutter/material.dart';

import '../models/review.dart';
import '../models/search_user.dart';
import '../models/user_skill_item.dart';
import '../services/auth_service.dart';
import '../services/exchange_service.dart';
import '../services/review_service.dart';
import '../services/skills_service.dart';
import '../utils/app_theme.dart';
import '../widgets/avatar_circle.dart';
import '../widgets/gradient_button.dart';
import '../widgets/skill_chip.dart';
import 'my_skills_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final SearchUser user;
  final String? requestedSkillId;
  final String? requestedSkillName;

  const PublicProfileScreen({
    super.key,
    required this.user,
    this.requestedSkillId,
    this.requestedSkillName,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _authService = AuthService();
  final _skillsService = SkillsService();
  final _exchangeService = ExchangeService();
  final _reviewService = ReviewService();

  List<UserSkillItem> _myOfferedSkills = [];
  List<Review> _reviews = [];
  UserRatingSummary? _ratingSummary;

  bool _loadingMySkills = true;
  bool _loadingReviews = true;
  bool _sending = false;
  bool _requestSent = false;
  int? _exchangeCount;

  String? _selectedTargetSkillId;
  String? _selectedTargetSkillName;

  @override
  void initState() {
    super.initState();
    _loadExchangeCount();
    _loadMyOfferedSkills();
    _loadReviews();

    _selectedTargetSkillId = widget.requestedSkillId;
    _selectedTargetSkillName = widget.requestedSkillName;
  }

  Future<void> _loadExchangeCount() async {
    try {
      final count = await _exchangeService.countAcceptedExchanges(
        widget.user.id,
      );
      if (!mounted) return;
      setState(() => _exchangeCount = count);
    } catch (_) {}
  }

  Future<void> _loadMyOfferedSkills() async {
    try {
      final myId = _authService.currentUser!.id;
      final mySkills = await _skillsService.fetchUserSkills(myId);
      if (!mounted) return;
      setState(() {
        _myOfferedSkills = mySkills.where((s) => s.tipo == 'ofrece').toList();
        _loadingMySkills = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMySkills = false);
    }
  }

  Future<void> _handleSendRequest() async {
    if (_myOfferedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes tener al menos una habilidad ofrecida para enviar solicitudes.',
          ),
        ),
      );
      return;
    }

    final offeredByTargetUser = widget.user.habilidadesOfrecidas
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (offeredByTargetUser.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este usuario no ofrece ninguna habilidad actualmente.',
          ),
        ),
      );
      return;
    }

    String? selectedTargetSkillName =
        _selectedTargetSkillName ??
        ((widget.requestedSkillName != null &&
                offeredByTargetUser.contains(widget.requestedSkillName))
            ? widget.requestedSkillName
            : offeredByTargetUser.first);

    // Modal 1: Elegir qué habilidad quieres aprender de este usuario
    final chosenSkillName = await showModalBottomSheet<String>(
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
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const Text(
                      '¿Qué deseas aprender de este usuario?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Selecciona la habilidad que te interesa de su repertorio.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 18),
                    ...offeredByTargetUser.map((skillName) {
                      final selected = selectedTargetSkillName == skillName;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setModalState(
                            () => selectedTargetSkillName = skillName,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.blue.withOpacity(0.1)
                                  : AppColors.bgLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? AppColors.blue
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: selected
                                      ? AppColors.blue
                                      : Colors.black38,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    skillName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                    GradientButton(
                      label: 'Continuar',
                      loading: false,
                      onPressed: () =>
                          Navigator.of(context).pop(selectedTargetSkillName),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.black54),
                        ),
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

    if (chosenSkillName == null) return;

    // Modal 2: Elegir qué habilidad tuya ofreces a cambio
    UserSkillItem? tempMySelection = _myOfferedSkills.first;

    final chosenMySkill = await showModalBottomSheet<UserSkillItem>(
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
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const Text(
                      '¿Qué prefieres ofrecer a cambio?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Elige cuál de tus habilidades darás a cambio de aprender "$chosenSkillName".',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ..._myOfferedSkills.map((skill) {
                      final selected =
                          tempMySelection?.skillId == skill.skillId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () =>
                              setModalState(() => tempMySelection = skill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.successBg
                                  : AppColors.bgLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? AppColors.success
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: selected
                                      ? AppColors.success
                                      : Colors.black38,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    skill.nombre,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    GradientButton(
                      label: 'Confirmar Solicitud',
                      loading: false,
                      onPressed: () =>
                          Navigator.of(context).pop(tempMySelection),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.black54),
                        ),
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

    if (chosenMySkill == null) return;

    setState(() => _sending = true);

    try {
      final catalog = await _skillsService.fetchCatalog();
      final targetSkillMatch = catalog.firstWhere(
        (s) => s.nombre.toLowerCase() == chosenSkillName.toLowerCase(),
      );

      await _exchangeService.sendRequest(
        usuarioDestinoId: widget.user.id,
        skillOfrecidaId: chosenMySkill.skillId,
        skillSolicitadaId: targetSkillMatch.id,
      );

      if (!mounted) return;
      setState(() {
        _sending = false;
        _requestSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Solicitud enviada! Ofreces "${chosenMySkill.nombre}" a cambio de "$chosenSkillName".',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar la solicitud. Intenta de nuevo.'),
        ),
      );
    }
  }

  String get _biografia {
    final bio = widget.user.bio?.trim();
    if (bio == null || bio.isEmpty)
      return 'Este usuario todavía no ha agregado una biografía.';
    return bio;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.user.nombre.trim().isNotEmpty
              ? widget.user.nombre
              : 'Perfil público',
        ),
        centerTitle: true,
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 24),
                _buildSkillsSection(
                  title: 'Ofrece',
                  emptyMessage:
                      'Este usuario todavía no ha agregado habilidades ofrecidas.',
                  skills: widget.user.habilidadesOfrecidas,
                ),
                const SizedBox(height: 20),
                _buildSkillsSection(
                  title: 'Quiere aprender',
                  emptyMessage:
                      'Este usuario todavía no ha agregado habilidades deseadas.',
                  skills: widget.user.habilidadesDeseadas,
                ),
                const SizedBox(height: 24),
                _buildSendRequestButton(),
                const SizedBox(height: 28),
                _buildReviewsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadReviews() async {
    try {
      final list = await _reviewService.fetchUserReviews(widget.user.id);
      if (!mounted) return;
      setState(() {
        _reviews = list;
        _ratingSummary = _reviewService.summarize(list);
        _loadingReviews = false;
      });
    } catch (e) {
      print('Error cargando reseñas: $e');
      if (!mounted) return;
      setState(() {
        _ratingSummary = UserRatingSummary(average: 0.0, count: 0);
        _loadingReviews = false;
      });
    }
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        AvatarCircle(
          nombre: widget.user.nombre,
          avatarUrl: widget.user.avatarUrl,
          size: 96,
        ),
        const SizedBox(height: 16),
        Text(
          widget.user.nombre.trim().isNotEmpty ? widget.user.nombre : 'Usuario',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        // --- ESTRELLAS UBICADAS ARRIBA (Garantizado que se muestren) ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                (_ratingSummary == null || _ratingSummary!.count == 0)
                    ? 'Sin calificaciones (0)'
                    : '${_ratingSummary!.average.toStringAsFixed(1)} (${_ratingSummary!.count} ${_ratingSummary!.count == 1 ? "reseña" : "reseñas"})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),
        if (_exchangeCount != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_horiz, size: 15, color: AppColors.blue),
                const SizedBox(width: 5),
                Text(
                  _exchangeCount == 0
                      ? 'Sin intercambios aún'
                      : '$_exchangeCount ${_exchangeCount == 1 ? "intercambio" : "intercambios"}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepBlue,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            _biografia,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reseñas y Opiniones',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.deepBlue,
                ),
              ),
              if (_ratingSummary != null && _ratingSummary!.count > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 16,
                    ),
                    Text(
                      ' ${_ratingSummary!.average.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loadingReviews)
            const Center(child: CircularProgressIndicator())
          else if (_reviews.isEmpty)
            const Text(
              'Este usuario todavía no tiene opiniones de clases.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black38,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ..._reviews.map((rev) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          rev.evaluatorName ?? 'Usuario',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(5, (starIdx) {
                            return Icon(
                              starIdx < rev.rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 15,
                              color: starIdx < rev.rating
                                  ? Colors.amber
                                  : Colors.grey,
                            );
                          }),
                        ),
                      ],
                    ),
                    if (rev.comment != null && rev.comment!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '"${rev.comment}"',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSendRequestButton() {
    if (_requestSent) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle_outline, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'Solicitud enviada',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (_loadingMySkills) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(color: AppColors.blue)),
      );
    }

    if (_myOfferedSkills.isEmpty) {
      return Column(
        children: [
          const Text(
            'Agrega al menos una habilidad que ofrezcas para poder enviar solicitudes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const MySkillsScreen()));
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar habilidades'),
          ),
        ],
      );
    }

    return GradientButton(
      label: _sending ? 'Enviando...' : 'Enviar solicitud de intercambio',
      loading: _sending,
      onPressed: _handleSendRequest,
    );
  }

  Widget _buildSkillsSection({
    required String title,
    required String emptyMessage,
    required List<String> skills,
  }) {
    final validSkills = skills
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.deepBlue,
            ),
          ),
          const SizedBox(height: 12),
          if (validSkills.isEmpty)
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black38,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: validSkills.map((s) => SkillChip(label: s)).toList(),
            ),
        ],
      ),
    );
  }
}
