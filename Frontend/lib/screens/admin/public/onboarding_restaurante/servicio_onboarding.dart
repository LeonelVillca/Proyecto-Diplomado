part of '../onboarding_restaurante_screen.dart';

extension _Onboarding_servicio_onboarding on _OnboardingRestauranteScreenState {
  String _mensajeErrorApi(int statusCode, List<int> bodyBytes) {
    try {
      final body = jsonDecode(utf8.decode(bodyBytes));
      final message = body is Map ? body['message'] : null;
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) return message.join(', ');
    } catch (_) {
      // El servidor pudo responder un texto no JSON.
    }
    return 'El servidor rechazó la solicitud (HTTP $statusCode).';
  }

  Future<void> _verificarCarga(
    http.StreamedResponse response,
    String operacion,
  ) async {
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      await response.stream.drain<void>();
      return;
    }
    final bytes = await response.stream.toBytes();
    throw Exception(
      '$operacion: ${this._mensajeErrorApi(response.statusCode, bytes)}',
    );
  }

  Future<void> _finalizar() async {
    if (_tiposComidaSeleccionados.isEmpty) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'Selecciona al menos un tipo de comida.',
        );
      }
      return;
    }
    if (_selectedImage == null) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'La foto de portada es obligatoria.',
        );
      }
      return;
    }
    if (_selectedLogoBytes == null) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'El logo del restaurante es obligatorio.',
        );
      }
      return;
    }
    if (_horarios.isEmpty) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'Debes configurar al menos un horario de atención.',
        );
      }
      return;
    }
    if (_mesasTotalCtrl.text.isEmpty || _capacidadTotalCtrl.text.isEmpty) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'Configura la capacidad de tu salón (mesas y comensales).',
        );
      }
      return;
    }
    final mesasTotal = int.tryParse(_mesasTotalCtrl.text.trim());
    final capacidadTotal = int.tryParse(_capacidadTotalCtrl.text.trim());
    if (mesasTotal == null ||
        capacidadTotal == null ||
        mesasTotal < 1 ||
        capacidadTotal < mesasTotal) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'La capacidad total debe ser un número igual o mayor que la cantidad de mesas.',
        );
      }
      return;
    }
    if (_selectedGallery.length < 5) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'Te faltan ${5 - _selectedGallery.length} fotos para activar tu restaurante.',
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = AuthScope.of(context, listen: false).token;

      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}/api/v1/restaurante/${widget.restaurante.id}',
      );
      final body = {
        'nombre': _nombreCtrl.text.trim(),
        'tiposComidaIds': _tiposComidaSeleccionados.toList(),
        'descripcion': _descripcionCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'correo': _correoCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'latitud': _selectedLocation?.latitude,
        'longitud': _selectedLocation?.longitude,
        'horarios': _horarios
            .map(
              (horario) => {
                'diaSemana': horario['diaSemana'],
                'horaInicio': horario['horaInicio'],
                'horaFin': horario['horaFin'],
              },
            )
            .toList(),
        'mesasTotal': mesasTotal,
        'capacidadTotal': capacidadTotal,
      };

      final patchResponse = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      if (patchResponse.statusCode != 200) {
        throw Exception(
          this._mensajeErrorApi(
            patchResponse.statusCode,
            patchResponse.bodyBytes,
          ),
        );
      }

      if (_selectedImageBytes != null) {
        final photoUrl = Uri.parse(
          '${ApiEndpoints.baseUrl}/api/v1/restaurante/${widget.restaurante.id}/portada',
        );
        final photoReq = http.MultipartRequest('POST', photoUrl);
        photoReq.headers['Authorization'] = 'Bearer $token';
        final ext = _selectedImage!.name.split('.').last.toLowerCase();
        final mimeType = ext == 'png'
            ? 'png'
            : (ext == 'webp' ? 'webp' : 'jpeg');
        photoReq.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _selectedImageBytes!,
            filename: _selectedImage!.name,
            contentType: MediaType('image', mimeType),
          ),
        );
        await this._verificarCarga(
          await photoReq.send(),
          'No se pudo guardar la portada',
        );
      }

      if (_selectedLogoBytes != null) {
        final logoUrl = Uri.parse(
          '${ApiEndpoints.baseUrl}/api/v1/restaurante/${widget.restaurante.id}/logo',
        );
        final logoReq = http.MultipartRequest('POST', logoUrl);
        logoReq.headers['Authorization'] = 'Bearer $token';
        final ext = _selectedLogo!.name.split('.').last.toLowerCase();
        final mimeType = ext == 'png'
            ? 'png'
            : (ext == 'webp' ? 'webp' : 'jpeg');
        logoReq.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _selectedLogoBytes!,
            filename: _selectedLogo!.name,
            contentType: MediaType('image', mimeType),
          ),
        );
        await this._verificarCarga(
          await logoReq.send(),
          'No se pudo guardar el logo',
        );
      }

      if (_selectedGalleryBytes.isNotEmpty) {
        final galeriaUrl = Uri.parse(
          '${ApiEndpoints.baseUrl}/api/v1/restaurante/${widget.restaurante.id}/galeria',
        );
        final galReq = http.MultipartRequest('POST', galeriaUrl);
        galReq.headers['Authorization'] = 'Bearer $token';
        for (int i = 0; i < _selectedGallery.length; i++) {
          final ext = _selectedGallery[i].name.split('.').last.toLowerCase();
          final mimeType = ext == 'png'
              ? 'png'
              : (ext == 'webp' ? 'webp' : 'jpeg');
          galReq.files.add(
            http.MultipartFile.fromBytes(
              'files',
              _selectedGalleryBytes[i],
              filename: _selectedGallery[i].name,
              contentType: MediaType('image', mimeType),
            ),
          );
        }
        await this._verificarCarga(
          await galReq.send(),
          'No se pudo guardar la galería',
        );
      }

      if (mounted) {
        AdminNotificationModal.success(
          context,
          '¡Perfil completado exitosamente!',
        );
        widget.onCompleted();
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        AdminNotificationModal.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
