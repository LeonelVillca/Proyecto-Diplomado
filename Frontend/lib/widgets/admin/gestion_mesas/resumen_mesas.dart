part of '../../../screens/admin/mesas/gestion_mesas_screen.dart';

extension _ResumenMesas on _GestionMesasScreenState {
  Widget _buildResumenCard(
    String titulo,
    String valor,
    IconData icon,
    Color color,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AdminTheme.surface,
        borderRadius: AdminTheme.mediumRadius,
        border: Border.all(color: AdminTheme.border),
        boxShadow: AdminTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: AdminTheme.titleStyle.copyWith(fontSize: 24),
                ),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.bodyStyle.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroPill(String label, String valor, int count) {
    final active = _filtroEstado == valor;
    return InkWell(
      onTap: () => setState(() => _filtroEstado = valor),
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AdminTheme.primaryColor : AdminTheme.surface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: active ? AdminTheme.primaryColor : AdminTheme.border,
          ),
          boxShadow: active ? AdminTheme.shadowSm : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              valor == 'todas'
                  ? Icons.table_restaurant_outlined
                  : this._getIconEstado(valor),
              size: 14,
              color: active ? Colors.white : AdminTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : AdminTheme.textMuted,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: active ? Colors.white24 : AdminTheme.background,
                borderRadius: AdminTheme.pillRadius,
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : AdminTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeyenda() => AdminSurface(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    radius: AdminTheme.mediumRadius,
    child: Wrap(
      spacing: 20,
      runSpacing: 10,
      children: [
        this._buildStatusLegend(
          AdminTheme.success,
          'Libre',
          'disponible para reservar',
        ),
        this._buildStatusLegend(
          AdminTheme.primaryColor,
          'Ocupada',
          'comensales en mesa',
        ),
        this._buildStatusLegend(
          AdminTheme.gold,
          'Reservada',
          'reserva o bloqueo manual',
        ),
        this._buildStatusLegend(
          AdminTheme.textMuted,
          'Inactiva',
          'fuera de servicio',
        ),
      ],
    ),
  );

  Widget _buildStatusLegend(Color color, String state, String detail) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 7),
      Text(
        '$state — $detail',
        style: AdminTheme.bodyStyle.copyWith(fontSize: 11),
      ),
    ],
  );
}

class TarjetaResumenMesas extends StatelessWidget {
  const TarjetaResumenMesas({
    super.key,
    required this.pantalla,
    required this.titulo,
    required this.valor,
    required this.icon,
    required this.color,
  });
  final _GestionMesasScreenState pantalla;
  final String titulo;
  final String valor;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) =>
      pantalla._buildResumenCard(titulo, valor, icon, color);
}

class FiltroEstadoMesas extends StatelessWidget {
  const FiltroEstadoMesas({
    super.key,
    required this.pantalla,
    required this.label,
    required this.valor,
    required this.count,
  });
  final _GestionMesasScreenState pantalla;
  final String label;
  final String valor;
  final int count;
  @override
  Widget build(BuildContext context) =>
      pantalla._buildFiltroPill(label, valor, count);
}

class LeyendaEstadosMesas extends StatelessWidget {
  const LeyendaEstadosMesas({super.key, required this.pantalla});
  final _GestionMesasScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._buildLeyenda();
}
