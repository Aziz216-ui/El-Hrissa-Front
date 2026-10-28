import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

const _monthsShort = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

/// L'arche des portes tunisiennes, à réutiliser sur les grands visuels (carte de swipe).
BorderRadius archRadius({double top = 150, double bottom = AppRadius.sheet}) => BorderRadius.only(
      topLeft: Radius.circular(top),
      topRight: Radius.circular(top),
      bottomLeft: Radius.circular(bottom),
      bottomRight: Radius.circular(bottom),
    );

/// Logo de l'app : « Elahrisa » en italique + piment.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Elahrisa',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Elahrisa', style: AppTextStyles.headlineMd.copyWith(color: AppColors.primary, fontStyle: FontStyle.italic)),
          const Text(' 🌶️', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}

/// Pastille de date « billet » : jour en grand, mois en dessous. Bleu = sortie.
class EventDateStub extends StatelessWidget {
  final DateTime? date;
  final double size;
  const EventDateStub({super.key, required this.date, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final d = date;
    return Container(
      width: size,
      height: size + 6,
      decoration: BoxDecoration(color: AppColors.sidiTint, borderRadius: BorderRadius.circular(AppRadius.control)),
      alignment: Alignment.center,
      child: d == null
          ? const Icon(Icons.event_outlined, color: AppColors.sidi)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${d.day}', style: AppTextStyles.titleMd.copyWith(color: AppColors.sidi, fontSize: size * 0.4, height: 1.05)),
                Text(
                  _monthsShort[d.month - 1],
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.sidi, fontWeight: FontWeight.w700),
                ),
              ],
            ),
    );
  }
}
