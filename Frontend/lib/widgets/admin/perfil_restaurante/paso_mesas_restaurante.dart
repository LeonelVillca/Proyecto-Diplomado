part of '../../../screens/admin/perfil/perfil_restaurante_screen.dart';

extension _PasoMesasRestaurante on _PerfilRestauranteScreenState {
  Widget _buildMesasBlock(bool narrow) {
    final tables = this._buildStepper(
      'TOTAL DE MESAS',
      LucideIcons.store,
      AdminTheme.primaryColor,
      AdminTheme.primaryLight,
      _mesasTotalCtrl,
      1,
    );
    final capacity = this._buildStepper(
      'CAPACIDAD TOTAL',
      LucideIcons.users,
      AdminTheme.accentColor,
      AdminTheme.accentSoft,
      _capacidadTotalCtrl,
      int.tryParse(_mesasTotalCtrl.text) ?? 1,
    );
    return narrow
        ? Column(children: [tables, const SizedBox(height: 12), capacity])
        : Row(
            children: [
              Expanded(child: tables),
              const SizedBox(width: 14),
              Expanded(child: capacity),
            ],
          );
  }

  Widget _buildStepper(
    String label,
    IconData icon,
    Color iconColor,
    Color iconBg,
    TextEditingController controller,
    int min,
  ) {
    final value = int.tryParse(controller.text) ?? min;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.background,
        border: Border.all(color: AdminTheme.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: AdminTheme.bodyStyle.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                    color: AdminTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: AdminTheme.titleStyle.copyWith(fontSize: 32),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Campo requerido' : null,
                ),
              ),
              Column(
                children: [
                  this._stepperButton(
                    LucideIcons.plus,
                    () => setState(() => controller.text = '${value + 1}'),
                  ),
                  const SizedBox(height: 6),
                  this._stepperButton(
                    LucideIcons.minus,
                    value <= min
                        ? null
                        : () =>
                              setState(() => controller.text = '${value - 1}'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback? onPressed) => SizedBox(
    width: 34,
    height: 34,
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AdminTheme.primaryColor,
        disabledForegroundColor: AdminTheme.textLight,
        side: const BorderSide(color: AdminTheme.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
  );
}

class PasoMesasRestaurante extends StatelessWidget {
  const PasoMesasRestaurante({
    super.key,
    required this.pantalla,
    required this.estrecho,
  });
  final _PerfilRestauranteScreenState pantalla;
  final bool estrecho;
  @override
  Widget build(BuildContext context) => pantalla._buildMesasBlock(estrecho);
}
