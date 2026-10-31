import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'legal_content.dart';

/// Page de texte légal (conditions d'utilisation ou politique de confidentialité).
class LegalScreen extends StatelessWidget {
  final String title;
  final List<LegalSection> sections;
  const LegalScreen({super.key, required this.title, required this.sections});

  const LegalScreen.terms({super.key})
      : title = "Conditions d'utilisation",
        sections = termsSections;

  const LegalScreen.privacy({super.key})
      : title = 'Politique de confidentialité',
        sections = privacySections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          tooltip: 'Retour',
          onPressed: () => context.canPop() ? context.pop() : context.go('/welcome'),
        ),
        title: Text(title, style: AppTextStyles.titleMd),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                Text('Dernière mise à jour : $legalLastUpdate', style: AppTextStyles.labelSm),
                const SizedBox(height: 16),
                for (final section in sections) ...[
                  Semantics(header: true, child: Text(section.title, style: AppTextStyles.titleMd)),
                  const SizedBox(height: 8),
                  for (final paragraph in section.paragraphs) ...[
                    Text(paragraph, style: AppTextStyles.bodyMd.copyWith(height: 1.6)),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Phrase de consentement avec liens vers les deux textes, à placer sous les boutons.
class LegalLinks extends StatelessWidget {
  final TextAlign align;

  /// Version sobre : seulement les deux liens, sans phrase (accueil).
  final bool short;
  const LegalLinks({super.key, this.align = TextAlign.center}) : short = false;
  const LegalLinks.short({super.key})
      : align = TextAlign.center,
        short = true;

  @override
  Widget build(BuildContext context) {
    if (short) {
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        children: [
          _link(context, "Conditions d'utilisation", '/terms'),
          _link(context, 'Confidentialité', '/privacy'),
        ],
      );
    }
    return Wrap(
      alignment: align == TextAlign.center ? WrapAlignment.center : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('En continuant, vous acceptez nos ', style: AppTextStyles.labelSm),
        _link(context, "conditions d'utilisation", '/terms'),
        Text(' et notre ', style: AppTextStyles.labelSm),
        _link(context, 'politique de confidentialité', '/privacy'),
        Text('.', style: AppTextStyles.labelSm),
      ],
    );
  }

  Widget _link(BuildContext context, String label, String route) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        // zone de toucher plus grande que le texte
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(color: AppColors.primary, decoration: TextDecoration.underline),
        ),
      ),
    );
  }
}
