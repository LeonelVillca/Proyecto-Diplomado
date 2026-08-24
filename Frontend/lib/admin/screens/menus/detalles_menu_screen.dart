import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/menu_admin_model.dart';
import 'formulario_menu_screen.dart';

class DetallesMenuScreen extends StatelessWidget {
  final MenuAdminModel menu;

  const DetallesMenuScreen({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6E1E39)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Detalles del Menú', style: GoogleFonts.playfairDisplay(color: const Color(0xFF2D0A14), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(menu.nombre, style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF2D0A14))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF6E1E39).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(menu.tipo, style: GoogleFonts.manrope(color: const Color(0xFF6E1E39), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FormularioMenuScreen(idRestaurante: menu.idRestaurante, menuExistente: menu),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Modificar este Menú'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E1E39),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Platillos Incluidos (${menu.platos.length})', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (menu.platos.isEmpty)
              Text('Este menú no tiene platillos registrados.', style: GoogleFonts.manrope(color: const Color(0xFF6B635E)))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: menu.platos.length,
                itemBuilder: (ctx, i) {
                  final plato = menu.platos[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: plato.fotoUrl != null && plato.fotoUrl!.isNotEmpty
                              ? Image.network(plato.fotoUrl!, fit: BoxFit.cover)
                              : Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(Icons.restaurant, color: Color(0xFFA39C98), size: 48),
                                ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(plato.nombre, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E1B1A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Text('Bs ${plato.precio.toStringAsFixed(2)}', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF6E1E39))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Text(
                                    plato.descripcion.isNotEmpty ? plato.descripcion : 'Sin descripción.',
                                    style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF6B635E)),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
