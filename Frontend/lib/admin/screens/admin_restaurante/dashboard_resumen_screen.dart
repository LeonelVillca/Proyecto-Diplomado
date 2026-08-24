import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardResumenScreen extends StatelessWidget {
  const DashboardResumenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: _BannerCard()),
              SizedBox(width: 16),
              Expanded(flex: 1, child: _ChartCard()),
            ],
          ),
        ),
        SizedBox(height: 16),
        _TableCard(),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF2D0A14), Color(0xFF6E1E39)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: CustomPaint(
              size: const Size(180, 180),
              painter: _ThinRingsPainter(),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4DE28A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SINCRONIZACIÓN EN TIEMPO REAL',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 34,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  children: [
                    const TextSpan(text: 'Servicio de la '),
                    TextSpan(
                      text: 'Noche',
                      style: GoogleFonts.playfairDisplay(
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFC9974F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hay 24 comensales programados para las próximas 2 horas.',
                style: GoogleFonts.manrope(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Capacidad del Salón',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1B1A),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 0.75),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 9,
                    backgroundColor: const Color(0xFFEAEDF2),
                    color: const Color(0xFF6E1E39),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '75%',
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2D0A14),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Ocupado',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: const Color(0xFF6B635E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                color: const Color(0xFF6B635E),
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(
                  text: '8 de 12',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B1A),
                  ),
                ),
                const TextSpan(text: ' mesas en uso.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Próximas Llegadas',
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1B1A),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8A2547), Color(0xFF6E1E39)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: const [
                    BoxShadow(
                      color:      Color(0x336E1E39),
                      blurRadius: 16,
                      offset:     Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(50),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Reserva Manual',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 2, child: _HeaderTitle('CLIENTE')),
                Expanded(flex: 1, child: _HeaderTitle('LLEGADA')),
                Expanded(flex: 2, child: _HeaderTitle('ASIGNACIÓN')),
                Expanded(flex: 1, child: _HeaderTitle('ESTADO')),
                SizedBox(width: 40),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAEDF2)),
          const _ReservaRow(
            iniciales: 'CR',
            nombre: 'Carlos Rodríguez',
            telefono: '+591 71234567',
            hora: '20:30',
            mesa: 'Mesa 4 (Terraza)',
            comensales: '4 Comensales',
            estadoTexto: 'Confirmada',
            estadoColor: Color(0xFF1F8B4C),
            estadoBg: Color(0xFFE6F6EE),
          ),
          const _ReservaRow(
            iniciales: 'MV',
            nombre: 'Mariana Vargas',
            telefono: '+591 76543210',
            hora: '21:00',
            mesa: 'Mesa 8 (Interior)',
            comensales: '2 Comensales',
            estadoTexto: 'En Mesa',
            estadoColor: Color(0xFF1D72B8),
            estadoBg: Color(0xFFEAF3FC),
          ),
          const _ReservaRow(
            iniciales: 'JP',
            nombre: 'Jorge Paz',
            telefono: '+591 78901234',
            hora: '21:30',
            mesa: 'Mesa 2 (Jardín)',
            comensales: '6 Comensales',
            estadoTexto: 'Pendiente',
            estadoColor: Color(0xFFC9974F),
            estadoBg: Color(0xFFFDF3E7),
          ),
        ],
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  final String text;
  const _HeaderTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFA39C98),
        letterSpacing: 1.5,
      ),
    );
  }
}

class _ReservaRow extends StatefulWidget {
  final String iniciales, nombre, telefono, hora, mesa, comensales, estadoTexto;
  final Color estadoColor, estadoBg;

  const _ReservaRow({
    required this.iniciales,
    required this.nombre,
    required this.telefono,
    required this.hora,
    required this.mesa,
    required this.comensales,
    required this.estadoTexto,
    required this.estadoColor,
    required this.estadoBg,
  });

  @override
  State<_ReservaRow> createState() => _ReservaRowState();
}

class _ReservaRowState extends State<_ReservaRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _hover ? const Color(0xFFF8FAFC) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCF4F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        widget.iniciales,
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF6E1E39),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nombre,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E1B1A),
                        ),
                      ),
                      Text(
                        widget.telefono,
                        style: GoogleFonts.manrope(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B635E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.hora,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D0A14),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mesa,
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1B1A),
                    ),
                  ),
                  Text(
                    widget.comensales,
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B635E),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.estadoBg,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.estadoColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.estadoTexto,
                        style: GoogleFonts.manrope(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: widget.estadoColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: _hover
                  ? const Color(0xFF1E1B1A)
                  : const Color(0xFFA39C98),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC9974F).withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final center = Offset(size.width / 2, size.height / 2);
    for (final radius in [
      size.width * 0.25,
      size.width * 0.38,
      size.width * 0.50,
    ]) {
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}