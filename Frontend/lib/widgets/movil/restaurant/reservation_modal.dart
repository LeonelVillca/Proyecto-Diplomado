import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/models/movil/restaurant.dart';

/// Modal inferior interactivo para realizar una reserva.
/// Recopila fecha, hora, numero de personas y comentarios.
class ReservationModal extends StatefulWidget {
  const ReservationModal({super.key, required this.restaurant});
  final Restaurant restaurant;

  @override
  State<ReservationModal> createState() => _ReservationModalState();
}

class _ReservationModalState extends State<ReservationModal> {
  int _guests = 2;
  late DateTime _selectedDate;
  String? _selectedTime;
  final TextEditingController _commentCtrl = TextEditingController();

  final List<String> _timeSlots = [
    '12:00', '12:30', '13:00', '13:30', '14:00',
    '19:00', '19:30', '20:00', '20:30', '21:00', '21:30'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); // Hoy por defecto
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _submitReservation() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, selecciona una hora para la reserva', style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Aqui se enviarian los datos al backend (NestJS)
    final data = {
      'fecha': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
      'hora': _selectedTime,
      'numeroPersonas': _guests,
      'comentarios': _commentCtrl.text,
      // 'id_restaurante': widget.restaurant.id,
    };

    // Simulacion de carga
    Navigator.pop(context); // Cierra modal
    
    // Muestra confirmacion de exito
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF2E8B57).withAlpha(20), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E8B57), size: 48),
            ),
            const SizedBox(height: 12),
            Text('Reserva Confirmada', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 20)),
          ],
        ),
        content: Text(
          'Te esperamos en ${widget.restaurant.name} el ${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')} a las $_selectedTime para $_guests personas.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.secondaryText),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.wine,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Entendido', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculo de dias proximos
    final today = DateTime.now();
    final dates = List.generate(7, (i) => today.add(Duration(days: i)));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F6F2), // AppColors.background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header del modal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reservar Mesa', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.secondaryText),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Contenido scrolleable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Numero de personas
                  _Label('¿Cuántas personas?'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 8,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final number = i + 1;
                        final isSelected = number == _guests;
                        return GestureDetector(
                          onTap: () => setState(() => _guests = number),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.wine : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? AppColors.wine : Colors.black12),
                              boxShadow: isSelected ? AppShadows.cardSoft : [],
                            ),
                            child: Text(
                              number == 8 ? '8+' : '$number',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : AppColors.ink,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Fecha
                  _Label('Selecciona una fecha'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dates.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final date = dates[i];
                        final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
                        final isToday = i == 0;
                        
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedDate = date;
                            _selectedTime = null; // reset hora
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 65,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.wine : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? AppColors.wine : Colors.black12),
                              boxShadow: isSelected ? AppShadows.cardSoft : [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isToday ? 'Hoy' : _getWeekDay(date.weekday),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? Colors.white70 : AppColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.day}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Hora
                  _Label('Selecciona la hora'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _timeSlots.map((time) {
                      final isSelected = time == _selectedTime;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTime = time),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.gold : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? AppColors.gold : Colors.black12),
                            boxShadow: isSelected ? AppShadows.cardSoft : [],
                          ),
                          child: Text(
                            time,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 4. Comentarios (Opcional)
                  _Label('Peticiones especiales (Opcional)'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'Ej. Aniversario, alergias, mesa cerca de la ventana...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.secondaryText.withAlpha(150)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.wine, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Boton fijo inferior
          Container(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(color: Colors.white, boxShadow: AppShadows.sheet),
            child: SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _submitReservation,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.wine,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Confirmar Reserva',
                  style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
    );
  }
}

String _getWeekDay(int weekday) {
  switch (weekday) {
    case 1: return 'Lun';
    case 2: return 'Mar';
    case 3: return 'Mié';
    case 4: return 'Jue';
    case 5: return 'Vie';
    case 6: return 'Sáb';
    case 7: return 'Dom';
    default: return '';
  }
}

