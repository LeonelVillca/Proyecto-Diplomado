import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Paleta del sistema (compartida) ─────────────────────────────────────────
const Color authWine = Color(0xFF6B1233);
const Color authWineSoft = Color(0xFF8C3350);
const Color authWineDeep = Color(0xFF3A0A1B);
const Color authGold = Color(0xFFD4AF37);
const Color authGoldAccent = Color(0xFFB0832B);
const Color authPaper = Color(0xFFF5EEE0);
const Color authCard = Color(0xFFFFFCF6);
const Color authInk = Color(0xFF241512);
const Color authInkSoft = Color(0xFF7A6A5C);
const Color authInkFaint = Color(0xFF8C7A6B);
const Color authSage = Color(0xFF5C7A52);

// ─── Lado izquierdo: imagen + capa editorial ─────────────────────────────────
class AuthLeftVisual extends StatelessWidget {
  final Animation<double> fadeIn;
  final Animation<double> quoteFade;
  final Animation<Offset> quoteSlide;

  const AuthLeftVisual({
    super.key,
    required this.fadeIn,
    required this.quoteFade,
    required this.quoteSlide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: authWineDeep,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(authWine.withValues(alpha: 0.14), BlendMode.multiply),
            child: FadeTransition(
              opacity: fadeIn,
              child: Image.asset('assets/fondoTarija.jpg', fit: BoxFit.cover, alignment: Alignment.topCenter),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [const Color(0xD9241512), Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 40,
            child: FadeTransition(
              opacity: fadeIn,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/icon_app.png', 
                          height: 42, 
                          fit: BoxFit.contain
                          ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Mesa Chapaca',
                                style: GoogleFonts.piazzolla(
                                    fontSize: 19, color: Colors.white, fontWeight: FontWeight.w700, height: 1.05)),
                            const SizedBox(height: 3),
                            Text('Reservas en Tarija',
                                style: GoogleFonts.manrope(
                                    fontSize: 10.5,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 40,
            right: 40,
            bottom: 42,
            child: FadeTransition(
              opacity: quoteFade,
              child: SlideTransition(
                position: quoteSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 3,
                      decoration: BoxDecoration(
                        color: authGold,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Sabores que cuentan historias.',
                      style: GoogleFonts.piazzolla(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Haz que tu restaurante sea parte de la experiencia.',
                      style: GoogleFonts.manrope(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Campo de formulario con foco y hover ───────────────────────────────────
class AuthLoginField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;
  final int maxLines;

  const AuthLoginField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  State<AuthLoginField> createState() => _AuthLoginFieldState();
}

class _AuthLoginFieldState extends State<AuthLoginField> {
  late final FocusNode _focusNode = FocusNode();
  bool _hovered = false;

  bool get _active => _focusNode.hasFocus;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              widget.icon,
              size: 15,
              color: _active ? authGoldAccent : authInkFaint,
            ),
            const SizedBox(width: 7),
            Text(
              widget.label,
              style: GoogleFonts.manrope(
                color: _active ? authWine : authInkSoft,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        MouseRegion(
          cursor: SystemMouseCursors.text,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: authCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _active ? authGoldAccent : _hovered ? authWine.withValues(alpha: 0.35) : const Color(0xFFE9E0D1),
                width: _active ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: authWineDeep.withValues(alpha: _active ? 0.10 : 0.045),
                  blurRadius: _active ? 18 : 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              cursorColor: authWine,
              style: GoogleFonts.manrope(
                color: authInk,
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
                letterSpacing: 0.1,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: GoogleFonts.manrope(
                  color: const Color(0xFFAD9F94),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: (_active ? authGoldAccent : authWine).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      widget.icon,
                      color: _active ? authGoldAccent : authWine,
                      size: 17,
                    ),
                  ),
                ),
                suffixIcon: widget.suffixIcon,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                errorStyle: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
              validator: widget.validator,
              onFieldSubmitted: widget.onFieldSubmitted,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Botón principal con hover ───────────────────────────────────────────────
class AuthSubmitButton extends StatefulWidget {
  final String label;
  final bool loading;
  final bool disabled;
  final VoidCallback onPressed;

  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    this.disabled = false,
    required this.onPressed,
  });

  @override
  State<AuthSubmitButton> createState() => _AuthSubmitButtonState();
}

class _AuthSubmitButtonState extends State<AuthSubmitButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveDisabled = widget.disabled || widget.loading;
    return MouseRegion(
      cursor: effectiveDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: effectiveDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.disabled ? const Color(0xFFE5DCD0) : null,
            gradient: widget.disabled
                ? null
                : LinearGradient(
                    colors: _hovered && !widget.loading ? [authWineSoft, authWine] : [authWine, const Color(0xFF55102A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.disabled
                ? []
                : [
                    BoxShadow(
                      color: authWine.withValues(alpha: _hovered && !widget.loading ? 0.35 : 0.15),
                      blurRadius: _hovered && !widget.loading ? 20 : 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: widget.loading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: widget.disabled ? authInkFaint : Colors.white,
                      ),
                    ),
                    if (!widget.disabled) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                    ]
                  ],
                ),
        ),
      ),
    );
  }
}
