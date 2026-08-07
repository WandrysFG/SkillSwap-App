import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AvatarCircle extends StatelessWidget {
  final String nombre;
  final String? avatarUrl;
  final double size;

  const AvatarCircle({
    super.key,
    required this.nombre,
    this.avatarUrl,
    this.size = 44,
  });

  String get _initials {
    final parts = nombre.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Color get _color {
    final index = nombre.hashCode.abs() % AppColors.avatarPalette.length;
    return AppColors.avatarPalette[index];
  }

  Widget _buildInitials() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _color.withOpacity(0.15)),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: size * 0.36),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    if (!hasPhoto) return _buildInitials();

    return ClipOval(
      child: Image.network(
        avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            color: AppColors.bgLight,
            alignment: Alignment.center,
            child: SizedBox(
              width: size * 0.35,
              height: size * 0.35,
              child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildInitials(),
      ),
    );
  }
}