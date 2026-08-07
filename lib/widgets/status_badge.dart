import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

enum ExchangeStatus { pendiente, aceptada, rechazada, cancelada }

class StatusBadge extends StatelessWidget {
  final ExchangeStatus status;

  const StatusBadge({super.key, required this.status});

  ({Color bg, Color text, String label}) get _style {
    switch (status) {
      case ExchangeStatus.pendiente:
        return (bg: AppColors.warningBg, text: AppColors.warning, label: 'Pendiente');
      case ExchangeStatus.aceptada:
        return (bg: AppColors.successBg, text: AppColors.success, label: 'Aceptada');
      case ExchangeStatus.rechazada:
        return (bg: AppColors.dangerBg, text: AppColors.danger, label: 'Rechazada');
      case ExchangeStatus.cancelada:
        return (bg: AppColors.neutralBg, text: AppColors.neutral, label: 'Cancelada');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(999)),
      child: Text(s.label, style: TextStyle(color: s.text, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}