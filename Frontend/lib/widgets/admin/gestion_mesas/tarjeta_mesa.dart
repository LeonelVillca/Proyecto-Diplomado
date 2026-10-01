part of '../../../screens/admin/mesas/gestion_mesas_screen.dart';

extension _TarjetaMesa on _GestionMesasScreenState {
  Widget _buildMesaCard(Map<String, dynamic> datosMesa) {
    final idMesa = (datosMesa['idMesa'] as num).toInt();
    final mesa = _mesas.firstWhere((item) => item.id == idMesa);
    final estado = this._estadoEnConsulta(datosMesa);
    final reserva = datosMesa['reserva'] as Map<String, dynamic>?;
    final horaReserva = reserva?['hora']?.toString() ?? '';
    final color = this._getColorEstado(estado);
    final icon = this._getIconEstado(estado);

    final stateLabel = switch (estado) {
      'libre' => 'Libre',
      'ocupada' => 'Ocupada',
      'reservada' => 'Reservada',
      _ => 'Inactiva',
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: AdminTheme.mediumRadius,
        boxShadow: AdminTheme.shadowSm,
        border: Border.all(color: AdminTheme.border),
      ),
      child: ClipRRect(
        borderRadius: AdminTheme.mediumRadius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:
                reserva != null ||
                    estado == 'inactiva' ||
                    _mesasActualizando.contains(idMesa)
                ? null
                : () => this._cambiarEstadoMesa(datosMesa),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(height: 4, color: color),
                Expanded(
                  child: Opacity(
                    opacity: estado == 'inactiva' ? .55 : 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 9, 15, 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MESA',
                                      style: AdminTheme.bodyStyle.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      mesa.numeroMesa,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.fraunces(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w600,
                                        height: 1.1,
                                        color: AdminTheme.textDark,
                                        decoration: estado == 'inactiva'
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationThickness: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.chair_alt_rounded,
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 42,
                                  minHeight: 42,
                                ),
                                icon: const Icon(
                                  Icons.more_horiz_rounded,
                                  color: AdminTheme.textMuted,
                                  size: 20,
                                ),
                                onSelected: (val) {
                                  if (val == 'edit')
                                    this._abrirModalMesa(mesa: mesa);
                                  if (val == 'delete')
                                    this._eliminarMesa(mesa.id);
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 16),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: AdminTheme.error,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Eliminar',
                                          style: TextStyle(
                                            color: AdminTheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 11),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              this._buildSmallChip(
                                Icons.people_alt_outlined,
                                '${mesa.capacidad} personas',
                                AdminTheme.textMuted,
                                AdminTheme.background,
                              ),
                              this._buildSmallChip(
                                icon,
                                stateLabel,
                                color,
                                color.withValues(alpha: .11),
                              ),
                            ],
                          ),
                          if (datosMesa['bloqueoHora'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Bloqueo manual desde ${datosMesa['bloqueoHora']} · 1 hora',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AdminTheme.bodyStyle.copyWith(
                                fontSize: 11,
                                color: AdminTheme.textMuted,
                              ),
                            ),
                          ],
                          if (reserva != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  size: 15,
                                  color: AdminTheme.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    '${reserva['cliente']?.toString().isNotEmpty == true ? reserva['cliente'] : 'Cliente'} · ${horaReserva.length >= 5 ? horaReserva.substring(0, 5) : horaReserva}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AdminTheme.bodyStyle.copyWith(
                                      fontSize: 11,
                                      color: AdminTheme.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (estado != 'libre') ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  estado == 'inactiva'
                                      ? Icons.block_outlined
                                      : Icons.schedule_rounded,
                                  size: 14,
                                  color: AdminTheme.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    estado == 'inactiva'
                                        ? 'Fuera de servicio'
                                        : estado == 'ocupada'
                                        ? 'Comensales en mesa'
                                        : 'Horario reservado',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AdminTheme.bodyStyle.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallChip(
    IconData icon,
    String label,
    Color foreground,
    Color background,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: background,
      borderRadius: AdminTheme.pillRadius,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: foreground),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      ],
    ),
  );
}

class TarjetaMesaAdmin extends StatelessWidget {
  const TarjetaMesaAdmin({
    super.key,
    required this.pantalla,
    required this.datosMesa,
  });
  final _GestionMesasScreenState pantalla;
  final Map<String, dynamic> datosMesa;
  @override
  Widget build(BuildContext context) => pantalla._buildMesaCard(datosMesa);
}
