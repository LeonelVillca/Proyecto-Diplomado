part of '../../../screens/admin/auth/admin_login_screen.dart';

extension _PasoVerificacionPinAdmin on _AdminLoginScreenState {
  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        this._buildRecoveryHeader(
          2,
          onBack: () =>
              setState(() => _screenState = AuthScreenState.paso1Correo),
          title: 'Ingresa el codigo',
          subtitle:
              'Enviamos un codigo de 6 digitos a ${_recoveryCorreoCtrl.text}.',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 5 ? 10 : 0),
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace) {
                      if (_pinCtrls[index].text.isEmpty && index > 0) {
                        _pinFocusNodes[index - 1].requestFocus();
                      }
                    }
                  },
                  child: TextFormField(
                    controller: _pinCtrls[index],
                    focusNode: _pinFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: GoogleFonts.manrope(
                      color: authInk,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5DCD0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5DCD0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: authWine, width: 2),
                      ),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty && index < 5) {
                        _pinFocusNodes[index + 1].requestFocus();
                      } else if (val.isEmpty && index > 0) {
                        _pinFocusNodes[index - 1].requestFocus();
                      }
                      setState(() {});
                    },
                  ),
                ),
              ),
            );
          }),
        ),
        this._buildInlineMessage(),
        const SizedBox(height: 16),
        Text(
          'El codigo vence en 15:00 minutos',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: authInkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        AuthSubmitButton(
          label: 'Verificar codigo',
          loading: _isLoading,
          disabled: _pinCtrls.map((c) => c.text).join().length < 6,
          onPressed: _verificarPin,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No recibiste el codigo? ',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: authInkSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: _isLoading ? null : _solicitarRecuperacion,
              child: Text(
                'Reenviar',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: authWine,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PasoVerificacionPinAdmin extends StatelessWidget {
  const PasoVerificacionPinAdmin({super.key, required this.pantalla});
  final _AdminLoginScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._buildPaso2();
}
