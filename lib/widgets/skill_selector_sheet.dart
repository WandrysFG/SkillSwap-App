import 'package:flutter/material.dart';
import '../models/skill.dart';
import '../utils/app_theme.dart';

/// Muestra un bottom sheet con el catálogo de habilidades agrupado por
/// categoría. `excludeIds` son las habilidades que ya están en la lista
/// (de ese mismo tipo) y por lo tanto no se deben poder elegir de nuevo.
/// Retorna el Skill elegido, o null si el usuario cierra el sheet.
Future<Skill?> showSkillSelectorSheet({
  required BuildContext context,
  required List<Skill> catalog,
  required Set<String> excludeIds,
  required String title,
}) {
  // Agrupa el catálogo por categoría, manteniendo el orden ya ordenado
  // que viene del backend (fetchCatalog ordena por categoria).
  final Map<String, List<Skill>> grouped = {};
  for (final skill in catalog) {
    grouped.putIfAbsent(skill.categoria, () => []).add(skill);
  }

  return showModalBottomSheet<Skill>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: grouped.entries.map((entry) {
                      final categoria = entry.key;
                      final skills = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            categoria,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.deepBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: skills.map((skill) {
                              final alreadyAdded = excludeIds.contains(skill.id);
                              return ChoiceChip(
                                label: Text(skill.nombre),
                                selected: false,
                                disabledColor: Colors.black12,
                                onSelected: alreadyAdded
                                    ? null
                                    : (_) => Navigator.of(context).pop(skill),
                                labelStyle: TextStyle(
                                  color: alreadyAdded ? Colors.black38 : Colors.black87,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}