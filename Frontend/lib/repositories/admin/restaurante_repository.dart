import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/models/admin/perfil_restaurante_model.dart';

class RestauranteRepository {
  Future<PerfilRestauranteModel?> obtenerMiRestaurante(String token) async {
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/mis-restaurantes');
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data.isNotEmpty) {
          return PerfilRestauranteModel.fromJson(data.first);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error en obtenerMiRestaurante: $e');
      rethrow;
    }
  }

  Future<String?> obtenerDireccionGeocoding(double lat, double lng) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data['display_name'] != null) {
          final partes = data['display_name'].toString().split(',');
          return partes.take(2).join(',').trim();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error en obtenerDireccionGeocoding: $e');
      rethrow;
    }
  }

  Future<bool> actualizarPerfil({
    required String token,
    required int restauranteId,
    required Map<String, dynamic> body,
    Uint8List? selectedImageBytes,
    PlatformFile? selectedImage,
    Uint8List? selectedLogoBytes,
    PlatformFile? selectedLogo,
    List<Uint8List> selectedGalleryBytes = const [],
    List<PlatformFile> selectedGallery = const [],
  }) async {
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/$restauranteId');
      
      final res = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        if (selectedImageBytes != null && selectedImage != null) {
          final photoUrl = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/$restauranteId/portada');
          final request = http.MultipartRequest('POST', photoUrl);
          request.headers['Authorization'] = 'Bearer $token';
          
          final ext = selectedImage.name.split('.').last.toLowerCase();
          final mimeType = ext == 'png' ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');
          
          request.files.add(http.MultipartFile.fromBytes(
            'file', 
            selectedImageBytes, 
            filename: selectedImage.name,
            contentType: MediaType('image', mimeType),
          ));
          
          final photoRes = await request.send();
          if (photoRes.statusCode != 200 && photoRes.statusCode != 201) {
            throw Exception('Error al subir la portada');
          }
        }

        if (selectedLogoBytes != null && selectedLogo != null) {
          final logoUrl = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/$restauranteId/logo');
          final request = http.MultipartRequest('POST', logoUrl);
          request.headers['Authorization'] = 'Bearer $token';
          final ext = selectedLogo.name.split('.').last.toLowerCase();
          final mimeType = ext == 'png' ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');
          request.files.add(http.MultipartFile.fromBytes('file', selectedLogoBytes, filename: selectedLogo.name, contentType: MediaType('image', mimeType)));
          await request.send();
        }

        if (selectedGalleryBytes.isNotEmpty) {
          final galeriaUrl = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/$restauranteId/galeria');
          final request = http.MultipartRequest('POST', galeriaUrl);
          request.headers['Authorization'] = 'Bearer $token';
          for (int i = 0; i < selectedGallery.length; i++) {
             final ext = selectedGallery[i].name.split('.').last.toLowerCase();
             final mimeType = ext == 'png' ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');
             request.files.add(http.MultipartFile.fromBytes('files', selectedGalleryBytes[i], filename: selectedGallery[i].name, contentType: MediaType('image', mimeType)));
          }
          await request.send();
        }
        
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error en actualizarPerfil: $e');
      rethrow;
    }
  }
}
