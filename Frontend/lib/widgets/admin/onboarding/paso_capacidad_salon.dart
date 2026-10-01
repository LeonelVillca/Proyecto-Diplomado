part of '../../../screens/admin/public/onboarding_restaurante_screen.dart';

class PasoCapacidadSalon extends StatelessWidget {
  const PasoCapacidadSalon({
    super.key,
    required this.pantalla,
    required this.mobile,
  });
  final _OnboardingRestauranteScreenState pantalla;
  final bool mobile;
  @override
  Widget build(BuildContext context) => pantalla._buildPaso3(mobile);
}

extension _Onboarding_paso_capacidad_salon
    on _OnboardingRestauranteScreenState {
  Widget _buildPaso3(bool mobile) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      this._stepHeading(
        2,
        'Salón y Galería',
        'Prepara tu ',
        'salón.',
        'Cuántos puedes atender por turno y las fotos que abren el apetito.',
      ),
      this._sectionCard(
        'Configuración de salón',
        'Lo usaremos para gestionar la ocupación de tus reservas.',
        LucideIcons.armchair,
        AdminTheme.primaryLight,
        AdminTheme.primaryColor,
        this._buildMesasBlock(mobile),
      ),
      this._sectionCard(
        'Galería de fotos',
        'Ambiente, platos fuertes y la entrada del local.',
        LucideIcons.images,
        AdminTheme.warningSoft,
        AdminTheme.gold,
        SelectorGaleria(pantalla: this),
      ),
    ],
  );

  Widget _buildMesasBlock(bool mobile) {
    final tables = this._salonCard(
      'TOTAL DE MESAS',
      LucideIcons.armchair,
      AdminTheme.primaryColor,
      AdminTheme.primaryLight,
      _mesasTotalCtrl,
      1,
    );
    final capacity = this._salonCard(
      'CAPACIDAD TOTAL',
      LucideIcons.users,
      AdminTheme.accentColor,
      AdminTheme.accentSoft,
      _capacidadTotalCtrl,
      int.tryParse(_mesasTotalCtrl.text) ?? 1,
    );
    return mobile
        ? Column(children: [tables, const SizedBox(height: 16), capacity])
        : Row(
            children: [
              Expanded(child: tables),
              const SizedBox(width: 16),
              Expanded(child: capacity),
            ],
          );
  }

  Widget _salonCard(
    String label,
    IconData icon,
    Color iconColor,
    Color iconBg,
    TextEditingController controller,
    int min,
  ) {
    final value = int.tryParse(controller.text) ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.background,
        border: Border.all(color: AdminTheme.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 23, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  style: AdminTheme.bodyStyle.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5,
                  ),
                ),
                SizedBox(
                  height: 43,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    style: AdminTheme.titleStyle.copyWith(fontSize: 30),
                    decoration: const InputDecoration(
                      filled: false,
                      isDense: true,
                      hintText: '0',
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              this._salonStepButton(
                LucideIcons.plus,
                () => setState(() => controller.text = '${value + 1}'),
              ),
              const SizedBox(height: 6),
              this._salonStepButton(
                LucideIcons.minus,
                value <= min
                    ? null
                    : () => setState(() => controller.text = '${value - 1}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _salonStepButton(IconData icon, VoidCallback? onPressed) => SizedBox(
    width: 34,
    height: 34,
    child: IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
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
