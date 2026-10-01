part of '../../../screens/admin/perfil/perfil_restaurante_screen.dart';

extension _PasoHorariosRestaurante on _PerfilRestauranteScreenState {
  Widget _buildHorariosBlock() {
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
        for (var day = 0; day < 7; day++) ...[
          if (day > 0) const Divider(height: 22, color: AdminTheme.rowBorder),
          this._buildHorarioDia(day, dias[day]),
        ],
      ],
    );
  }

  Widget _buildHorarioDia(int day, String name) {
    final entries = _horarios.where((h) => h['diaSemana'] == day).toList();
    final active = entries.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 510;
        final timeControls = active
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: this._timeInput(entries[i], 'horaInicio'),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 7),
                          child: Text('—'),
                        ),
                        Flexible(child: this._timeInput(entries[i], 'horaFin')),
                        if (entries.length > 1)
                          IconButton(
                            tooltip: 'Quitar intervalo',
                            onPressed: () => setState(() {
                              _horarios.remove(entries[i]);
                              _isDirty = true;
                            }),
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: AdminTheme.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (entries.length > 1) const SizedBox(height: 2),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _horarios.add({
                        'diaSemana': day,
                        'horaInicio': '08:00',
                        'horaFin': '22:00',
                      });
                      _isDirty = true;
                    }),
                    icon: const Icon(LucideIcons.plus, size: 13),
                    label: const Text('Otro intervalo'),
                    style: TextButton.styleFrom(
                      foregroundColor: AdminTheme.primaryColor,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AdminTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.nightlight_round,
                      size: 13,
                      color: AdminTheme.textMuted,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Cerrado',
                      style: TextStyle(
                        fontSize: 12,
                        color: AdminTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: compact ? 86 : 120,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AdminTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: active
                            ? AdminTheme.textDark
                            : AdminTheme.textMuted,
                      ),
                    ),
                    if (active)
                      Text(
                        entries
                            .map((h) => '${h['horaInicio']}–${h['horaFin']}')
                            .join(', '),
                        style: AdminTheme.bodyStyle.copyWith(fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => setState(() {
                if (active) {
                  _horarios.removeWhere((h) => h['diaSemana'] == day);
                } else {
                  _horarios.add({
                    'diaSemana': day,
                    'horaInicio': '08:00',
                    'horaFin': '22:00',
                  });
                }
                _isDirty = true;
              }),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 28,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: active
                      ? AdminTheme.primaryColor
                      : const Color(0xFFE3DACA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  alignment: active
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x3026201A), blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(key: ValueKey(active), child: timeControls),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _timeInput(Map<String, dynamic> horario, String key) => SizedBox(
    width: 110,
    child: TextFormField(
      key: ValueKey((horario, key)),
      initialValue: horario[key]?.toString() ?? '',
      style: AdminTheme.bodyStyle.copyWith(
        color: AdminTheme.textDark,
        fontSize: 13,
      ),
      textAlign: TextAlign.center,
      decoration: this
          ._fieldDecoration(null)
          .copyWith(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 11,
            ),
          ),
      onChanged: (value) {
        horario[key] = value;
        this._markDirty();
      },
    ),
  );
}

class PasoHorariosRestaurante extends StatelessWidget {
  const PasoHorariosRestaurante({super.key, required this.pantalla});
  final _PerfilRestauranteScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._buildHorariosBlock();
}
