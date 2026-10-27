import 'package:flutter/material.dart';

import '../core/place_style.dart';
import '../core/theme.dart';
import '../models/place.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place});

  final CampusPlace place;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.palette.line),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Icon(categoryIcon(place.category), color: categoryColor(place.category)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name, style: AppTextStyles.title.copyWith(fontSize: 16, color: context.palette.ink)),
                const SizedBox(height: 2),
                Text(place.category, style: AppTextStyles.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
