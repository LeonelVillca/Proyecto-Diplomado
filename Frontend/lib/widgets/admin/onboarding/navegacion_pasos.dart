part of '../../../screens/admin/public/onboarding_restaurante_screen.dart';

extension _Onboarding_navegacion_pasos on _OnboardingRestauranteScreenState {
  Widget _mainPane({required bool mobile, required bool tablet}) => Column(
    children: [
      Expanded(
        child: Scrollbar(
          controller: _contentScrollCtrl,
          child: SingleChildScrollView(
            controller: _contentScrollCtrl,
            padding: EdgeInsets.fromLTRB(
              tablet ? 22 : 56,
              tablet ? 30 : 44,
              tablet ? 22 : 56,
              30,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: tablet ? 796 : 728),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(.025, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: _currentStep == 0
                        ? PasoIdentidadRestaurante(
                            pantalla: this,
                            mobile: mobile,
                          )
                        : _currentStep == 1
                        ? PasoUbicacionHorarios(pantalla: this, mobile: mobile)
                        : PasoCapacidadSalon(pantalla: this, mobile: mobile),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      this._footer(mobile),
    ],
  );

  Widget _footer(bool mobile) {
    final stacked = mobile || MediaQuery.sizeOf(context).width < 780;
    final primary = FilledButton.icon(
      onPressed: _isLoading ? null : this._continueStep,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Icon(
              _currentStep == 2 ? LucideIcons.rocket : LucideIcons.arrowRight,
              size: 18,
            ),
      label: Text(
        _isLoading
            ? 'Activando...'
            : _currentStep == 2
            ? 'Guardar y Activar Restaurante'
            : 'Continuar',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AdminTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shadowColor: const Color(0x4DBE4B24),
        elevation: 5,
      ),
    );
    final back = TextButton.icon(
      onPressed: _currentStep == 0 || _isLoading ? null : this._previousStep,
      icon: const Icon(LucideIcons.arrowLeft, size: 17),
      label: const Text('Atrás'),
      style: TextButton.styleFrom(foregroundColor: AdminTheme.textDark),
    );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(mobile ? 22 : 56, 15, mobile ? 22 : 56, 17),
      decoration: const BoxDecoration(
        color: AdminTheme.background,
        border: Border(top: BorderSide(color: AdminTheme.border)),
      ),
      child: stacked
          ? Column(
              children: [
                SizedBox(width: double.infinity, child: primary),
                if (_currentStep > 0) back,
              ],
            )
          : Row(
              children: [
                if (_currentStep > 0) back else const SizedBox(width: 82),
                const Spacer(),
                const Icon(
                  LucideIcons.shieldCheck,
                  size: 16,
                  color: AdminTheme.gold,
                ),
                const SizedBox(width: 7),
                Text(
                  'Puedes editar todo esto después desde tu perfil',
                  style: AdminTheme.bodyStyle.copyWith(fontSize: 12),
                ),
                const Spacer(),
                primary,
              ],
            ),
    );
  }

  Widget _stepHeading(
    int index,
    String kicker,
    String before,
    String emphasis,
    String subtitle,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 9,
        children: [
          Container(width: 24, height: 2, color: AdminTheme.primaryColor),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AdminTheme.primaryLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'PASO ${index + 1} DE 3',
              style: AdminTheme.bodyStyle.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .8,
                color: AdminTheme.primaryDark,
              ),
            ),
          ),
          Text(
            kicker.toUpperCase(),
            style: AdminTheme.bodyStyle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AdminTheme.primaryColor,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      RichText(
        text: TextSpan(
          style: AdminTheme.titleStyle.copyWith(fontSize: 34),
          children: [
            TextSpan(text: before),
            TextSpan(
              text: emphasis,
              style: AdminTheme.titleStyle.copyWith(
                fontSize: 34,
                color: AdminTheme.primaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(subtitle, style: AdminTheme.bodyStyle.copyWith(fontSize: 15)),
      const SizedBox(height: 28),
    ],
  );
}
