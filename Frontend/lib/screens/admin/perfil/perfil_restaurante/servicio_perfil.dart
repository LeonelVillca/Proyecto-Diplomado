part of '../perfil_restaurante_screen.dart';

extension _ServicioPerfil on _PerfilRestauranteScreenState {
  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate() || _restaurante == null) {
      return;
    }

    if (_tiposComidaSeleccionados.isEmpty) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'Selecciona al menos un tipo de comida.',
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

    if ((_existingGallery.length + _selectedGallery.length) < 5) {
      if (mounted) {
        AdminNotificationModal.info(
          context,
          'Sube al menos 5 fotografías en la galería.',
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final token = AuthScope.of(context, listen: false).token;

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

      final exito = await _repository.actualizarPerfil(
        token: token!,
        restauranteId: _restaurante!.id,
        body: body,
        selectedImageBytes: _selectedImageBytes,
        selectedImage: _selectedImage,
        selectedLogoBytes: _selectedLogoBytes,
        selectedLogo: _selectedLogo,
        selectedGalleryBytes: _selectedGalleryBytes,
        selectedGallery: _selectedGallery,
        deletedImageIds: _deletedGalleryIds,
      );

      if (exito) {
        await this._cargarPerfil();
        _selectedImage = null;
        _selectedImageBytes = null;
        _selectedLogo = null;
        _selectedLogoBytes = null;
        _selectedGallery = [];
        _selectedGalleryBytes = [];
        _deletedGalleryIds.clear();
        if (mounted) {
          AdminNotificationModal.success(
            context,
            '¡Perfil actualizado con éxito!',
          );
        }
      } else if (mounted) {
        AdminNotificationModal.error(
          context,
          'No pudimos actualizar el perfil.',
        );
      }
    } catch (e) {
      debugPrint('Error guardando perfil: $e');
      if (mounted) {
        AdminNotificationModal.error(context, 'Ocurrió un error inesperado.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
