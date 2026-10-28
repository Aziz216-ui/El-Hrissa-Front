import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_client.dart';
import '../api/api_error.dart';
import '../api/endpoints.dart';
import '../models/profile_models.dart';

class ProfileService {
  final ApiClient _api = ApiClient();

  Future<ProfileResponse> getMyProfile() async {
    try {
      final response = await _api.dio.get(Endpoints.myProfile);
      return ProfileResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de charger le profil'));
    }
  }

  Future<PublicProfileResponse> getPublicProfile(int userId) async {
    try {
      final response = await _api.dio.get(Endpoints.publicProfile(userId));
      return PublicProfileResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Profil introuvable'));
    }
  }

  Future<ProfileResponse> updateProfile({
    String? displayName,
    String? bio,
    String? genderPreference,
    List<String>? interests,
  }) async {
    try {
      final response = await _api.dio.put(Endpoints.myProfile, data: {
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (genderPreference != null) 'genderPreference': genderPreference,
        if (interests != null) 'interests': interests,
      });
      return ProfileResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de mettre à jour le profil'));
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      await _api.dio.put(Endpoints.myLocation, data: {'latitude': latitude, 'longitude': longitude});
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Erreur de mise à jour de la localisation'));
    }
  }

  Future<PhotoResponse> uploadPhoto(XFile file) async {
    try {
      final response = await _api.dio.post(Endpoints.myPhotos, data: await _imageForm(file));
      return PhotoResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Impossible d'envoyer la photo"));
    }
  }

  Future<void> deletePhoto(int photoId) async {
    try {
      await _api.dio.delete(Endpoints.photo(photoId));
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de supprimer la photo'));
    }
  }

  Future<void> setMainPhoto(int photoId) async {
    try {
      await _api.dio.put(Endpoints.mainPhoto(photoId));
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Impossible de changer la photo principale'));
    }
  }

  Future<ProfileResponse> submitVerification(XFile selfie) async {
    try {
      final response = await _api.dio.post(Endpoints.myVerification, data: await _imageForm(selfie));
      return ProfileResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, "Impossible d'envoyer le selfie de vérification"));
    }
  }

  /// Le backend n'accepte que JPEG/PNG/WebP : on déduit le type de l'extension
  /// (fiable aussi sur le web, où mimeType peut être vide).
  Future<FormData> _imageForm(XFile file) async {
    final name = file.name.toLowerCase();
    String ext = 'jpg';
    String mime = 'image/jpeg';
    if (name.endsWith('.png')) {
      ext = 'png';
      mime = 'image/png';
    } else if (name.endsWith('.webp')) {
      ext = 'webp';
      mime = 'image/webp';
    }
    final bytes = await file.readAsBytes();
    return FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: 'photo.$ext',
        contentType: DioMediaType.parse(mime),
      ),
    });
  }
}
