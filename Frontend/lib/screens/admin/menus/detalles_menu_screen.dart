import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/models/admin/menu_admin_model.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'formulario_menu_screen.dart';

const Color kBurgundy900 = Color(0xFF42101F);
const Color kBurgundy700 = Color(0xFF6E1E39);
const Color kBurgundy600 = Color(0xFF872A4C);
const Color kBurgundy100 = Color(0xFFF6E9EE);
const Color kGoldDeep = Color(0xFFA5793A);
const Color kGoldSoft = Color(0xFFF3E6C9);
const Color kCream = Color(0xFFF7F2EA);
const Color kCard = Color(0xFFFFFFFF);
const Color kLine = Color(0xFFE9E0D1);
const Color kInk = Color(0xFF2A2320);
const Color kInkSoft = Color(0xFF8C8074);

final List<BoxShadow> kShadow = [
  BoxShadow(color: const Color(0xFF42101F).withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1)),
  BoxShadow(color: const Color(0xFF42101F).withValues(alpha: 0.07), blurRadius: 28, offset: const Offset(0, 10)),
];

class DetallesMenuScreen extends StatelessWidget {
  final MenuAdminModel menu;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const DetallesMenuScreen({super.key, required this.menu, required this.onBack, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 30, 40, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Volver
            InkWell(
              onTap: onBack,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 16, color: kBurgundy700),
                  const SizedBox(width: 6),
                  Text('Volver a Gestión de menús', style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.bold, color: kBurgundy700)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Header Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kLine),
                boxShadow: kShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(menu.nombre, style: GoogleFonts.instrumentSerif(fontSize: 28, color: kBurgundy900)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                        decoration: BoxDecoration(color: kBurgundy100, borderRadius: BorderRadius.circular(99)),
                        child: Text(menu.tipo, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: kBurgundy700)),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      decoration: BoxDecoration(
                        color: kCard,
                        border: Border.all(color: kBurgundy700, width: 1.5),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined, size: 16, color: kBurgundy700),
                          const SizedBox(width: 8),
                          Text('Modificar este menú', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: kBurgundy700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Platillos incluidos (${menu.platos.length})', style: GoogleFonts.instrumentSerif(fontSize: 19, color: kInk)),
            const SizedBox(height: 16),
            if (menu.platos.isEmpty)
              Text('Este menú no tiene platillos registrados.', style: GoogleFonts.manrope(color: kInkSoft))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 0.85,
                ),
                itemCount: menu.platos.length,
                itemBuilder: (ctx, i) {
                  final plato = menu.platos[i];
                  final hasImage = plato.fotoUrl != null && plato.fotoUrl!.isNotEmpty;
                  return Container(
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kLine),
                      boxShadow: kShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 140,
                          child: hasImage
                              ? Image.network(
                                  plato.fotoUrl!.startsWith('/') ? '${ApiEndpoints.baseUrl}${plato.fotoUrl}' : plato.fotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [kGoldSoft, Color(0xFFFBF6EA)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.restaurant, color: kGoldDeep, size: 40),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [kGoldSoft, Color(0xFFFBF6EA)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.restaurant, color: kGoldDeep, size: 40),
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(plato.nombre, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold, color: kInk), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('Bs ${plato.precio.toStringAsFixed(2)}', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: kBurgundy700)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: Text(
                                    plato.descripcion.isNotEmpty ? plato.descripcion : 'Sin descripción.',
                                    style: GoogleFonts.manrope(fontSize: 12.5, color: kInkSoft, height: 1.5),
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
