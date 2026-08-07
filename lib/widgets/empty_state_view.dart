import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool outlinedAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.outlinedAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: AppColors.bgLight, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: AppColors.blue),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              outlinedAction
                  ? OutlinedButton(onPressed: onAction, child: Text(actionLabel!))
                  : ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white),
                      child: Text(actionLabel!),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}