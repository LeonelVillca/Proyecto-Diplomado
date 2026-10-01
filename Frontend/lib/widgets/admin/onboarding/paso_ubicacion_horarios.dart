part of '../../../screens/admin/public/onboarding_restaurante_screen.dart';

class PasoUbicacionHorarios extends StatelessWidget {
  const PasoUbicacionHorarios({
    super.key,
    required this.pantalla,
    required this.mobile,
  });
  final _OnboardingRestauranteScreenState pantalla;
  final bool mobile;
  @override
  Widget build(BuildContext context) => pantalla._buildPaso2(mobile);
}

extension _Onboarding_paso_ubicacion_horarios
    on _OnboardingRestauranteScreenState {
  Widget _buildPaso2(bool mobile) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      this._stepHeading(
        1,
        'Ubicación y Horarios',
        'Que te encuentren ',
        'fácil.',
        'Tu punto exacto en el mapa y los horarios en los que esperas comensales.',
      ),
      this._sectionCard(
        'Ubicación',
        'Selecciona tu restaurante en el mapa y confirma la dirección.',
        LucideIcons.mapPin,
        const Color(0xFFE8E8F5),
        const Color(0xFF4B4B8F),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            this._mapPicker(),
            const SizedBox(height: 16),
            this._buildTextField(
              'Dirección extraída',
              _direccionCtrl,
              icon: LucideIcons.mapPin,
              hint: 'Aparece al seleccionar tu ubicación en el mapa',
            ),
          ],
        ),
      ),
      this._sectionCard(
        'Horarios de atención',
        'Agrega los bloques de días y horas en que atiendes.',
        LucideIcons.clock,
        AdminTheme.warningSoft,
        AdminTheme.gold,
        this._buildHorariosBlock(mobile),
      ),
    ],
  );

  Widget _mapPicker() => InkWell(
    onTap: this._abrirMapaModal,
    borderRadius: BorderRadius.circular(18),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 260,
        width: double.infinity,
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
                        'Mapas no soportados en esta plataforma',
                      ),
                    ),
            ),
            Positioned(
              top: 14,
              left: 12,
              right: 12,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedLocation == null
                        ? Colors.white.withValues(alpha: .94)
                        : AdminTheme.successSoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _selectedLocation == null
                          ? AdminTheme.border
                          : Colors.transparent,
                    ),
                    boxShadow: AdminTheme.shadowSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedLocation == null
                            ? LucideIcons.mapPin
                            : LucideIcons.check,
                        size: 15,
                        color: _selectedLocation == null
                            ? AdminTheme.primaryColor
                            : AdminTheme.success,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          _selectedLocation == null
                              ? 'Haz clic en el mapa donde está tu restaurante'
                              : 'Ubicación seleccionada',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AdminTheme.bodyStyle.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _selectedLocation == null
                                ? AdminTheme.textDark
                                : AdminTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildHorariosBlock(bool mobile) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return Column(
      children: [
        for (final horario in _horarios) ...[
          if (_horarios.indexOf(horario) > 0) const SizedBox(height: 10),
          mobile
              ? Column(
                  children: [
                    this._scheduleDay(horario, dias),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: this._scheduleTime(horario, 'horaInicio'),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('—'),
                        ),
                        Expanded(child: this._scheduleTime(horario, 'horaFin')),
                        const SizedBox(width: 7),
                        this._scheduleRemove(horario),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 3, child: this._scheduleDay(horario, dias)),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: this._scheduleTime(horario, 'horaInicio'),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 9),
                      child: Text('—'),
                    ),
                    Expanded(
                      flex: 2,
                      child: this._scheduleTime(horario, 'horaFin'),
                    ),
                    const SizedBox(width: 10),
                    this._scheduleRemove(horario),
                  ],
                ),
        ],
        if (_horarios.isNotEmpty) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(
              () => _horarios.add({
                'diaSemana': 0,
                'horaInicio': '08:00',
                'horaFin': '22:00',
              }),
            ),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Agregar horario'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminTheme.textMuted,
              side: const BorderSide(color: Color(0xFFD5C9B8), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scheduleDay(Map<String, dynamic> horario, List<String> dias) =>
      DropdownButtonFormField<int>(
        key: ValueKey((horario, 'day')),
        initialValue: horario['diaSemana'],
        isExpanded: true,
        style: AdminTheme.bodyStyle.copyWith(
          color: AdminTheme.textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: this
            ._inputDecoration(null)
            .copyWith(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 13,
              ),
            ),
        items: dias
            .asMap()
            .entries
            .map(
              (entry) =>
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            )
            .toList(),
        onChanged: (value) => setState(() => horario['diaSemana'] = value!),
      );

  Widget _scheduleTime(Map<String, dynamic> horario, String field) =>
      TextFormField(
        key: ValueKey((horario, field)),
        initialValue: horario[field]?.toString() ?? '',
        textAlign: TextAlign.center,
        style: AdminTheme.bodyStyle.copyWith(
          color: AdminTheme.textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        decoration: this
            ._inputDecoration(null)
            .copyWith(
              isDense: true,
              hintText: field == 'horaInicio' ? '00:00' : '23:59',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 13,
              ),
            ),
        onChanged: (value) => horario[field] = value,
      );

  Widget _scheduleRemove(Map<String, dynamic> horario) => SizedBox(
    width: 42,
    height: 42,
    child: IconButton(
      tooltip: 'Eliminar horario',
      onPressed: () => setState(() => _horarios.remove(horario)),
      icon: const Icon(LucideIcons.x, size: 16),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AdminTheme.textMuted,
        side: const BorderSide(color: AdminTheme.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
  );
}
