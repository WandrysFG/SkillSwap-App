import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/review.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/review_service.dart';
import '../utils/app_theme.dart';
import '../widgets/gradient_button.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _profileService = ProfileService();
  final _reviewService = ReviewService();

  late Future<AppUser?> _profileFuture;

  List<Review> _reviews = [];
  UserRatingSummary? _ratingSummary;
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _loadMyReviews();
  }

  Future<AppUser?> _loadProfile() {
    final userId = _authService.currentUser!.id;
    return _profileService.fetchProfile(userId);
  }

  Future<void> _loadMyReviews() async {
    try {
      final userId = _authService.currentUser!.id;

      print('CONSULTANDO RESEÑAS PARA: $userId');

      final list = await _reviewService.fetchUserReviews(userId);
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

  Future<void> _refresh() async {
    setState(() {
      _loadingReviews = true;
      _profileFuture = _loadProfile();
    });
    await _loadMyReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: FutureBuilder<AppUser?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.blue),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error al cargar el perfil: ${snapshot.error}'),
              );
            }

            final user = snapshot.data;

            if (user == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off_outlined,
                        size: 56,
                        color: Colors.black38,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No encontramos tu perfil.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Esto puede pasar si tu cuenta no completó el registro correctamente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final hasAvatar =
                user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

            return RefreshIndicator(
              color: AppColors.blue,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: hasAvatar ? null : AppColors.primaryGradient,
                        image: hasAvatar
                            ? DecorationImage(
                                image: NetworkImage(user.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blue.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: hasAvatar
                          ? null
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 52,
                            ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user.nombre,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (_ratingSummary == null ||
                                    _ratingSummary!.count == 0)
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

                    const SizedBox(height: 20),
                    Container(
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
                          const Text(
                            'Biografía',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.deepBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (user.bio == null || user.bio!.trim().isEmpty)
                                ? 'Aún no has agregado una biografía.'
                                : user.bio!,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  (user.bio == null || user.bio!.trim().isEmpty)
                                  ? Colors.black38
                                  : Colors.black87,
                              fontStyle:
                                  (user.bio == null || user.bio!.trim().isEmpty)
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    GradientButton(
                      label: 'Editar Perfil',
                      loading: false,
                      onPressed: () async {
                        final updated = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: user),
                          ),
                        );
                        if (updated == true) _refresh();
                      },
                    ),
                    const SizedBox(height: 28),

                    _buildMyReviewsSection(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMyReviewsSection() {
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
          const Text(
            'Mis Reseñas',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.deepBlue,
            ),
          ),
          const SizedBox(height: 14),
          if (_loadingReviews)
            const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            )
          else if (_reviews.isEmpty)
            const Text(
              'Aún no tienes reseñas. ¡Completa más intercambios para ganar reputación!',
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
}
