import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:frontend/services/shared/secure_http.dart' as http;
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';

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
                      'SINCRONIZACIÃ“N EN TIEMPO REAL',
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
                  style: GoogleFonts.inter(
                    fontSize: 34,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  children: [
                    const TextSpan(text: 'Servicio de la '),
                    TextSpan(
                      text: 'Noche',
                      style: GoogleFonts.inter(
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
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
      ),
    );
  }
}

class _TableCard extends StatefulWidget {
  const _TableCard();

  @override
  State<_TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<_TableCard> {
  bool _isLoading = true;
  List<dynamic> _reservas = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarReservas();
    });
  }

  Future<void> _cargarReservas() async {
    try {
      final auth = AuthScope.of(context, listen: false);
      final token = auth.token;
      
      final resRestaurante = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/v1/restaurante/mis-restaurantes'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (resRestaurante.statusCode == 200) {
        final List<dynamic> restaurantes = jsonDecode(utf8.decode(resRestaurante.bodyBytes));
        if (restaurantes.isNotEmpty) {
          final idRestaurante = restaurantes.first['id'];
          final resReservas = await http.get(
            Uri.parse('${ApiEndpoints.baseUrl}/api/v1/reservas/restaurante/$idRestaurante'),
            headers: {'Authorization': 'Bearer $token'},
          );
          
          if (resReservas.statusCode == 200) {
             final List<dynamic> todasReservas = jsonDecode(utf8.decode(resReservas.bodyBytes));
             final proximas = todasReservas.where((r) => 
               r['estado'] == 'pendiente' || 
               r['estado'] == 'aprobada' || 
               r['estado'] == 'confirmada'
             ).toList();
             
             if (mounted) {
               setState(() {
                 _reservas = proximas.take(10).toList();
                 _isLoading = false;
               });
             }
             return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading reservas: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

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
                    onTap: () => _cargarReservas(),
                    borderRadius: BorderRadius.circular(50),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Actualizar',
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
                Expanded(flex: 2, child: _HeaderTitle('ASIGNACIÃ“N')),
                Expanded(flex: 1, child: _HeaderTitle('ESTADO')),
                SizedBox(width: 40),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAEDF2)),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6E1E39))),
            )
          else if (_reservas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No hay próximas llegadas programadas',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF6B635E),
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ..._reservas.map((r) {
              final usuario = r['usuario'] ?? {};
              final nombre = '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'.trim();
              final iniciales = nombre.isNotEmpty ? nombre.substring(0, 1).toUpperCase() : 'C';
              final telefono = r['comentarios']?.toString() ?? 'Sin comentarios';
              final hora = r['hora']?.toString().substring(0, 5) ?? '--:--';
              final mesa = r['mesa']?['numero_mesa'] != null ? 'Mesa ${r['mesa']['numero_mesa']}' : 'No asignada';
              final comensales = '${r['numeroPersonas'] ?? 1} Comensales';
              final estado = r['estado']?.toString() ?? '';
              
              String estadoTexto = 'Pendiente';
              Color estadoColor = const Color(0xFFC9974F);
              Color estadoBg = const Color(0xFFFDF3E7);
              
              if (estado == 'confirmada') {
                estadoTexto = 'Confirmada';
                estadoColor = const Color(0xFF1F8B4C);
                estadoBg = const Color(0xFFE6F6EE);
              } else if (estado == 'aprobada') {
                estadoTexto = 'Aprobada';
                estadoColor = const Color(0xFF1D72B8);
                estadoBg = const Color(0xFFEAF3FC);
              }
              
              return _ReservaRow(
                iniciales: iniciales,
                nombre: nombre.isEmpty ? 'Cliente Anónimo' : nombre,
                telefono: telefono,
                hora: hora,
                mesa: mesa,
                comensales: comensales,
                estadoTexto: estadoTexto,
                estadoColor: estadoColor,
                estadoBg: estadoBg,
              );
            }),
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


