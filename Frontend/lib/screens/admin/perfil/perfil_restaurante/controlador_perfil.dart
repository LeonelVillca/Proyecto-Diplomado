part of '../perfil_restaurante_screen.dart';

extension _ControladorPerfil on _PerfilRestauranteScreenState {
  Future<void> _cargarPerfil() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _hydrating = true;

    try {
      final token = AuthScope.of(context, listen: false).token;
      final restaurante = await _repository.obtenerMiRestaurante(token!);
      _catalogoTiposComida = await _repository.obtenerTiposComida(token);

      if (restaurante != null) {
        _restaurante = restaurante;
        _nombreCtrl.text = _restaurante!.nombre;
        _tipoComidaCtrl.text = _restaurante!.tipoComida ?? '';
        _tiposComidaSeleccionados
          ..clear()
          ..addAll(
            _restaurante!.tiposComida
                .map((tipo) => int.tryParse(tipo['id']?.toString() ?? ''))
                .whereType<int>(),
          );
        _descripcionCtrl.text = _restaurante!.descripcion ?? '';
        _telefonoCtrl.text = _restaurante!.telefono ?? '';
        _correoCtrl.text = _restaurante!.correo ?? '';
        _direccionCtrl.text = _restaurante!.direccion ?? '';

        if (_restaurante!.mesas != null && _restaurante!.mesas!.isNotEmpty) {
          _mesasTotalCtrl.text = _restaurante!.mesas!.length.toString();
          final cap = _restaurante!.mesas!.first['capacidad'] ?? 0;
          _capacidadTotalCtrl.text = (cap * _restaurante!.mesas!.length)
              .toString();
        }
        if (_restaurante!.horarios != null) {
          _horarios = List<Map<String, dynamic>>.from(_restaurante!.horarios!);
        }
        if (_restaurante!.imagenes != null) {
          _existingGallery = _restaurante!.imagenes!
              .whereType<Map>()
              .map((i) => Map<String, dynamic>.from(i))
              .toList();
        }

        if (_restaurante!.latitud != null && _restaurante!.longitud != null) {
          _selectedLocation = LatLng(
            _restaurante!.latitud!,
            _restaurante!.longitud!,
          );
          this._actualizarMarcador(_selectedLocation!);
        } else {
          _selectedLocation = const LatLng(
            -21.5354,
            -64.7295,
          ); // Tarija por defecto
        }
      }
    } catch (e) {
      debugPrint('Error cargando perfil del restaurante: $e');
    } finally {
      _hydrating = false;
      _isDirty = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markDirty() {
    if (_hydrating || !mounted) return;
    setState(() => _isDirty = true);
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes != null) {
        setState(() {
          _selectedImage = file;
          _selectedImageBytes = bytes;
          _isDirty = true;
        });
      }
    }
  }

  Future<void> _pickLogo() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes != null) {
        setState(() {
          _selectedLogo = file;
          _selectedLogoBytes = bytes;
          _isDirty = true;
        });
      }
    }
  }

  Future<void> _pickGallery() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      for (var file in result.files) {
        final bytes = file.bytes;
        if (bytes != null) {
          setState(() {
            _selectedGallery.add(file);
            _selectedGalleryBytes.add(bytes);
            _isDirty = true;
          });
        }
      }
    }
  }

  void _onMapTapped(LatLng pos) async {
    setState(() {
      _selectedLocation = pos;
      _isDirty = true;
      _direccionCtrl.text = "Buscando dirección...";
      this._actualizarMarcador(pos);
    });

    try {
      final direccion = await _repository.obtenerDireccionGeocoding(
        pos.latitude,
        pos.longitude,
      );
      if (direccion != null && mounted) {
        setState(() {
          _direccionCtrl.text = direccion;
        });
      } else if (mounted) {
        setState(() {
          _direccionCtrl.text =
              "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
        });
      }
    } catch (e) {
      debugPrint('Error geocoding: $e');
      if (mounted) {
        setState(() {
          _direccionCtrl.text =
              "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
        });
      }
    }
  }

  void _actualizarMarcador(LatLng pos) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('restaurante_loc'),
        position: pos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      ),
    );
  }

  Future<void> _abrirMapaModal() async {
    LatLng tempLoc = _selectedLocation ?? const LatLng(-21.5354, -64.7295);
    final Set<Marker> tempMarkers = {
      if (_selectedLocation != null)
        Marker(
          markerId: const MarkerId('restaurante_loc_temp'),
          position: _selectedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        ),
    };

    final LatLng? result = await AdminModal.show<LatLng>(
      context: context,
      title: 'Seleccionar Ubicación',
      width: 800,
      confirmText: 'Confirmar Ubicación',
      onConfirm: () => Navigator.pop(context, tempLoc),
      content: StatefulBuilder(
        builder: (context, setModalState) {
          return SizedBox(
            height: 500,
            child: _mapsSupported
                ? GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: tempLoc,
                      zoom: 15,
                    ),
                    markers: tempMarkers,
                    onTap: (pos) {
                      setModalState(() {
                        tempLoc = pos;
                        tempMarkers.clear();
                        tempMarkers.add(
                          Marker(
                            markerId: const MarkerId('restaurante_loc_temp'),
                            position: pos,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRose,
                            ),
                          ),
                        );
                      });
                    },
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: true,
                    myLocationButtonEnabled: false,
                  )
                : const Center(child: Text('Mapas no soportados')),
          );
        },
      ),
    );

    if (result != null) {
      this._onMapTapped(result);
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(result, 15));
    }
  }
}
