part of '../onboarding_restaurante_screen.dart';

extension _Onboarding_controlador_onboarding
    on _OnboardingRestauranteScreenState {
  void _refreshDescription() {
    if (mounted) setState(() {});
  }

  Future<void> _cargarTiposComida() async {
    try {
      final token = AuthScope.of(context, listen: false).token;
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/tipos-comida'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 && mounted) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        setState(
          () => _catalogoTiposComida = data
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(),
        );
      }
    } catch (e) {
      debugPrint('Error cargando tipos de comida: $e');
    }
  }

  Widget _buildTiposComidaSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      this._fieldLabel(
        'Tipos de comida',
        suffix: '· elige todos los que apliquen',
      ),
      const SizedBox(height: 9),
      Wrap(
        spacing: 9,
        runSpacing: 9,
        children: _catalogoTiposComida.map((tipo) {
          final id = int.tryParse(tipo['id']?.toString() ?? '');
          if (id == null) return const SizedBox.shrink();
          final isSelected = _tiposComidaSeleccionados.contains(id);
          return FilterChip(
            label: Text(tipo['nombre']?.toString() ?? ''),
            selected: isSelected,
            showCheckmark: true,
            checkmarkColor: AdminTheme.primaryColor,
            selectedColor: AdminTheme.primaryLight,
            backgroundColor: Colors.white,
            labelStyle: AdminTheme.bodyStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AdminTheme.primaryDark : AdminTheme.textMuted,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected ? AdminTheme.primaryColor : AdminTheme.border,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            onSelected: (selected) => setState(() {
              if (selected) {
                if (tipo['slug'] != 'por-definir') {
                  _tiposComidaSeleccionados.removeWhere(
                    (selectedId) => _catalogoTiposComida.any(
                      (entry) =>
                          entry['id'] == selectedId &&
                          entry['slug'] == 'por-definir',
                    ),
                  );
                } else {
                  _tiposComidaSeleccionados.clear();
                }
                _tiposComidaSeleccionados.add(id);
              } else {
                _tiposComidaSeleccionados.remove(id);
              }
            }),
          );
        }).toList(),
      ),
    ],
  );

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
          });
        }
      }
    }
  }

  void _onMapTapped(LatLng pos) async {
    setState(() {
      _selectedLocation = pos;
      _direccionCtrl.text = "Buscando dirección...";
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('restaurante_loc'),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        ),
      );
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=18&addressdetails=1',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data['display_name'] != null) {
          final partes = data['display_name'].toString().split(',');
          final direccion = partes.take(2).join(',').trim();
          if (mounted) {
            setState(() {
              _direccionCtrl.text = direccion;
            });
          }
        } else {
          throw Exception('No results');
        }
      } else {
        throw Exception('HTTP Status ${res.statusCode}');
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

  void _continueStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep += 1);
      if (_contentScrollCtrl.hasClients) _contentScrollCtrl.jumpTo(0);
    } else {
      this._finalizar();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
      if (_contentScrollCtrl.hasClients) _contentScrollCtrl.jumpTo(0);
    }
  }
}
