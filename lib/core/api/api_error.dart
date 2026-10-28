import 'package:dio/dio.dart';

/// Message lisible pour l'utilisateur à partir d'une erreur réseau/serveur.
String apiErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      final fieldErrors = data['fieldErrors'];
      if (fieldErrors is Map && fieldErrors.isNotEmpty) {
        return fieldErrors.values.first.toString();
      }
      return data['message'] as String;
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Serveur injoignable. Vérifiez votre connexion.';
      default:
        break;
    }
    if (error.response?.statusCode == 429) return 'Trop de tentatives, réessayez dans une minute.';
    if (error.response?.statusCode == 413) return 'Fichier trop volumineux (10 Mo maximum).';
  }
  return fallback;
}
