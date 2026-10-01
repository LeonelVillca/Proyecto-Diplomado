part of '../../../screens/admin/public/onboarding_restaurante_screen.dart';

class IndicadorPasos extends StatelessWidget {
  const IndicadorPasos({
    super.key,
    required this.pantalla,
    required this.compacto,
  });
  final _OnboardingRestauranteScreenState pantalla;
  final bool compacto;
  @override
  Widget build(BuildContext context) =>
      pantalla._progressPanel(compact: compacto);
}

extension _Onboarding_indicador_pasos on _OnboardingRestauranteScreenState {
  Widget _progressPanel({required bool compact}) {
    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 17, 22, 18),
        decoration: const BoxDecoration(
          color: Color(0xFFF3ECDE),
          border: Border(bottom: BorderSide(color: AdminTheme.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                this._brandMark(),
                const SizedBox(width: 9),
                Text(
                  'Mesa Chapaca',
                  style: AdminTheme.titleStyle.copyWith(fontSize: 18),
                ),
                const Spacer(),
                Text(
                  'PASO ${_currentStep + 1} DE 3',
                  style: AdminTheme.bodyStyle.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AdminTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            this._horizontalSteps(),
          ],
        ),
      );
    }
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 30),
      decoration: const BoxDecoration(
        color: Color(0xFFF3ECDE),
        border: Border(right: BorderSide(color: AdminTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              this._brandMark(),
              const SizedBox(width: 10),
              Text(
                'Mesa Chapaca',
                style: AdminTheme.titleStyle.copyWith(fontSize: 19),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(color: AdminTheme.border, height: 1),
          const SizedBox(height: 26),
          Text(
            'CONFIGURACIÓN INICIAL',
            style: AdminTheme.bodyStyle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bienvenido a\nMesa Chapaca',
            style: AdminTheme.titleStyle.copyWith(fontSize: 23, height: 1.18),
          ),
          const SizedBox(height: 8),
          Text(
            'Completa el perfil de tu restaurante en 3 pasos y empieza a recibir reservas.',
            style: AdminTheme.bodyStyle.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 30),
          ...List.generate(3, this._verticalStep),
          const Spacer(),
          const Divider(color: AdminTheme.border, height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Progreso',
                style: AdminTheme.bodyStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$_currentStep de 3',
                style: AdminTheme.bodyStyle.copyWith(
                  fontSize: 13,
                  color: AdminTheme.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 7,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFE9E1D2)),
                  AnimatedFractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _currentStep / 3,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    child: Container(color: AdminTheme.primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandMark() => Container(
    width: 34,
    height: 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AdminTheme.primaryColor,
      borderRadius: BorderRadius.circular(11),
    ),
    child: const Icon(LucideIcons.utensils, size: 17, color: Colors.white),
  );

  static const _stepNames = [
    'Identidad',
    'Ubicación y Horarios',
    'Salón y Galería',
  ];
  static const _stepDetails = [
    'Portada, nombre, tipos de comida y contacto.',
    'Dónde encontrarte y cuándo atender.',
    'Mesas, capacidad y tus mejores fotos.',
  ];

  Widget _stepCircle(int index) {
    final done = index < _currentStep;
    final active = index == _currentStep;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done
            ? AdminTheme.successSoft
            : active
            ? AdminTheme.primaryLight
            : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: done
              ? Colors.transparent
              : active
              ? AdminTheme.primaryColor
              : const Color(0xFFD8CDBC),
          width: 1.5,
        ),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: Color(0x29BE4B24),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: done
          ? const Icon(LucideIcons.check, size: 18, color: AdminTheme.success)
          : Text(
              '${index + 1}',
              style: AdminTheme.bodyStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: active ? AdminTheme.primaryDark : AdminTheme.textMuted,
              ),
            ),
    );
  }

  Widget _verticalStep(int index) {
    final done = index < _currentStep;
    final active = index == _currentStep;
    return SizedBox(
      height: index == 2 ? 80 : 105,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              this._stepCircle(index),
              if (index < 2)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    color: done
                        ? const Color(0xFFBFE3CE)
                        : const Color(0xFFE3DACA),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Opacity(
              opacity: index > _currentStep ? .55 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    'PASO ${index + 1}',
                    style: AdminTheme.bodyStyle.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _stepNames[index],
                    style: AdminTheme.bodyStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? AdminTheme.primaryDark
                          : AdminTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stepDetails[index],
                    style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _horizontalSteps() => Row(
    children: [
      for (var index = 0; index < 3; index++)
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 0
                          ? Colors.transparent
                          : index <= _currentStep
                          ? const Color(0xFFBFE3CE)
                          : const Color(0xFFE3DACA),
                    ),
                  ),
                  this._stepCircle(index),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index == 2
                          ? Colors.transparent
                          : index < _currentStep
                          ? const Color(0xFFBFE3CE)
                          : const Color(0xFFE3DACA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                _stepNames[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AdminTheme.bodyStyle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: index == _currentStep
                      ? AdminTheme.primaryDark
                      : AdminTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
