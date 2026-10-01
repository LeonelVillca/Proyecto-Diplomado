part of '../../../screens/admin/auth/admin_login_screen.dart';

extension _SelectorEstadoLoginAdmin on _AdminLoginScreenState {
  Widget _buildCurrentState() {
    switch (_screenState) {
      case AuthScreenState.login:
        return FormularioAccesoAdmin(pantalla: this);
      case AuthScreenState.paso1Correo:
        return PasoCorreoRecuperacionAdmin(pantalla: this);
      case AuthScreenState.paso2Pin:
        return PasoVerificacionPinAdmin(pantalla: this);
      case AuthScreenState.paso3NuevaContrasena:
        return PasoNuevaContrasenaAdmin(pantalla: this);
      case AuthScreenState.exito:
        return ConfirmacionRecuperacionAdmin(pantalla: this);
    }
  }
}

class ContenidoEstadoLoginAdmin extends StatelessWidget {
  const ContenidoEstadoLoginAdmin({super.key, required this.pantalla});
  final _AdminLoginScreenState pantalla;
  @override
  Widget build(BuildContext context) => pantalla._buildCurrentState();
}
