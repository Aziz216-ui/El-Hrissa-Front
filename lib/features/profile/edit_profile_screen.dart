import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/profile_models.dart';
import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/network_photo.dart';
import '../../shared/widgets/state_views.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _service = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestController = TextEditingController();

  List<PhotoResponse> _photos = [];
  List<String> _interests = [];
  String _genderPreference = 'EVERYONE';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final p = await _service.getMyProfile();
      if (!mounted) return;
      setState(() {
        _photos = p.photos;
        _interests = List.of(p.interests);
        _nameController.text = p.displayName ?? '';
        _bioController.text = p.bio ?? '';
        _genderPreference = p.genderPreference ?? 'EVERYONE';
      });
    } catch (e) {
      if (mounted) setState(() => _error = cleanError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshPhotos() async {
    final p = await _service.getMyProfile();
    if (mounted) setState(() => _photos = p.photos);
  }

  Future<void> _addPhoto() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (file == null) return;
      setState(() => _isUploading = true);
      await _service.uploadPhoto(file);
      await _refreshPhotos();
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _photoActions(PhotoResponse photo) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!photo.isMain)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Définir comme photo principale'),
                onTap: () => Navigator.pop(ctx, 'main'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;
    try {
      if (action == 'main') await _service.setMainPhoto(photo.id);
      if (action == 'delete') await _service.deletePhoto(photo.id);
      await _refreshPhotos();
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    }
  }

  void _addInterest() {
    final value = _interestController.text.trim();
    if (value.isEmpty) return;
    if (value.length > 50) {
      showSnack(context, '50 caractères maximum par centre d\'intérêt', error: true);
      return;
    }
    if (_interests.any((i) => i.toLowerCase() == value.toLowerCase())) {
      _interestController.clear();
      return;
    }
    setState(() {
      _interests.add(value);
      _interestController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _service.updateProfile(
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        genderPreference: _genderPreference,
        interests: _interests,
      );
      if (mounted) {
        showSnack(context, 'Profil enregistré ✅');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showSnack(context, cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Mon profil', style: AppTextStyles.headlineMd)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Photos', style: AppTextStyles.labelMd),
            const SizedBox(height: 4),
            Text('Appuyez sur une photo pour la gérer. La première sert de photo principale.',
                style: AppTextStyles.labelSm),
            const SizedBox(height: 12),
            _buildPhotoGrid(),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              maxLength: 255,
              decoration: const InputDecoration(labelText: 'Prénom affiché'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioController,
              maxLength: 500,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true),
              validator: (v) => v == null || v.trim().isEmpty ? 'La bio est nécessaire pour apparaître dans les suggestions' : null,
            ),
            const SizedBox(height: 16),
            Text('Je souhaite rencontrer', style: AppTextStyles.labelMd),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'WOMEN', label: Text('Femmes')),
                ButtonSegment(value: 'MEN', label: Text('Hommes')),
                ButtonSegment(value: 'EVERYONE', label: Text('Tous')),
              ],
              selected: {_genderPreference},
              onSelectionChanged: (s) => setState(() => _genderPreference = s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.pastelPink,
                selectedForegroundColor: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 24),
            Text('Centres d\'intérêt', style: AppTextStyles.labelMd),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _interestController,
                    decoration: const InputDecoration(hintText: 'Ex : Cinéma, Voyage...'),
                    onSubmitted: (_) => _addInterest(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addInterest,
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: const Icon(Icons.add, color: AppColors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interests
                  .map((i) => Chip(label: Text(i), onDeleted: () => setState(() => _interests.remove(i))))
                  .toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ..._photos.map(
          (p) => GestureDetector(
            onTap: () => _photoActions(p),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkPhoto(url: p.url),
                  if (p.isMain)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                        child: Text('Principale', style: AppTextStyles.labelSm.copyWith(color: AppColors.white, fontSize: 10)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: _isUploading ? null : _addPhoto,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Center(
              child: _isUploading
                  ? const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5)
                  : const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
