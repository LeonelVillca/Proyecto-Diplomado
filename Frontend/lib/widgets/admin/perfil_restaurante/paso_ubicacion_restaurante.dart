part of '../../../screens/admin/perfil/perfil_restaurante_screen.dart';

extension _PasoUbicacionRestaurante on _PerfilRestauranteScreenState {
  Widget _buildLocation() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: _abrirMapaModal,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 230,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _mapsSupported
                      ? IgnorePointer(
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target:
                                  _selectedLocation ??
                                  const LatLng(-21.5354, -64.7295),
                              zoom: 15,
                            ),
                            markers: _markers,
                            onMapCreated: (ctrl) => _mapCtrl = ctrl,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            compassEnabled: false,
                            myLocationButtonEnabled: false,
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF2ECDF),
                          alignment: Alignment.center,
                          child: const Text(
                            'Mapa no disponible en esta plataforma',
                          ),
                        ),
                ),
                Positioned(
                  left: 14,
                  bottom: 14,
                  right: 14,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      constraints: const BoxConstraints(maxWidth: 410),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: AdminTheme.shadowSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 16,
                            color: AdminTheme.primaryColor,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              _nombreCtrl.text.isEmpty
                                  ? 'Seleccionar ubicación'
                                  : _nombreCtrl.text,
                              overflow: TextOverflow.ellipsis,
                              style: AdminTheme.bodyStyle.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AdminTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  right: 13,
                  top: 13,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.open_in_full,
                      size: 16,
                      color: AdminTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      this._buildTextField(
        'Dirección',
        _direccionCtrl,
        icon: LucideIcons.mapPin,
      ),
    ],
  );
}

class PasoUbicacionRestaurante extends StatelessWidget {
  const PasoUbicacionRestaurante({super.key, required this.pantalla});
  final _PerfilRestauranteScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._buildLocation();
}
