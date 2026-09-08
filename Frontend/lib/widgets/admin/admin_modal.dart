import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminModal extends StatelessWidget {
  final String title;
  final Widget content;
  final String? cancelText;
  final String? confirmText;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final Color? confirmColor;
  final double width;

  final List<Widget>? actions;

  const AdminModal({
    super.key,
    required this.title,
    required this.content,
    this.cancelText = 'Cancelar',
    this.confirmText = 'Guardar',
    this.onCancel,
    this.onConfirm,
    this.confirmColor,
    this.width = 550,
    this.actions,
  });

  /// Método estático de conveniencia para mostrar el modal fácilmente
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    String? cancelText = 'Cancelar',
    String? confirmText = 'Guardar',
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
    Color? confirmColor,
    double width = 550,
    bool barrierDismissible = true,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AdminModal(
        title: title,
        content: content,
        cancelText: cancelText,
        confirmText: confirmText,
        onCancel: onCancel ?? () => Navigator.pop(ctx),
        onConfirm: onConfirm,
        confirmColor: confirmColor,
        width: width,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent, // Make transparent to use custom container decoration
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000), // 10% black
              blurRadius: 30,
              offset: Offset(0, 15),
            ),
          ],
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera del modal
            Container(
              padding: const EdgeInsets.only(left: 32, right: 24, top: 24, bottom: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF8F5), // Warm off-white header
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1B1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF6B635E), size: 20),
                      onPressed: onCancel ?? () => Navigator.pop(context),
                      splashRadius: 24,
                      tooltip: 'Cerrar',
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido dinámico
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: content,
              ),
            ),
            
            // Botones de acción
            Container(
              padding: const EdgeInsets.only(left: 32, right: 32, top: 16, bottom: 32),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions ?? [
                  if (cancelText != null)
                    TextButton(
                      onPressed: onCancel ?? () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        foregroundColor: const Color(0xFF6B635E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      child: Text(cancelText!),
                    ),
                  if (cancelText != null && confirmText != null)
                    const SizedBox(width: 12),
                  if (confirmText != null)
                    ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor ?? const Color(0xFF28C76F), // Verde pastel por defecto como en el ejemplo
                        foregroundColor: confirmColor == null ? const Color(0xFF0F5132) : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      child: Text(confirmText!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminInputDecoration {
  static InputDecoration get({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: const TextStyle(color: Color(0xFF6B635E), fontFamily: 'Karla', fontWeight: FontWeight.w600, fontSize: 14),
      alignLabelWithHint: true,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF6E1E39), size: 20) : null,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6E1E39), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC), // Slight slate gray for input backgrounds
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    );
  }
}
