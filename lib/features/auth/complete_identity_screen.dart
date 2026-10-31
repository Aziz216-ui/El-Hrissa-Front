import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Étape obligatoire après une inscription Google : Google ne fournit ni le genre ni la date de naissance.
class CompleteIdentityScreen extends StatefulWidget {
  const CompleteIdentityScreen({super.key});

  @override
  State<CompleteIdentityScreen> createState() => _CompleteIdentityScreenState();
}

class _CompleteIdentityScreenState extends State<CompleteIdentityScreen> {
  final _authService = AuthService();

  DateTime _dateNaissance = DateTime(2000, 1, 1);
  String _gender = 'MEN';
  bool _isLoading = false;
  String? _errorMessage;

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance,
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 ans min
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.completeIdentity(
        dateNaissance: '${_dateNaissance.year.toString().padLeft(4, '0')}-${_two(_dateNaissance.month)}-${_two(_dateNaissance.day)}',
        gender: _gender,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _genderChip(String value, String label) => ChoiceChip(
        label: Text(label),
        selected: _gender == value,
        onSelected: (selected) {
          if (selected) setState(() => _gender = value);
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: _gender == value ? AppColors.white : AppColors.onSurface),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Dernière étape', style: AppTextStyles.headlineXl.copyWith(color: AppColors.primary), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Ces informations servent à vous proposer des profils compatibles.',
                  style: AppTextStyles.bodyMdMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (_errorMessage != null) ...[
                  Text(_errorMessage!, style: AppTextStyles.labelSm.copyWith(color: AppColors.error)),
                  const SizedBox(height: 12),
                ],
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: AppColors.outline),
                        const SizedBox(width: 12),
                        Text(
                          'Date de naissance : ${_two(_dateNaissance.day)}/${_two(_dateNaissance.month)}/${_dateNaissance.year}',
                          style: AppTextStyles.bodyMd,
                        ),
                        const Spacer(),
                        const Icon(Icons.edit, size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Genre : ', style: AppTextStyles.labelMd),
                    const SizedBox(width: 12),
                    _genderChip('MEN', 'Homme'),
                    const SizedBox(width: 12),
                    _genderChip('WOMEN', 'Femme'),
                  ],
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Continuer'),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _authService.logout,
                  child: const Text('Annuler et me déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
